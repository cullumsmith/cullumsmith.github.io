#!/usr/bin/env python3

import argparse
from lib import get_blog_posts

DATE_FORMAT = '%Y-%m-%d'

parser = argparse.ArgumentParser('bloglist')
parser.add_argument('BLOG_DIR', type=str, help='Directory containing markdown blog posts')
parser.add_argument('LIMIT', nargs='?', default=None, type=int, help='Maximum number of posts to show')
args = parser.parse_args()

posts = get_blog_posts(args.BLOG_DIR)

if args.LIMIT is not None:
    posts = posts[:args.LIMIT]

if len(posts) == 0:
    print('Nothing has been posted yet!')
else:
    print('<ul class="bloglist">')
    for post in posts:
        print(f'<li><a href="{post.href}">{post.title}</a><span class="date">{post.date.strftime(DATE_FORMAT)}</span>', end='')
        if post.description is not None:
            print(f'<br>{post.description}</li>')
        else:
            print('</li>')
    print('</ul>')
