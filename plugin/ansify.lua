local group = vim.api.nvim_create_augroup("ansify", {})

--- Ansify command
--- Process current buffer.
--- Bang means delete the original buffer
--- count can be used to specify a different buffer
vim.api.nvim_create_user_command("Ansify", function(opts)
	require("ansify").ansify_buffer {
		buffer = opts.count,
	}
end, {
	count = 0,
	desc = "Highlight ANSI termcodes in current buffer",
})

-- Similar to Ansify, but assumes this is used to open neovim as a pager
-- for a single file (which may be stdin), and do some additional configuration
vim.api.nvim_create_user_command("AnsiPage", function(opts)
	-- hide the status line, unless another window is opened
	vim.o.laststatus = 1
	vim.g.ansify_pager = true
	local buf = require("ansify").ansify_buffer {}
end, {
	desc = "Helper for using nvim as a pager for content with ANSI escapes",
})

vim.api.nvim_create_user_command("OpenAnsi", function(opts)
	require("ansify").open(opts.args)
end, {
	nargs = 1,
	desc = "Open the given file, with ANSI escapes highlighted",
	complete = "file",
})

local augroup = vim.api.nvim_create_augroup("__ansify", {})
vim.api.nvim_create_autocmd({ "BufReadCmd" }, {
	group = augroup,
	pattern = "ansify://*",
	desc = "Open file with processed ansi escapes",
	callback = function(ev)
		require("ansify").buf_read(ev.file, ev.buf)
	end,
})
