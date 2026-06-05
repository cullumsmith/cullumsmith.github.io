#!/usr/bin/env python3

import sys

from lib import get_pages

baseurl = sys.argv[1]
source_dir = sys.argv[2]


print('<?xml version="1.0" encoding="UTF-8"?>')
print('<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">')
for page in get_pages(source_dir):
    print("  <url>")
    print(f"    <loc>{baseurl}{page.href}</loc>")
    print(f"    <lastmod>{page.git_date}</lastmod>")
    print("  </url>")
print("</urlset>")
