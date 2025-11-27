# Ansify.nvim

This is a simple, and fairly minimal Neovim plugin that allows you to view content that contains ANSI escapes as intended within
the editor, using Neovim's terminal functionality to process the escapes.

# Documentation

The full documentation is in [doc/ansify.txt](doc/ansify.txt).

# Acknowledgments

- https://github.com/neovim/neovim/issues/30415#issuecomment-2368519968 for the start of the implementation, although this has added some additional functionality
- https://github.com/kovidgoyal/kitty/issues/719 for some ideas on how to handle kitty's scrollback buffer with Neovim

# Alternatives

There are some other plugins I'm aware of that solve similar problems. However, these
either don't take advantage of Neovim's terminal mode, or in the case of
kitty-scrollback.nvim, are larger and more complicated than what I needed.

- https://github.com/m00qek/baleia.nvim processes escapes in Lua code
- https://github.com/powerman/vim-plugin-AnsiEsc processes escapes with vimscript
- https://github.com/mikesmithgh/kitty-scrollback.nvim If you are using this exclusively for viewing scrollback with kitty

