default: _site

.PHONY: serve
serve: css
	bundle exec jekyll s

.PHONY: deploy
deploy: site
	./deploy.sh

.PHONY: clean
clean:
	rm -rf _site css/style.min.css

site: _site
_site: css
	bundle exec jekyll b

css: css/style.min.css
css/style.min.css: css/lanyon.css css/poole.css css/syntax.css
	npm run css
