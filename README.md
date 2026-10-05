# DOGROTS — source workspace

- `place/DOGROTS_V13_RELEASE.rbxl` — original place file (V13 release).
- `src/` — every script from the place (except the generated `ReplicatedStorage/DogAnimationClips`), one file per
  instance. `*.server.luau` = Script, `*.client.luau` = LocalScript, `*.luau` = ModuleScript.
  `~N` in a name means the N-th sibling with the same name. `src/MANIFEST.tsv` lists every file.
- `tools/` — [Lune](https://github.com/lune-org/lune) scripts that extract scripts from a place and build a new place.
