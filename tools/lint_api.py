#!/usr/bin/env python3
"""Roblox API name checks for Luau files (heuristic, no type inference beyond locals).

    python3 tools/lint_api.py FILE...

Checks:
  * Instance.new("X") — X must be creatable;
  * Enum.A.B — enum and item must exist;
  * :GetService("X") — X must be a service;
  * a local bound to Instance.new("X") / GetService("X") / a typed constructor call:
    every `name.Member` and `name:Method(` must exist on X (until the local is rebound);
  * table literals passed as `make("X", {...})` / `new("X", {...})` / `inst("X", {...})`:
    keys must be properties of X.
Unknown members are reported; review them (children accessed by dot are reported too).
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import rbx_api  # noqa: E402

API = rbx_api.RbxApi.load(rbx_api.default_package_dir())

STR = r"""["']([A-Za-z0-9_]+)["']"""
NEW_RE = re.compile(r"Instance\.new\(\s*" + STR)
ENUM_RE = re.compile(r"\bEnum\.([A-Za-z0-9_]+)\.([A-Za-z0-9_]+)")
SERVICE_RE = re.compile(r":GetService\(\s*" + STR)
LOCAL_RE = re.compile(r"\blocal\s+([A-Za-z_]\w*)\s*=\s*(?:Instance\.new\(\s*" + STR + r"|game:GetService\(\s*" + STR + r")")
ASSIGN_RE = re.compile(r"(?<![\w.:])([A-Za-z_]\w*)\s*=(?!=)")
USE_RE = re.compile(r"(?<![\w.:])([A-Za-z_]\w*)([.:])([A-Za-z_]\w*)")
HELPER_RE = re.compile(r"\b(?:make|new|inst|create|Make|New)\(\s*" + STR + r"\s*,\s*\{")
# Members that exist on every Instance through the engine but some declarations omit
ALWAYS = {"Name", "Parent", "ClassName", "Destroy", "Clone", "GetChildren", "GetDescendants", "FindFirstChild",
          "WaitForChild", "IsA", "SetAttribute", "GetAttribute", "GetAttributes", "IsDescendantOf",
          "FindFirstChildOfClass", "FindFirstChildWhichIsA", "FindFirstAncestor", "FindFirstAncestorOfClass",
          "FindFirstAncestorWhichIsA", "GetPropertyChangedSignal", "GetAttributeChangedSignal", "AddTag",
          "RemoveTag", "HasTag", "GetTags", "ChildAdded", "ChildRemoved", "DescendantAdded", "DescendantRemoving",
          "Destroying", "AncestryChanged", "Changed", "AttributeChanged", "ClearAllChildren", "GetFullName",
          "IsAncestorOf", "GetActor", "GetStyled", "QueryDescendants"}


CONTAINER = {c: True for c in ("ReplicatedStorage", "ServerStorage", "ServerScriptService", "Workspace", "Folder",
                                "Model", "StarterGui", "StarterPlayer", "StarterPlayerScripts", "Lighting", "SoundService",
                                "ScreenGui", "Frame", "Players", "ReplicatedFirst", "Terrain", "TextChatService")}


def strip_comments_and_strings(src):
    """Blank out comments and string contents (keeps line structure), so regexes see code only.
    String delimiters are kept so STR patterns on the original line still work separately."""
    out = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if src.startswith("--[[", i) or src.startswith("--[=[", i):
            close = "]]" if src.startswith("--[[", i) else "]=]"
            j = src.find(close, i)
            j = n if j < 0 else j + len(close)
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
        elif src.startswith("--", i):
            j = src.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i))
            i = j
        elif c in "\"'`":
            j = i + 1
            while j < n and src[j] != c:
                if src[j] == "\\":
                    j += 1
                if src[j] == "\n" and c != "`":
                    break
                j += 1
            out.append(c + re.sub(r"[^\n]", " ", src[i + 1:j]) + (c if j < n else ""))
            i = j + 1
        elif src.startswith("[[", i) or src.startswith("[=[", i):
            close = "]]" if src.startswith("[[", i) else "]=]"
            j = src.find(close, i)
            j = n if j < 0 else j + len(close)
            out.append(re.sub(r"[^\n]", " ", src[i:j]))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def table_keys(code, start):
    """Top-level `Key=` names of the table literal starting at code[start] == '{'."""
    depth, i, keys = 0, start, []
    token_start = start + 1
    while i < len(code):
        c = code[i]
        if c in "{([":
            depth += 1
        elif c in "})]":
            depth -= 1
            if depth == 0:
                break
        elif depth == 1 and c in ",;":
            token_start = i + 1
        elif depth == 1 and c == "=" and code[i + 1:i + 2] != "=" and code[i - 1:i] not in "=~<>":
            m = re.match(r"\s*([A-Za-z_]\w*)\s*$", code[token_start:i])
            if m:
                keys.append((m.group(1), code.count("\n", 0, token_start) + 1))
        i += 1
    return keys


def lint(path):
    src = open(path, encoding="utf-8").read()
    code = strip_comments_and_strings(src)
    problems = []

    def line_of(pos):
        return src.count("\n", 0, pos) + 1
    for m in NEW_RE.finditer(src):
        if m.group(1) not in API.creatable:
            problems.append((line_of(m.start()), "Instance.new: %s is not creatable" % m.group(1)))
    for m in ENUM_RE.finditer(code):
        enum, item = m.group(1), m.group(2)
        if enum not in API.enums:
            problems.append((line_of(m.start()), "unknown enum Enum.%s" % enum))
        elif item not in API.enums[enum] and item not in ("GetEnumItems", "FromName", "FromValue"):
            problems.append((line_of(m.start()), "unknown enum item Enum.%s.%s" % (enum, item)))
    for m in SERVICE_RE.finditer(src):
        if m.group(1) not in API.services:
            problems.append((line_of(m.start()), "GetService: %s is not a service" % m.group(1)))
    # typed locals
    bindings = []  # (pos, name, class)
    for m in LOCAL_RE.finditer(src):
        cls = m.group(2) or m.group(3)
        bindings.append((m.start(), m.group(1), cls))
    for m in re.finditer(r"\blocal\s+([A-Za-z_]\w*)\s*=", code):
        if not any(b[0] == m.start() for b in bindings):
            bindings.append((m.start(), m.group(1), None))
    for m in ASSIGN_RE.finditer(code):
        if not code[max(0, m.start() - 6):m.start()].strip().endswith("local"):
            bindings.append((m.start(), m.group(1), None))
    # loop variables and function parameters rebind names too
    for m in re.finditer(r"\bfor\s+([\w\s,]+?)\s+(?:in|=)", code):
        for n in re.findall(r"[A-Za-z_]\w*", m.group(1)):
            bindings.append((m.start(), n, None))
    for m in re.finditer(r"\bfunction\s*[\w.:]*\s*\(([^)]*)\)", code):
        for n in re.findall(r"[A-Za-z_]\w*", m.group(1)):
            bindings.append((m.start(), n, None))
    for m in re.finditer(r"\blocal\s+([A-Za-z_][\w\s,]*?)\s*=", code):
        names = re.findall(r"[A-Za-z_]\w*", m.group(1))
        if len(names) > 1:
            for n in names:
                bindings.append((m.start(), n, None))
    bindings.sort()

    def class_at(name, pos):
        cls = None
        for p, n, c in bindings:
            if p > pos:
                break
            if n == name:
                cls = c
        return cls
    for m in USE_RE.finditer(code):
        name, sep, member = m.group(1), m.group(2), m.group(3)
        cls = class_at(name, m.start())
        if not cls or member in ALWAYS:
            continue
        kind = API.member(cls, member)
        if kind is None and sep == "." and CONTAINER.get(cls, False):
            if not re.match(r"\s*=(?!=)", code[m.end():m.end() + 4]):
                continue  # a child looked up by name (assignments must still be properties)
        if kind is None:
            problems.append((line_of(m.start()), "%s (%s) has no member %s" % (name, cls, member)))
        elif sep == ":" and kind != "method":
            problems.append((line_of(m.start()), "%s:%s — %s is a %s of %s" % (name, member, member, kind, cls)))
    for m in HELPER_RE.finditer(src):
        cls = m.group(1)
        if cls not in API.classes:
            problems.append((line_of(m.start()), "helper: unknown class %s" % cls))
            continue
        brace = m.end() - 1
        for key, _ in table_keys(code, brace):
            if API.member(cls, key) is None and key != "Parent":
                problems.append((line_of(brace) + 0, "helper %s: no property %s" % (cls, key)))
    return sorted(set(problems))


def main():
    total = 0
    for path in sys.argv[1:]:
        for line, msg in lint(path):
            print("%s:%d: %s" % (path, line, msg))
            total += 1
    print("lint_api: %d findings in %d files" % (total, len(sys.argv) - 1))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
