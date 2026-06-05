#!/usr/bin/env python3

import sys

from lib import relpath

if __name__ == "__main__":
    print(relpath(sys.argv[1], sys.argv[2]))
