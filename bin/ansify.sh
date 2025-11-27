#!/usr/bin/env bash

# This is a wrapper script to launch neovim using the ansify plugin to edit the scrollback buffer
# with colors preserved.
#
# To invoke from kitty use something like:
#     launch --stdin-source=@screen_scrollback --stdin-add-formatting --type=overlay ansify.sh @input-line-number @cursor-x @cursor-y

if [[ $# -ne 3 ]]; then
    printf "USAGE: ansify.sh <line-number> <cursor-x> <cursor-y>" >&2
    exit 1
fi

exec nvim -c "lua require'ansify.kitty'.scroll_to($1, $3, $2)"
