#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   @author         :   Chris Burnham
#   @file           :   home/dot_config/homebrew/dump_brewfile.sh
#   @description    :   Update Homebrew bundle file
#   @usage          :   ./home/dot_config/homebrew/dump_brewfile.sh
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

set -u

DOTFILE_BREWFILE_PATHS="home/dot_config/homebrew/Brewfile-bundle-dump"

# dump homebrew bundle
brew bundle dump --describe --force --file="${DOTFILE_BREWFILE_PATHS}"
