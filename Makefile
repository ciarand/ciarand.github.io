default: _site

.PHONY: serve
serve:
	bundle exec jekyll s

.PHONY: deploy
deploy: _site
	firebase deploy

_site: css/style.css
	bundle exec jekyll b

css/style.css: css/lanyon.css css/poole.css css/syntax.css
	npm run css
