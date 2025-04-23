#!/usr/bin/env bash

DOTFILE_BREWFILE_PATHS="home/dot_config/homebrew/Brewfile-bundle-dump-shard"

# dump homebrew bundle
brew bundle dump --describe --force --file="${DOTFILE_BREWFILE_PATHS}"
