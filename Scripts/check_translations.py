#!/usr/bin/env python3
# check_translations.py 1.0.0 -- vendored from primer-claude plugins/primer-core/skills/translate/check_translations.py. Do not edit here, update the source and re-vendor.
"""Check that every locale file of every translation catalog in a repo has the
English keys, non-empty, with the same placeholders as English.

Catalogs are found by layout, anywhere in the repo:
  iOS           <dir>/<lang>.lproj/<Table>.strings   English: en.lproj, else Base.lproj
  Android       <res>/values[-<locale>]/strings.xml  English: values/
  Web and RN    <dir>/<locale>.json next to en.json  English: en.json
Other Android qualifiers (values-night, values-v28, values-sw600dp) are not locales.

--exclude GLOB (repeatable) leaves out every file whose repo-relative path matches the
glob. Matching is fnmatch, so * and ** also match "/": "Debug App/**" is the whole folder.
A catalog whose English file or every locale file is excluded is listed as excluded and
never read.

Diff mode (the default) checks only the keys a change touches: keys that are new
in English, keys whose English value changed, and keys whose value changed in any
locale. A locale file that is new since --base is checked for every English key.
A locale file deleted since --base is a problem, unless its English file is deleted too.
Old gaps on keys nobody touched are ignored, so CI can run this on every merge
request. --all checks every key, for reporting.

Exit codes: 0 clean, 1 problems found, 2 usage or parse error.
"""

import argparse
import fnmatch
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter

SKIP_DIRS = {".git", "node_modules", "Pods", "Carthage", "DerivedData", ".build", "build", ".gradle"}

LPROJ_RE = re.compile(r"^(?P<dir>(?:.*/)?)(?P<lang>[^/]+)\.lproj/(?P<table>[^/]+\.strings)$")
ANDROID_RE = re.compile(r"^(?P<res>(?:.*/)?res)/values(?:-(?P<qual>[^/]+))?/strings\.xml$")
# xx, xxx, xx-rYY or b+...; car (UI mode) and hdr (color mode) are qualifiers, not languages.
ANDROID_LOCALE_RE = re.compile(r"^(?:(?!car$|hdr$)[a-z]{2,3}(?:-r(?:[A-Za-z]{2}|[0-9]{3}))?"
                               r"|b\+[A-Za-z0-9+]+)$")
JSON_RE = re.compile(r"^(?P<dir>(?:.*/)?)(?P<stem>[^/]+)\.json$")
JSON_LOCALE_RE = re.compile(r"^[a-z]{2,3}(?:[-_][A-Za-z0-9]{2,8})*$")

# %% first, so it is never read as a placeholder. {{name}} before {name}.
# No space flag: "10% off" must not read as a "% o" conversion.
TOKEN_RE = re.compile(
    r"%%"
    r"|\{\{\s*(?P<dname>[A-Za-z_][A-Za-z0-9_.]*)\s*\}\}"
    r"|\{(?P<sname>[A-Za-z_][A-Za-z0-9_.]*)\}"
    r"|%(?:(?P<pos>[1-9][0-9]*)\$)?[-+#0']*(?:[0-9]+|\*)?(?:\.(?:[0-9]+|\*))?"
    r"(?P<len>hh|h|ll|l|q|z|t|j|L)?(?P<conv>[@dDiuUxXoOfFeEgGcCsSpaA])"
)
CYRILLIC_RE = re.compile(u"[Ѐ-ӿ]")


class ParseError(Exception):
    pass


class UsageError(Exception):
    pass


class Catalog(object):
    def __init__(self, kind, label, english, locales):
        self.kind = kind          # "ios", "android" or "json"
        self.label = label        # display name, for example "Foo/<lang>.lproj/Bar.strings"
        self.english = english    # repo-relative path of the English file, or None
        self.locales = locales    # locale code -> repo-relative path
        self.excluded = False     # matched --exclude: listed, not checked


# ---------------------------------------------------------------- locale codes

def norm_locale(code):
    """One spelling per locale, so --skip-locale accepts zh-rHK, zh-HK or zh_HK."""
    c = code.lower().replace("_", "-")
    if c.startswith("b+"):
        c = c[2:].replace("+", "-")
    return re.sub(r"^([a-z]{2,3})-r([a-z]{2}|[0-9]{3})$", r"\1-\2", c)


def is_serbian_latin_locale(code):
    c = norm_locale(code)
    return (c == "sr" or c.startswith("sr-")) and "cyrl" not in c


# --------------------------------------------------------------------- parsing

def decode(data, path):
    if data.startswith(b"\xef\xbb\xbf"):
        return data[3:].decode("utf-8")
    if data.startswith(b"\xff\xfe") or data.startswith(b"\xfe\xff"):
        return data.decode("utf-16")
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        pass
    if len(data) > 1 and data[1:2] == b"\x00":
        return data.decode("utf-16-le")
    if data[:1] == b"\x00":
        return data.decode("utf-16-be")
    raise ParseError("%s: not UTF-8 or UTF-16" % path)


STRINGS_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", "0": "\0", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}
UNQUOTED_RE = re.compile(r"[A-Za-z0-9_$+/:.\-]+")
HEX4_RE = re.compile(r"[0-9a-fA-F]{4}")


def parse_strings(data, path):
    """Apple .strings (old-style plist dictionary): comments, escapes, multi-line values."""
    text = decode(data, path)
    n = len(text)
    out = {}

    def fail(msg, pos):
        raise ParseError("%s:%d: %s" % (path, text.count("\n", 0, pos) + 1, msg))

    def skip(i):
        while i < n:
            if text[i] in " \t\r\n﻿":
                i += 1
            elif text.startswith("/*", i):
                j = text.find("*/", i + 2)
                if j < 0:
                    fail("unterminated comment", i)
                i = j + 2
            elif text.startswith("//", i):
                j = text.find("\n", i)
                i = n if j < 0 else j + 1
            else:
                break
        return i

    def token(i):
        if text[i] != '"':
            m = UNQUOTED_RE.match(text, i)
            if not m:
                fail("unexpected character %r" % text[i], i)
            return m.group(0), m.end()
        j, buf = i + 1, []
        while True:
            if j >= n:
                fail("unterminated string", i)
            c = text[j]
            if c == '"':
                return "".join(buf), j + 1
            if c == "\\":
                j += 1
                if j >= n:
                    fail("unterminated string", i)
                e = text[j]
                if e in "uU" and HEX4_RE.match(text, j + 1):
                    buf.append(chr(int(text[j + 1:j + 5], 16)))
                    j += 5
                    continue
                buf.append(STRINGS_ESCAPES.get(e, e))
                j += 1
                continue
            buf.append(c)
            j += 1

    i = skip(0)
    while i < n:
        key, i = token(i)
        i = skip(i)
        if i < n and text[i] == ";":          # "key"; is shorthand for "key" = "key";
            out[key] = key
            i = skip(i + 1)
            continue
        if i >= n or text[i] != "=":
            fail("expected '=' after %r" % key, i)
        i = skip(i + 1)
        if i >= n:
            fail("expected a value for %r" % key, i)
        value, i = token(i)
        i = skip(i)
        if i >= n or text[i] != ";":
            fail("expected ';' after the value of %r" % key, i)
        out[key] = value
        i = skip(i + 1)
    return out, set()


ANDROID_NS = {
    b"xliff": b"urn:oasis:names:tc:xliff:document:1.2",
    b"tools": b"http://schemas.android.com/tools",
}


def android_text(raw):
    """Resolve Android escaping: \\' \\" \\n \\t \\uXXXX, "quoted" spans, whitespace collapse."""
    out, quoted, space, i, n = [], False, False, 0, len(raw)
    while i < n:
        c = raw[i]
        if c == "\\" and i + 1 < n:
            e = raw[i + 1]
            if e == "u" and HEX4_RE.match(raw, i + 2):
                out.append(chr(int(raw[i + 2:i + 6], 16)))
                i += 6
            else:
                out.append({"n": "\n", "t": "\t"}.get(e, e))
                i += 2
            space = False
            continue
        if c == '"':
            quoted = not quoted
            i += 1
            continue
        if not quoted and c in " \t\r\n":
            if out and not space:
                out.append(" ")
            space = True
            i += 1
            continue
        out.append(c)
        space = False
        i += 1
    if space and out and out[-1] == " ":      # trailing whitespace outside quotes
        out.pop()
    return "".join(out)


def parse_android(data, path):
    """Android strings.xml: <string>, <string-array>, <plurals>, CDATA, <xliff:g>."""
    # DTD entities can expand without limit. Dropping NULs catches UTF-16 files too.
    if re.search(b"<!(?:DOCTYPE|ENTITY)", data.replace(b"\0", b"")):
        raise ParseError("%s: <!DOCTYPE> and <!ENTITY> are not allowed" % path)
    # Some files use the xliff: or tools: prefix without declaring it; expat rejects that.
    for prefix, uri in ANDROID_NS.items():
        if prefix + b":" in data and b"xmlns:" + prefix not in data:
            data = re.sub(b"<resources\\b", b'<resources xmlns:' + prefix + b'="' + uri + b'"', data, count=1)
    try:
        root = ET.fromstring(data)
    except ET.ParseError as e:
        raise ParseError("%s: %s" % (path, e))
    if root.tag != "resources":
        raise ParseError("%s: root element is <%s>, expected <resources>" % (path, root.tag))
    out, fixed = {}, set()
    for el in root:
        name = el.get("name")
        if not name or not isinstance(el.tag, str):
            continue
        if el.tag == "string":
            entries = [(name, el)]
        elif el.tag == "string-array":
            entries = [("%s[%d]" % (name, i), item) for i, item in enumerate(el.findall("item"))]
        elif el.tag == "plurals":
            items = dict((item.get("quantity"), item) for item in el.findall("item"))
            # "other" exists in every language; the rest vary by plural rules.
            item = items.get("other") if "other" in items else (list(items.values()) or [None])[-1]
            entries = [(name, item)] if item is not None else []
        else:
            continue
        for key, node in entries:
            out[key] = android_text("".join(node.itertext()))
            if el.get("translatable") == "false":
                fixed.add(key)
    return out, fixed


def parse_json(data, path):
    try:
        obj = json.loads(decode(data, path))
    except ValueError as e:
        raise ParseError("%s: %s" % (path, e))
    if not isinstance(obj, dict):
        raise ParseError("%s: top level is not a JSON object" % path)
    out = {}

    def walk(o, prefix):
        if isinstance(o, dict):
            for k, v in o.items():
                walk(v, "%s.%s" % (prefix, k) if prefix else k)
        elif isinstance(o, list) and all(not isinstance(v, (dict, list)) for v in o):
            # A list of strings is one value (aliases), so a locale may give one string.
            out[prefix] = " | ".join("" if v is None else str(v) for v in o)
        elif isinstance(o, list):
            for i, v in enumerate(o):
                walk(v, "%s[%d]" % (prefix, i))
        elif isinstance(o, str):
            out[prefix] = o
        else:
            out[prefix] = "" if o is None else json.dumps(o)

    walk(obj, "")
    return out, set()


PARSERS = {"ios": parse_strings, "android": parse_android, "json": parse_json}


# ---------------------------------------------------------------- placeholders

def placeholders(value):
    named, printf = Counter(), []
    for m in TOKEN_RE.finditer(value):
        if m.group(0) == "%%":
            continue
        if m.group("dname"):
            named["{{%s}}" % m.group("dname")] += 1
        elif m.group("sname"):
            named["{%s}" % m.group("sname")] += 1
        else:
            conv = "d" if m.group("conv") == "i" else m.group("conv")
            pos = int(m.group("pos")) if m.group("pos") else None
            printf.append((pos, (m.group("len") or "") + conv))
    return named, printf


def unnumbered(printf):
    return all(p is None for p, _ in printf)


def printf_ok(en, tr):
    # Unnumbered arguments are read in order, so "%d hat %@" for "%@ has %d" reads the string as %d.
    if unnumbered(en) and unnumbered(tr):
        return en == tr
    # Same (position, kind) pairs: every argument used as often as in English, with its kind.
    if Counter(en) == Counter(tr):
        return True
    # English "%@ %d" may become "%2$d %1$@": number the English arguments, same rule.
    if unnumbered(en) and all(p is not None for p, _ in tr):
        return Counter(tr) == Counter((i, k) for i, (_, k) in enumerate(en, 1))
    return False


def describe(named, printf):
    toks = ["%%%d$%s" % (p, k) if p else "%" + k for p, k in printf] + list(named.elements())
    if not toks:
        return "none"
    return ", ".join("%s x%d" % (t, c) if c > 1 else t for t, c in sorted(Counter(toks).items()))


def problems_for(en_value, value, code):
    """(category, message) pairs for one key in one locale file."""
    if value is None:
        return [("missing", "missing")]
    if not value.strip():
        return [("empty", "empty")] if en_value.strip() else []
    found = []
    en_named, en_printf = placeholders(en_value)
    tr_named, tr_printf = placeholders(value)
    if en_named == tr_named and Counter(en_printf) == Counter(tr_printf) and not printf_ok(en_printf, tr_printf):
        found.append(("placeholders", "placeholders in a different order from English: English has %s, "
                      "this has %s; number them to reorder"
                      % tuple(" ".join("%" + k for _, k in t) for t in (en_printf, tr_printf))))
    elif en_named != tr_named or not printf_ok(en_printf, tr_printf):
        found.append(("placeholders", "placeholders differ from English: English has %s, this has %s"
                      % (describe(en_named, en_printf), describe(tr_named, tr_printf))))
    if is_serbian_latin_locale(code) and CYRILLIC_RE.search(value):
        found.append(("script", "Serbian must use Latin script, found Cyrillic"))
    return found


# ----------------------------------------------------------------------- git

def git(repo, *args):
    return subprocess.run(["git", "-C", repo] + list(args), stdout=subprocess.PIPE, stderr=subprocess.PIPE)


class BaseReader(object):
    """Reads files at the base ref through one `git cat-file --batch` process."""

    def __init__(self, repo, base):
        self.base = base
        self.prefix = git(repo, "rev-parse", "--show-prefix").stdout.decode().strip()
        self.proc = subprocess.Popen(["git", "-C", repo, "cat-file", "--batch"],
                                     stdin=subprocess.PIPE, stdout=subprocess.PIPE)

    def read(self, path):
        """The file's bytes at the base ref, or None when it does not exist there."""
        self.proc.stdin.write(("%s:%s%s\n" % (self.base, self.prefix, path)).encode("utf-8"))
        self.proc.stdin.flush()
        header = self.proc.stdout.readline().decode("utf-8", "replace").rstrip("\n").split(" ")
        if len(header) != 3 or not header[2].isdigit():
            return None                       # "<object> missing" or "ambiguous"
        body = self.proc.stdout.read(int(header[2]))
        self.proc.stdout.read(1)
        return body if header[1] == "blob" else None

    def close(self):
        self.proc.stdin.close()
        self.proc.wait()


# ------------------------------------------------------------------ discovery

def list_files(repo, in_git):
    if in_git:
        r = git(repo, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
        if r.returncode != 0:
            raise UsageError("git ls-files failed in %s: %s" % (repo, r.stderr.decode().strip()))
        paths = [p for p in r.stdout.decode("utf-8").split("\0") if p]
    else:
        paths = []
        for d, dirs, files in os.walk(repo):
            dirs[:] = [x for x in dirs if x not in SKIP_DIRS]
            rel = os.path.relpath(d, repo)
            paths += [f if rel == "." else "%s/%s" % (rel.replace(os.sep, "/"), f) for f in files]
    return sorted(p for p in paths
                  if not SKIP_DIRS.intersection(p.split("/")[:-1]) and os.path.isfile(os.path.join(repo, p)))


def read_file(repo, path):
    with open(os.path.join(repo, path), "rb") as f:
        return f.read()


def group(files):
    """Catalogs by path layout alone, so a JSON config file next to en.json still counts."""
    ios, android, json_dirs = {}, {}, {}
    for p in files:
        m = LPROJ_RE.match(p)
        if m:
            ios.setdefault((m.group("dir"), m.group("table")), {})[m.group("lang")] = p
            continue
        m = ANDROID_RE.match(p)
        if m:
            q = m.group("qual") or ""
            if not q or ANDROID_LOCALE_RE.match(q):
                android.setdefault(m.group("res"), {})[q] = p
            continue
        m = JSON_RE.match(p)
        if m and JSON_LOCALE_RE.match(m.group("stem")):
            json_dirs.setdefault(m.group("dir"), {})[m.group("stem")] = p

    catalogs = []
    for (d, table), langs in sorted(ios.items()):
        src = "en" if "en" in langs else ("Base" if "Base" in langs else None)
        catalogs.append(Catalog("ios", "%s<lang>.lproj/%s" % (d, table), langs.get(src),
                                dict((k, v) for k, v in langs.items() if k not in (src, "Base"))))

    for res, quals in sorted(android.items()):
        catalogs.append(Catalog("android", "%s/values-<locale>/strings.xml" % res, quals.get(""),
                                dict((q, p) for q, p in quals.items() if q)))

    for d, stems in sorted(json_dirs.items()):
        if "en" in stems and len(stems) > 1:
            catalogs.append(Catalog("json", "%s<locale>.json" % d, stems["en"],
                                    dict((s, p) for s, p in stems.items() if s != "en")))
    return catalogs


def discover(repo, files, excluded, warnings):
    catalogs = []
    for cat in group(files):
        if cat.kind == "json":
            todo = [s for s, p in cat.locales.items() if not excluded(p)]
            if todo and not excluded(cat.english):
                en_keys = set(parse_json(read_file(repo, cat.english), cat.english)[0])
                for stem in todo:
                    # A config file such as app.json can sit next to en.json; a locale file
                    # shares keys with English (or is still empty).
                    p = cat.locales[stem]
                    keys = set(parse_json(read_file(repo, p), p)[0])
                    if keys and not keys & en_keys:
                        warnings.append("ignored %s: no keys in common with %s" % (p, cat.english))
                        del cat.locales[stem]
            if not cat.locales:
                continue
        catalogs.append(cat)

    for cat in catalogs:
        kept = dict((c, p) for c, p in cat.locales.items() if not excluded(p))
        cat.excluded = bool(cat.english and excluded(cat.english) or cat.locales and not kept)
        cat.locales = kept
    return catalogs


# ------------------------------------------------------------------- checking

def check(repo, base, check_all, skip, excludes=()):
    if not os.path.isdir(repo):
        raise UsageError("--repo %s is not a directory" % repo)
    in_git = git(repo, "rev-parse", "--is-inside-work-tree").returncode == 0
    if not check_all:
        if not in_git:
            raise UsageError("%s is not a git repository; diff mode needs one (or pass --all)" % repo)
        if git(repo, "rev-parse", "--verify", "--quiet", base + "^{commit}").returncode != 0:
            raise UsageError("--base %s is not a commit in %s (fetch it first)" % (base, repo))

    def excluded(path):
        return any(fnmatch.fnmatchcase(path, g) for g in excludes)

    warnings, problems, summary = [], [], []
    files = list_files(repo, in_git)
    catalogs = discover(repo, files, excluded, warnings)
    reader = None if check_all else BaseReader(repo, base)
    try:
        if reader:
            problems += removed_locale_files(repo, reader, set(files), excluded, skip)
        for cat in catalogs:
            if cat.excluded:
                summary.append("  excluded %s" % cat.label)
                continue
            if not cat.english:
                summary.append("  skipped  %s: no English file" % cat.label)
                continue
            parse = PARSERS[cat.kind]
            en, fixed = parse(read_file(repo, cat.english), cat.english)
            en_keys = [k for k in en if k not in fixed]
            locales = dict((c, p) for c, p in cat.locales.items() if norm_locale(c) not in skip)
            heads = dict((c, parse(read_file(repo, p), p)[0]) for c, p in locales.items())

            if check_all:
                todo = dict((c, set(en_keys)) for c in heads)
            else:
                en_base = base_values(reader, parse, cat.english, warnings)
                if en_base is None:                      # the catalog is new
                    todo = dict((c, set(en_keys)) for c in heads)
                else:
                    touched = set(k for k in en_keys if en_base.get(k) != en[k])
                    new_locales = set()
                    for c, p in locales.items():
                        old = base_values(reader, parse, p, warnings)
                        if old is None:
                            new_locales.add(c)
                        else:
                            touched |= set(k for k in en_keys if heads[c].get(k) != old.get(k))
                    todo = dict((c, set(en_keys) if c in new_locales else touched) for c in heads)

            n_checked = len(set().union(*todo.values())) if todo else 0
            for c in sorted(heads):
                for k in sorted(todo[c]):
                    for category, message in problems_for(en[k], heads[c].get(k), c):
                        problems.append((locales[c], k, category, message))
            summary.append("  %-8s %s: %d locales, %d keys, %d checked"
                           % (cat.kind, cat.label, len(heads), len(en_keys), n_checked))
    finally:
        if reader:
            reader.close()
    return problems, summary, warnings


def removed_locale_files(repo, reader, head_files, excluded, skip):
    """Locale files deleted since the base ref; a catalog deleted with its English file is fine."""
    r = git(repo, "ls-tree", "-r", "-z", "--name-only", reader.base)
    if r.returncode != 0:
        raise UsageError("git ls-tree %s failed in %s: %s" % (reader.base, repo, r.stderr.decode().strip()))
    base_files = [p for p in r.stdout.decode("utf-8").split("\0")
                  if p and not SKIP_DIRS.intersection(p.split("/")[:-1])]
    found = []
    for cat in group(base_files):
        if cat.english not in head_files or excluded(cat.english):
            continue
        for code, p in cat.locales.items():
            if p in head_files or excluded(p) or norm_locale(code) in skip:
                continue
            if cat.kind == "json":
                keys, en_keys = base_json_keys(reader, p), base_json_keys(reader, cat.english)
                if keys and en_keys is not None and not keys & en_keys:
                    continue                  # a config file such as app.json
            found.append((p, "", "removed", "locale file removed"))
    return found


def base_json_keys(reader, path):
    data = reader.read(path)
    try:
        return None if data is None else set(parse_json(data, path)[0])
    except ParseError:
        return None


def base_values(reader, parse, path, warnings):
    data = reader.read(path)
    if data is None:
        return None
    try:
        return parse(data, path)[0]
    except ParseError as e:
        warnings.append("cannot parse %s at %s, treating it as new: %s" % (path, reader.base, e))
        return None


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Check translation catalogs (iOS .strings, Android strings.xml, Web and React "
                    "Native JSON) for missing keys, empty values and placeholder mismatches.")
    ap.add_argument("--repo", default=".", help="repository to check (default: current directory)")
    ap.add_argument("--base", help="git ref to diff against; in a merge request pass the merge base")
    ap.add_argument("--skip-locale", action="append", default=[], metavar="CODE",
                    help="locale code to skip, for example zf (repeatable)")
    ap.add_argument("--exclude", action="append", default=[], metavar="GLOB",
                    help="leave out files whose repo-relative path matches GLOB, for example "
                         "'Debug App/**' (fnmatch: * and ** also match /; repeatable)")
    ap.add_argument("--all", action="store_true", help="check every key, not only changed ones")
    args = ap.parse_args(argv)
    if not args.all and not args.base:
        ap.error("--base is required unless --all is given")

    try:
        problems, summary, warnings = check(os.path.abspath(args.repo), args.base, args.all,
                                            set(norm_locale(c) for c in args.skip_locale), args.exclude)
    except (ParseError, UsageError) as e:
        print("error: %s" % e, file=sys.stderr)
        return 2

    for w in warnings:
        print("warning: %s" % w, file=sys.stderr)
    for path, key, _, message in sorted(problems):
        print("%s: %s: %s" % (path, key, message) if key else "%s: %s" % (path, message))
    if problems:
        print("")
    mode = "all keys" if args.all else "keys changed since %s" % args.base
    print("Catalogs (%s):" % mode)
    print("\n".join(summary) if summary else "  none found")
    if problems:
        counts = Counter(category for _, _, category, _ in problems)
        files = len(set(p[0] for p in problems))
        print("%d problem(s) in %d file(s): %s"
              % (len(problems), files, ", ".join("%d %s" % (n, k) for k, n in sorted(counts.items()))))
        return 1
    print("OK: no problems found.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
