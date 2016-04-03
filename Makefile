.PHONY: serve
serve:
	bundle exec jekyll s

.PHONY: build
build:
	bundle exec jekyll build

.PHONY: deploy
deploy: build
	gsutil -m rsync -d -r ./_site gs://blog.ciarand.me
