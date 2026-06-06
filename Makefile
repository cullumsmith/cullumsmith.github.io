BASE_URL           = https://www.sacredheartsc.com
STATIC_REGEX       = .*\.(html|jpg|jpeg|png|xml|txt|ico|webmanifest|svg|asc)
BLOG_LIST_LIMIT    = 3
FEED_TITLE         = Cullum Smith's Blog
FEED_DESCRIPTION   = Wrangling scripts in the shell and quilismas in the choir loft.

RSYNC_TARGET       = www1.idm.sacredheartsc.com:/usr/local/www/vhosts/www.sacredheartsc.com/

OS := $(shell uname -s)
ifeq ($(OS),FreeBSD)
	FIND = gfind
else
	FIND = find
endif

SOURCE_DIR          = src
OUTPUT_DIR          = dist
SCRIPT_DIR          = scripts
BLOG_DIR            = blog
TEMPLATE_DIR        = templates
FEED_PATH           = feed.xml
DEFAULT_TEMPLATE    = $(TEMPLATE_DIR)/default.html
CV_TEMPLATE         = $(TEMPLATE_DIR)/cv.html
HOMEPAGE_TEMPLATE   = $(TEMPLATE_DIR)/homepage.html
PANDOC_CONFIG       = pandoc.yml
DEFAULT_CSS         = $(SOURCE_DIR)/style.css
PANDOC_METADATA     = metadata.md
BLOGLIST_REPLACE    = __BLOGLIST__
BLOGLIST_FILENAME   = __BLOGLIST.md
SOURCE_DIRS        := $(shell $(FIND) $(SOURCE_DIR) -mindepth 1 -type d)
SOURCE_MARKDOWN    := $(shell $(FIND) $(SOURCE_DIR) -type f -name '*.md' -and ! -name $(BLOGLIST_FILENAME))
SOURCE_STATIC      := $(shell $(FIND) $(SOURCE_DIR) -type f -regextype posix-extended -iregex '$(STATIC_REGEX)')
SOURCE_BLOG        := $(shell $(FIND) $(SOURCE_DIR)/$(BLOG_DIR) -type f -name '*.md' -and ! -name $(BLOGLIST_FILENAME) -and ! -path $(SOURCE_DIR)/$(BLOG_DIR)/index.md)
OUTPUT_DIRS        := $(patsubst $(SOURCE_DIR)/%, $(OUTPUT_DIR)/%, $(SOURCE_DIRS))
OUTPUT_MARKDOWN    := $(patsubst $(SOURCE_DIR)/%, $(OUTPUT_DIR)/%, $(patsubst %.md, %.html, $(SOURCE_MARKDOWN)))
OUTPUT_STATIC      := $(patsubst $(SOURCE_DIR)/%, $(OUTPUT_DIR)/%, $(SOURCE_STATIC))
OUTPUT_SITEMAP      = $(OUTPUT_DIR)/sitemap.xml
OUTPUT_RSS          = $(OUTPUT_DIR)/$(FEED_PATH)
OUTPUT_BLOGLIST_SHORT = $(SOURCE_DIR)/$(BLOGLIST_FILENAME)
OUTPUT_BLOGLIST       = $(SOURCE_DIR)/$(BLOG_DIR)/$(BLOGLIST_FILENAME)

CP                  = cp -p
MKSITEMAP           = $(SCRIPT_DIR)/sitemap.py
MKRSS               = $(SCRIPT_DIR)/rss.py
MKBLOGLIST          = $(SCRIPT_DIR)/bloglist.py
INTERPOLATE         = sed -e '/$(1)/{r $(2)' -e 'd;}'
RELPATH             = $(shell $(SCRIPT_DIR)/relpath.py $(OUTPUT_DIR) "$(1)")
PANDOC              = pandoc \
												--defaults=$(PANDOC_CONFIG) \
												--include-in-header="$(DEFAULT_CSS)" \
												--template="$(1)" \
												--metadata="relpath:$(call RELPATH,$(2))" \
												--metadata="baseurl:$(BASE_URL)" \
												--metadata="feed:/$(FEED_PATH)" \
												--output="$(2)" \
												$(PANDOC_METADATA) \
												-

# Default target
build: \
	$(OUTPUT_DIRS) \
	$(OUTPUT_MARKDOWN) \
	$(OUTPUT_STATIC) \
	$(OUTPUT_SITEMAP) \
	$(OUTPUT_RSS)

# All directories
$(OUTPUT_DIRS):
	mkdir -p $@

# Homepage (/)
$(OUTPUT_DIR)/index.html: $(SOURCE_DIR)/index.md $(OUTPUT_BLOGLIST_SHORT) $(HOMEPAGE_TEMPLATE) $(PANDOC_CONFIG) $(PANDOC_METADATA) $(DEFAULT_CSS)
	$(call INTERPOLATE,$(BLOGLIST_REPLACE),$(OUTPUT_BLOGLIST_SHORT)) $< | $(call PANDOC,$(HOMEPAGE_TEMPLATE),$@)

# CV (/cv/)
$(OUTPUT_DIR)/cv/index.html: $(SOURCE_DIR)/cv/index.md $(OUTPUT_BLOGLIST_SHORT) $(CV_TEMPLATE) $(PANDOC_CONFIG) $(PANDOC_METADATA) $(DEFAULT_CSS)
	$(call INTERPOLATE,$(BLOGLIST_REPLACE),$(OUTPUT_BLOGLIST_SHORT)) $< | $(call PANDOC,$(CV_TEMPLATE),$@)

# Short blog listing
$(OUTPUT_BLOGLIST_SHORT): $(SOURCE_BLOG) $(MKBLOGLIST)
	$(MKBLOGLIST) $(SOURCE_DIR)/$(BLOG_DIR) $(BLOG_LIST_LIMIT) > $@

# Full blog listing
$(OUTPUT_BLOGLIST): $(SOURCE_BLOG) $(MKBLOGLIST)
	$(MKBLOGLIST) $(SOURCE_DIR)/$(BLOG_DIR) > $@

# Blog (/blog/)
$(OUTPUT_DIR)/$(BLOG_DIR)/index.html: $(SOURCE_DIR)/$(BLOG_DIR)/index.md $(OUTPUT_BLOGLIST) $(DEFAULT_TEMPLATE) $(PANDOC_CONFIG) $(PANDOC_METADATA) $(DEFAULT_CSS)
	$(call INTERPOLATE,$(BLOGLIST_REPLACE),$(OUTPUT_BLOGLIST)) $< | $(call PANDOC,$(DEFAULT_TEMPLATE),$@)

# Sitemap
$(OUTPUT_SITEMAP): $(SOURCE_MARKDOWN) $(SOURCE_STATIC) $(MKSITEMAP)
	$(MKSITEMAP) $(BASE_URL) $(SOURCE_DIR) > $@

# RSS feed
$(OUTPUT_RSS): $(SOURCE_BLOG) $(MKRSS)
	$(MKRSS) $(SOURCE_DIR)/$(BLOG_DIR) --blog-path /$(BLOG_DIR) --feed-path /$(FEED_PATH) --url $(BASE_URL) --title "$(FEED_TITLE)" --description "$(FEED_DESCRIPTION)" > $@

# Convert all other .md files to .html
$(OUTPUT_DIR)/%.html: $(SOURCE_DIR)/%.md $(DEFAULT_TEMPLATE) $(PANDOC_CONFIG) $(PANDOC_METADATA) $(DEFAULT_CSS)
		$(call PANDOC,$(DEFAULT_TEMPLATE),$@) < $<

# Catch-all: copy static assets in $(SOURCE_DIR)/ to $(OUTPUT_DIR)/
$(OUTPUT_DIR)/%: $(SOURCE_DIR)/%
		$(CP) $< $@

.PHONY: serve clean rsync deps
serve: build
		cd $(OUTPUT_DIR) && python3 -m http.server

clean:
		rm -rf $(OUTPUT_DIR) $(SOURCE_DIR)/$(BLOG_DIR)/$(BLOGLIST_FILENAME) $(SOURCE_DIR)/$(BLOGLIST_FILENAME)

rsync: build
	rsync -rlphv --delete ${OUTPUT_DIR}/ ${RSYNC_TARGET}

deps:
	pip install -r requirements.txt
