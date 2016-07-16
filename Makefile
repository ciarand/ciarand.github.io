.PHONY: default serve deploy site css clean

default: site
css: css/style.min.css
site: _site

serve: css
	bundle exec jekyll s

deploy: site
	./deploy.sh

clean:
	rm -rf _site css/ bin/

_site: css
	bundle exec jekyll b

bin/minify_css: cmd/minify_css/minify_css.go
	mkdir -p bin
	go build -o bin/minify_css ./cmd/minify_css

css_files := $(wildcard src/css/*.css)
css/style.min.css: $(css_files) bin/minify_css
	mkdir -p css
	cat $(css_files) | bin/minify_css > $@
