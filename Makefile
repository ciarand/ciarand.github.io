default: _site

.PHONY: deploy
deploy:
	firebase deploy

_site: css/style.css
	jekyll build

css/style.css: css/lanyon.css css/poole.css css/syntax.css
	npm run css

