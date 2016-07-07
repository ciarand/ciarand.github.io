default: _site

.PHONY: serve
serve:
	bundle exec jekyll s

.PHONY: deploy
deploy: _site
	firebase deploy

.PHONY: clean
clean:
	rm -rf _site css/style.min.css

_site: css/style.min.css
	bundle exec jekyll b

css/style.min.css: css/lanyon.css css/poole.css css/syntax.css
	npm run css
