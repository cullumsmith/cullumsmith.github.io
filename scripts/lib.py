#!/usr/bin/env python3

import os
import subprocess
from datetime import date, datetime, timezone
from fnmatch import fnmatch
from glob import glob
from pathlib import Path
from urllib.parse import quote

import dateparser
import frontmatter
from typing_extensions import final, override

BLOG_LIST_FILE = "__BLOGLIST.md"

EXCLUDE_PATTERNS = [f"*{BLOG_LIST_FILE}", "google*.html"]


@final
class Page:
    def __init__(self, path: str):
        self._path = path
        self._metadata = None

    @property
    def path(self):
        return self._path

    @property
    def href(self):
        path = Path(self._path)
        path = path.relative_to(*path.parts[:1])
        if path.name == "index.md":
            if len(path.parts) == 1:
                return "/"
            return "/{}/".format(path.parent)
        else:
            return "/{}/{}.html".format(path.parent, path.stem)

    @property
    def metadata(self):
        if self._metadata is None:
            try:
                self._metadata = frontmatter.load(self.path).to_dict()
            except:
                self._metadata = {}
        return self._metadata

    @property
    def git_date(self):
        fs_mtime = Path(self.path).stat().st_mtime
        git_mtime = subprocess.run(
            ["git", "log", "-1", "--format=%cI", self._path],
            stdout=subprocess.PIPE,
            check=True,
            universal_newlines=True,
        ).stdout.strip()
        try:
            return datetime.fromisoformat(git_mtime)
        except:
            return datetime.fromtimestamp(fs_mtime).replace(microsecond=0).astimezone()

    @property
    def date(self):
        t = self.metadata.get("date")
        if t is None:
            return self.git_date
        if isinstance(t, datetime):
            return t
        if isinstance(t, date):
            return datetime.combine(t, datetime.min.time())

        guess = dateparser.parse(str(t))
        if guess is None:
            raise ValueError(f"invalid date for page {self}: {t}")
        return guess

    @property
    def title(self):
        return self.metadata.get("title")

    @property
    def author(self):
        return self.metadata.get("author")

    @property
    def description(self):
        return self.metadata.get("description")

    @property
    def draft(self):
        return self.metadata.get("draft")

    def __lt__(self, other: object):
        if isinstance(other, Page):
            return self.date.astimezone() < other.date.astimezone()
        raise NotImplementedError

    @override
    def __str__(self):
        return self.path


def relpath(root_dir: str, path: str):
    root_dir_p = Path(root_dir)
    path_p = Path(path)
    relpath = path_p.relative_to(root_dir_p)

    if path_p == root_dir_p:
        raise ValueError("path and root_dir are the same!")

    if relpath.name in ["index.html", "index.md"]:
        parent = relpath.parent.as_posix()
        if parent == ".":
            url = ""
        else:
            url = parent + os.sep
    else:
        url = relpath.as_posix()

    return quote(url)


def get_blog_posts(source_dir: str):
    posts = [Page(f) for f in glob(f"{source_dir}/*/index.md") if os.path.isfile(f)]
    posts = [p for p in posts if not p.draft]
    return sorted(posts, reverse=True)


def get_pages(source_dir: str):
    pages: list[Page] = []
    for root, _dirs, files in os.walk(source_dir):
        for file in files:
            path = os.path.join(root, file)
            if path.endswith(".md") or path.endswith(".html"):
                exclude = False
                for pattern in EXCLUDE_PATTERNS:
                    if fnmatch(path, pattern):
                        exclude = True
                        break
                if exclude:
                    continue
                page = Page(path)
                if not page.draft:
                    pages.append(page)
    return sorted(pages, reverse=True)
