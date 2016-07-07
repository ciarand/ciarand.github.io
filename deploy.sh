#!/usr/bin/env bash

deploy() {
    local date_str="$(date '+%Y-%m-%d-%H:%M:%S')"
    local git_rev="$(git rev-parse HEAD)"

    firebase deploy --message "${date_str}__${git_rev}"
}

deploy $@
