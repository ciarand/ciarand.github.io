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

# relies on tdewolff/minify/tree/master/cmd/minify
css/style.min.css: $(wildcard src/css/*.css)
	mkdir -p css
	cat $^ | minify --type=css > $@
