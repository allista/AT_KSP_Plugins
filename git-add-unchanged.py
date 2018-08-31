import re
import sys

from git import Repo

diff_re = re.compile(r'[+-]\s*(?P<change>.*)')

IGNORE_LINES = [
    re.compile(r'// MVID: (\w+-?)+'),
    re.compile(r'// Assembly location: .*'),
    re.compile(r'// Assembly location: .*'),
    re.compile(r'switch \(-?\d+\)')
]

if __name__ == '__main__':
    repo = Repo()
    if repo.bare:
        print('No repo here.')
        sys.exit(1)
    for change in repo.index.diff(None, create_patch=True):
        changed = False
        for line in change.diff.decode().splitlines():
            match = diff_re.match(line)
            if match:
                line_diff = match.group('change').strip()
                if line_diff:
                    if any(_re.match(line_diff) for _re in IGNORE_LINES):
                        continue
                    changed = True
                    break
        if not changed:
            print(('{} staged.'.format(change.a_path)))
            repo.index.add([change.a_path])
