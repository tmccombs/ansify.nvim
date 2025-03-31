# Ansify.nvim

This is a simple, and fairly minimal Neovim plugin that allows you to view content that contains ANSI escapes as intended within
the editor, using neovim's terminal functionality to process the escapes.

# Acknowledgements

- https://github.com/neovim/neovim/issues/30415#issuecomment-2368519968 for the start of the implementation, although this has added some additional functionality
- https://github.com/kovidgoyal/kitty/issues/719 for some ideas on how to handle kitty's scrollback buffer with neovim

# Alternatives

- https://github.com/m00qek/baleia.nvim processes escapes in lua code
- https://github.com/mikesmithgh/kitty-scrollback.nvim If you are using this exclusively for viewing scrollback with kitty
- https://github.com/powerman/vim-plugin-AnsiEsc processes escapes with vimscript

