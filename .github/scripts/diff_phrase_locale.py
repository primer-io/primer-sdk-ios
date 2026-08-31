#!/usr/bin/env python3
"""Report how a locale's .strings file differs from what Phrase currently holds.

Used by Manual Translation Push to record the blast radius of an upload in the run log,
and runnable by hand before deciding to push:

    phrase locales download --id Polish --file_format strings --tags ios-sdk > current.strings
    python3 .github/scripts/diff_phrase_locale.py current.strings path/to/pl.lproj/Localizable.strings

Phrase serves .strings as UTF-16; the files in this repo are UTF-8, so both encodings are
tried on each side rather than assumed.
"""

import re
import sys

ENTRY = re.compile(r'^"((?:[^"\\]|\\.)*)" = "((?:[^"\\]|\\.)*)";', re.M)


def read(path):
    for encoding in ("utf-16", "utf-8-sig", "utf-8"):
        try:
            with open(path, encoding=encoding) as handle:
                text = handle.read()
        except (UnicodeDecodeError, UnicodeError):
            continue
        # A UTF-8 file decoded as UTF-16 yields mojibake rather than an error, so require
        # that the result actually parses as .strings entries.
        if ENTRY.search(text):
            return text
    sys.exit(f"error: could not parse {path} as a .strings file")


def entries(text):
    return {key: value for key, value in ENTRY.findall(text)}


def main():
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <phrase.strings> <repo.strings>")

    remote, local = entries(read(sys.argv[1])), entries(read(sys.argv[2]))

    changed = sorted(k for k in remote.keys() & local.keys() if remote[k] != local[k])
    added = sorted(local.keys() - remote.keys())
    missing = sorted(remote.keys() - local.keys())

    print(f"Phrase holds {len(remote)} keys, the repo file has {len(local)}.\n")

    if changed:
        print(f"{len(changed)} value(s) would be overwritten in Phrase:")
        for key in changed:
            print(f"  {key}")
            print(f"    phrase: {remote[key]}")
            print(f"    repo  : {local[key]}")
        print()

    if added:
        # update_translation_keys is pinned to false, so these are reported, not created.
        print(f"{len(added)} key(s) exist only in the repo and will NOT be created:")
        for key in added:
            print(f"  {key}")
        print()

    if missing:
        print(f"{len(missing)} key(s) exist only in Phrase and are left untouched:")
        for key in missing:
            print(f"  {key}")
        print()

    if not changed:
        print("No existing translation would change. The push would be a no-op.")


if __name__ == "__main__":
    main()
