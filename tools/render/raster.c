/* Tiny deferred software rasterizer for map previews.
   Input (little-endian):
     header: int W, H; float cam[12] (pos xyz, rot row-major 3x3); float fovY_deg;
             float sun[3] (direction TO the sun); float sunColor[3]; float ambSky[3]; float ambGround[3];
             float fogColor[3]; float fogStart, fogEnd; float skyTop[3]; float skyHorizon[3];
             int shadowRes; int nTris; int nLights
     tris:  nTris * { float v[9]; float rgb[3]; float emissive; float alpha; float spec }
     lights: nLights * { float pos[3]; float rgb[3]; float range; float brightness }
   Output: raw float RGB (W*H*3) then float emissive mask (W*H) */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { float v[9]; float rgb[3]; float emissive, alpha, spec; } Tri;
typedef struct { float p[3]; float c[3]; float range, bright; } Light;

static int W, H, SR, NT, NL;
static float cam[12], fovY, sun[3], sunC[3], ambS[3], ambG[3], fogC[3], fogS, fogE, skyT[3], skyH[3];
static Tri *tris; static Light *lights;
static float *zbuf; static int *idbuf; static float *smap; static float sminx, sminy, smaxx, smaxy, smz0;
static float L[9]; /* light basis rows: right, up, forward (into scene) */

static void cross(const float *a, const float *b, float *o) { o[0]=a[1]*b[2]-a[2]*b[1]; o[1]=a[2]*b[0]-a[0]*b[2]; o[2]=a[0]*b[1]-a[1]*b[0]; }
static void norm(float *a) { float n = sqrtf(a[0]*a[0]+a[1]*a[1]+a[2]*a[2]); if (n > 0) { a[0]/=n; a[1]/=n; a[2]/=n; } }
static float dot(const float *a, const float *b) { return a[0]*b[0]+a[1]*b[1]+a[2]*b[2]; }

/* camera space: x right, y up, z = distance along look (positive in front) */
static void to_cam(const float *w, float *c) {
  float d[3] = { w[0]-cam[0], w[1]-cam[1], w[2]-cam[2] };
  /* rot row-major: columns are right, up, back */
  const float *r = cam + 3;
  c[0] = r[0]*d[0] + r[3]*d[1] + r[6]*d[2];
  c[1] = r[1]*d[0] + r[4]*d[1] + r[7]*d[2];
  c[2] = -(r[2]*d[0] + r[5]*d[1] + r[8]*d[2]);
}

static float F; /* focal in pixels */
#define NEAR 0.3f

typedef void (*PixFn)(int x, int y, float z, int id);

static void raster_tri(float *p0, float *p1, float *p2, int id, PixFn fn, int w, int h) {
  /* p: screen x, y, z(depth for test) */
  float minx = fminf(p0[0], fminf(p1[0], p2[0])), maxx = fmaxf(p0[0], fmaxf(p1[0], p2[0]));
  float miny = fminf(p0[1], fminf(p1[1], p2[1])), maxy = fmaxf(p0[1], fmaxf(p1[1], p2[1]));
  int x0 = (int)floorf(minx), x1 = (int)ceilf(maxx), y0 = (int)floorf(miny), y1 = (int)ceilf(maxy);
  if (x0 < 0) x0 = 0; if (y0 < 0) y0 = 0; if (x1 > w - 1) x1 = w - 1; if (y1 > h - 1) y1 = h - 1;
  float area = (p1[0]-p0[0])*(p2[1]-p0[1]) - (p1[1]-p0[1])*(p2[0]-p0[0]);
  if (fabsf(area) < 1e-12f) return;
  for (int y = y0; y <= y1; y++) {
    float py = y + 0.5f;
    for (int x = x0; x <= x1; x++) {
      float px = x + 0.5f;
      float w0 = (p1[0]-px)*(p2[1]-py) - (p1[1]-py)*(p2[0]-px);
      float w1 = (p2[0]-px)*(p0[1]-py) - (p2[1]-py)*(p0[0]-px);
      float w2 = (p0[0]-px)*(p1[1]-py) - (p0[1]-py)*(p1[0]-px);
      if (area < 0) { w0 = -w0; w1 = -w1; w2 = -w2; }
      if (w0 < 0 || w1 < 0 || w2 < 0) continue;
      float s = w0 + w1 + w2;
      float z = (w0*p0[2] + w1*p1[2] + w2*p2[2]) / s;
      fn(x, y, z, id);
    }
  }
}

/* ---- main camera pass: depth = 1/z interpolated (perspective-correct depth ordering) */
static int pass_alpha = 0;
static float *col, *emis;
static void pix_main(int x, int y, float invz, int id) {
  int i = y * W + x;
  if (invz > zbuf[i]) { zbuf[i] = invz; idbuf[i] = id; }
}

static void emit_cam_tri(int id, PixFn fn) {
  Tri *t = &tris[id];
  float c[3][3];
  for (int k = 0; k < 3; k++) to_cam(t->v + 3*k, c[k]);
  /* clip against near plane */
  float poly[4][3]; int n = 0;
  for (int k = 0; k < 3; k++) {
    float *a = c[k], *b = c[(k+1)%3];
    int ain = a[2] >= NEAR, bin = b[2] >= NEAR;
    if (ain) { memcpy(poly[n++], a, 12); }
    if (ain != bin) {
      float tt = (NEAR - a[2]) / (b[2] - a[2]);
      poly[n][0] = a[0] + (b[0]-a[0])*tt; poly[n][1] = a[1] + (b[1]-a[1])*tt; poly[n][2] = NEAR; n++;
    }
  }
  if (n < 3) return;
  float s[4][3];
  for (int k = 0; k < n; k++) {
    s[k][0] = W*0.5f + poly[k][0] / poly[k][2] * F;
    s[k][1] = H*0.5f - poly[k][1] / poly[k][2] * F;
    s[k][2] = 1.0f / poly[k][2];
  }
  raster_tri(s[0], s[1], s[2], id, fn, W, H);
  if (n == 4) raster_tri(s[0], s[2], s[3], id, fn, W, H);
}

/* ---- shadow pass: orthographic along -sun */
static void to_light(const float *w, float *o) {
  o[0] = dot(L, w); o[1] = dot(L+3, w); o[2] = dot(L+6, w);
}
static void pix_shadow(int x, int y, float z, int id) {
  int i = y * SR + x;
  if (z < smap[i]) smap[i] = z;
}
static float shadow_at(const float *w, const float *n) {
  float p[3] = { w[0] + n[0]*0.35f, w[1] + n[1]*0.35f, w[2] + n[2]*0.35f };
  float o[3]; to_light(p, o);
  float fx = (o[0]-sminx)/(smaxx-sminx)*SR, fy = (o[1]-sminy)/(smaxy-sminy)*SR;
  int x = (int)fx, y = (int)fy;
  if (x < 0 || y < 0 || x >= SR || y >= SR) return 1.0f;
  float lit = 0; int cnt = 0;
  for (int dy = -1; dy <= 1; dy++) for (int dx = -1; dx <= 1; dx++) {
    int xx = x+dx, yy = y+dy; if (xx < 0 || yy < 0 || xx >= SR || yy >= SR) continue;
    cnt++; if (o[2] <= smap[yy*SR+xx] + 0.25f) lit += 1;
  }
  return cnt ? lit / cnt : 1.0f;
}

static void tri_normal(Tri *t, float *nrm) {
  float a[3] = { t->v[3]-t->v[0], t->v[4]-t->v[1], t->v[5]-t->v[2] };
  float b[3] = { t->v[6]-t->v[0], t->v[7]-t->v[1], t->v[8]-t->v[2] };
  cross(a, b, nrm); norm(nrm);
}

static void world_of_pixel(int x, int y, float invz, float *w) {
  float z = 1.0f / invz;
  float cx = (x + 0.5f - W*0.5f) / F * z, cy = -(y + 0.5f - H*0.5f) / F * z;
  const float *r = cam + 3;
  /* world = pos + right*cx + up*cy + look*z, look = -back */
  for (int k = 0; k < 3; k++) w[k] = cam[k] + r[k*3+0]*cx + r[k*3+1]*cy - r[k*3+2]*z;
}

static void shade(Tri *t, const float *w, float *out, float *em) {
  float nrm[3]; tri_normal(t, nrm);
  float view[3] = { cam[0]-w[0], cam[1]-w[1], cam[2]-w[2] }; float dist = sqrtf(dot(view, view)); norm(view);
  if (dot(nrm, view) < 0) { nrm[0] = -nrm[0]; nrm[1] = -nrm[1]; nrm[2] = -nrm[2]; }
  float ndl = dot(nrm, sun); float sh = ndl > 0 ? shadow_at(w, nrm) : 0;
  float hemi = 0.5f + 0.5f * nrm[1];
  float c[3];
  for (int k = 0; k < 3; k++) {
    float amb = ambS[k]*hemi + ambG[k]*(1-hemi);
    float diff = sunC[k] * (ndl > 0 ? ndl : 0) * sh;
    c[k] = t->rgb[k] * (amb + diff);
  }
  /* specular sun glint */
  if (t->spec > 0 && ndl > 0) {
    float hv[3] = { sun[0]+view[0], sun[1]+view[1], sun[2]+view[2] }; norm(hv);
    float s = powf(fmaxf(0, dot(nrm, hv)), 60) * t->spec * sh;
    for (int k = 0; k < 3; k++) c[k] += sunC[k] * s;
  }
  /* point lights */
  for (int i = 0; i < NL; i++) {
    Light *l = &lights[i];
    float d[3] = { l->p[0]-w[0], l->p[1]-w[1], l->p[2]-w[2] };
    float dd = sqrtf(dot(d, d));
    if (dd > l->range) continue;
    float att = 1 - dd / l->range; att *= att;
    float nd = dd > 0.01f ? dot(nrm, d) / dd : 1; if (nd < 0) nd = 0;
    nd = 0.25f + 0.75f * nd;
    for (int k = 0; k < 3; k++) c[k] += t->rgb[k] * l->c[k] * l->bright * att * nd * 0.9f;
  }
  float e = t->emissive;
  for (int k = 0; k < 3; k++) c[k] = c[k] * (1 - e) + t->rgb[k] * e * 1.25f;
  float f = (dist - fogS) / (fogE - fogS); if (f < 0) f = 0; if (f > 1) f = 1;
  f = f * f * (3 - 2 * f);
  for (int k = 0; k < 3; k++) out[k] = c[k] * (1 - f) + fogC[k] * f;
  *em = e * (1 - f);
}

int main(int argc, char **argv) {
  FILE *fi = fopen(argv[1], "rb"); FILE *fo = fopen(argv[2], "wb");
  if (!fi || !fo) return 1;
  fread(&W, 4, 1, fi); fread(&H, 4, 1, fi); fread(cam, 4, 12, fi); fread(&fovY, 4, 1, fi);
  fread(sun, 4, 3, fi); fread(sunC, 4, 3, fi); fread(ambS, 4, 3, fi); fread(ambG, 4, 3, fi);
  fread(fogC, 4, 3, fi); fread(&fogS, 4, 1, fi); fread(&fogE, 4, 1, fi); fread(skyT, 4, 3, fi); fread(skyH, 4, 3, fi);
  fread(&SR, 4, 1, fi); fread(&NT, 4, 1, fi); fread(&NL, 4, 1, fi);
  tris = malloc(sizeof(Tri) * (size_t)NT); fread(tris, sizeof(Tri), NT, fi);
  lights = malloc(sizeof(Light) * (size_t)(NL ? NL : 1)); if (NL) fread(lights, sizeof(Light), NL, fi);
  fclose(fi);
  norm(sun);
  F = (H * 0.5f) / tanf(fovY * 0.5f * 3.14159265f / 180.0f);

  /* shadow basis */
  float fwd[3] = { -sun[0], -sun[1], -sun[2] }, up0[3] = { 0, 1, 0 }, rt[3], up[3];
  if (fabsf(fwd[1]) > 0.99f) { up0[0] = 1; up0[1] = 0; }
  cross(fwd, up0, rt); norm(rt); cross(rt, fwd, up); norm(up);
  memcpy(L, rt, 12); memcpy(L+3, up, 12); memcpy(L+6, fwd, 12);
  sminx = sminy = 1e30f; smaxx = smaxy = -1e30f;
  for (int i = 0; i < NT; i++) for (int k = 0; k < 3; k++) {
    float o[3]; to_light(tris[i].v + 3*k, o);
    /* limit shadow map to area near camera for resolution */
    float d0 = tris[i].v[3*k]-cam[0], d2 = tris[i].v[3*k+2]-cam[2];
    if (d0*d0 + d2*d2 > 900.0f*900.0f) continue;
    if (o[0] < sminx) sminx = o[0]; if (o[0] > smaxx) smaxx = o[0];
    if (o[1] < sminy) sminy = o[1]; if (o[1] > smaxy) smaxy = o[1];
  }
  smap = malloc(sizeof(float) * (size_t)SR * SR);
  for (size_t i = 0; i < (size_t)SR * SR; i++) smap[i] = 1e30f;
  for (int i = 0; i < NT; i++) {
    if (tris[i].alpha < 0.5f || tris[i].emissive > 0.5f) continue;
    float s[3][3];
    for (int k = 0; k < 3; k++) {
      float o[3]; to_light(tris[i].v + 3*k, o);
      s[k][0] = (o[0]-sminx)/(smaxx-sminx)*SR; s[k][1] = (o[1]-sminy)/(smaxy-sminy)*SR; s[k][2] = o[2];
    }
    raster_tri(s[0], s[1], s[2], i, pix_shadow, SR, SR);
  }

  zbuf = malloc(sizeof(float) * (size_t)W * H); idbuf = malloc(sizeof(int) * (size_t)W * H);
  col = malloc(sizeof(float) * 3 * (size_t)W * H); emis = calloc((size_t)W * H, sizeof(float));
  for (int i = 0; i < W * H; i++) { zbuf[i] = 0; idbuf[i] = -1; }
  for (int i = 0; i < NT; i++) if (tris[i].alpha >= 0.999f) emit_cam_tri(i, pix_main);
  /* sky + shade opaque */
  for (int y = 0; y < H; y++) for (int x = 0; x < W; x++) {
    int i = y * W + x; float *o = col + 3*i;
    if (idbuf[i] < 0) {
      /* sky gradient by view elevation */
      float d[3]; float cx = (x + 0.5f - W*0.5f) / F, cy = -(y + 0.5f - H*0.5f) / F;
      const float *r = cam + 3;
      for (int k = 0; k < 3; k++) d[k] = r[k*3+0]*cx + r[k*3+1]*cy - r[k*3+2];
      norm(d);
      float el = d[1]; float tt = el < 0 ? 0 : powf(el, 0.6f);
      for (int k = 0; k < 3; k++) o[k] = skyH[k] * (1 - tt) + skyT[k] * tt;
      float sd = dot(d, sun); if (sd > 0.9995f) { for (int k = 0; k < 3; k++) o[k] = 1.0f; emis[i] = 1; }
      else if (sd > 0.97f) { float g = (sd - 0.97f) / 0.03f; for (int k = 0; k < 3; k++) o[k] += sunC[k] * g * g * 0.35f; }
      continue;
    }
    float w[3]; world_of_pixel(x, y, zbuf[i], w);
    shade(&tris[idbuf[i]], w, o, &emis[i]);
  }
  /* transparent pass: per pixel blend, sorted back-to-front by centroid distance */
  int na = 0; for (int i = 0; i < NT; i++) if (tris[i].alpha < 0.999f && tris[i].alpha > 0.01f) na++;
  if (na) {
    int *ids = malloc(sizeof(int) * na); float *keys = malloc(sizeof(float) * na); na = 0;
    for (int i = 0; i < NT; i++) if (tris[i].alpha < 0.999f && tris[i].alpha > 0.01f) {
      float c[3] = { (tris[i].v[0]+tris[i].v[3]+tris[i].v[6])/3 - cam[0], (tris[i].v[1]+tris[i].v[4]+tris[i].v[7])/3 - cam[1], (tris[i].v[2]+tris[i].v[5]+tris[i].v[8])/3 - cam[2] };
      ids[na] = i; keys[na] = dot(c, c); na++;
    }
    /* simple sort (shell sort) descending */
    for (int gap = na/2; gap > 0; gap /= 2) for (int i = gap; i < na; i++) {
      float k = keys[i]; int v = ids[i]; int j = i;
      while (j >= gap && keys[j-gap] < k) { keys[j] = keys[j-gap]; ids[j] = ids[j-gap]; j -= gap; }
      keys[j] = k; ids[j] = v;
    }
    float *tz = malloc(sizeof(float) * (size_t)W * H); int *tid = malloc(sizeof(int) * (size_t)W * H);
    for (int a = 0; a < na; a++) {
      int id = ids[a];
      /* rasterize into temp buffers of this triangle only: use main z for occlusion */
      Tri *t = &tris[id];
      float c[3][3];
      for (int k = 0; k < 3; k++) to_cam(t->v + 3*k, c[k]);
      if (c[0][2] < NEAR || c[1][2] < NEAR || c[2][2] < NEAR) continue;
      float s[3][3];
      for (int k = 0; k < 3; k++) { s[k][0] = W*0.5f + c[k][0]/c[k][2]*F; s[k][1] = H*0.5f - c[k][1]/c[k][2]*F; s[k][2] = 1.0f/c[k][2]; }
      float minx = fminf(s[0][0], fminf(s[1][0], s[2][0])), maxx = fmaxf(s[0][0], fmaxf(s[1][0], s[2][0]));
      float miny = fminf(s[0][1], fminf(s[1][1], s[2][1])), maxy = fmaxf(s[0][1], fmaxf(s[1][1], s[2][1]));
      int x0 = (int)floorf(minx), x1 = (int)ceilf(maxx), y0 = (int)floorf(miny), y1 = (int)ceilf(maxy);
      if (x0 < 0) x0 = 0; if (y0 < 0) y0 = 0; if (x1 > W-1) x1 = W-1; if (y1 > H-1) y1 = H-1;
      float area = (s[1][0]-s[0][0])*(s[2][1]-s[0][1]) - (s[1][1]-s[0][1])*(s[2][0]-s[0][0]);
      if (fabsf(area) < 1e-12f) continue;
      for (int y = y0; y <= y1; y++) for (int x = x0; x <= x1; x++) {
        float px = x + 0.5f, py = y + 0.5f;
        float w0 = (s[1][0]-px)*(s[2][1]-py) - (s[1][1]-py)*(s[2][0]-px);
        float w1 = (s[2][0]-px)*(s[0][1]-py) - (s[2][1]-py)*(s[0][0]-px);
        float w2 = (s[0][0]-px)*(s[1][1]-py) - (s[0][1]-py)*(s[1][0]-px);
        if (area < 0) { w0 = -w0; w1 = -w1; w2 = -w2; }
        if (w0 < 0 || w1 < 0 || w2 < 0) continue;
        float sum = w0 + w1 + w2; float iz = (w0*s[0][2] + w1*s[1][2] + w2*s[2][2]) / sum;
        int i = y * W + x;
        if (iz <= zbuf[i]) continue;
        float wp[3]; world_of_pixel(x, y, iz, wp);
        float o[3], e; shade(t, wp, o, &e);
        float al = t->alpha;
        for (int k = 0; k < 3; k++) col[3*i+k] = col[3*i+k] * (1 - al) + o[k] * al;
        emis[i] = emis[i] * (1 - al) + e * al;
      }
    }
    free(tz); free(tid);
  }
  fwrite(col, sizeof(float), 3 * (size_t)W * H, fo);
  fwrite(emis, sizeof(float), (size_t)W * H, fo);
  fclose(fo);
  return 0;
}
