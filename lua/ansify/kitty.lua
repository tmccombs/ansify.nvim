local ansify = require "ansify"

--- Parse kitty information from the KITTY_PIPE_DATA environment variable.
--- See https://sw.kovidgoyal.net/kitty/launch/#the-piping-environment
--- Expected format is {scrolled_by}:{cursor_x},{cursor_y}:{lines},{columns}
local get_pipe_data = function()
	local pipe_data = vim.env.KITTY_PIPE_DATA
	if not pipe_data then
		return
	end
	local parts = vim.split(pipe_data, ":")
	if #parts ~= 3 then
		vim.notify("Unexpected value for KITTY_PIPE_DATA: " .. pipe_data, vim.log.levels.WARN)
		return
	end
	local cursor = vim.split(parts[2], ",")
	if #cursor ~= 2 then
		vim.notify("Unexpected value for cursor position: " .. parts[2], vim.log.levels.WARN)
		return
	end
	return {
		scrolled_by = parts[1],
		cur = { tonumber(cursor[1]), tonumber(cursor[2]) },
	}
end

---@param first_line number
---@param y number
---@param x number
local navigate = function(first_line, y, x)
	vim.wo.scrolloff = 0
	-- TODO: check that scrolled_by is a number
	-- TODO: check that cursor position is valid
	vim.cmd {
		cmd = "normal",
		bang = true,
		args = { first_line .. "zt" },
	}
	-- kitty column is 1-based, but nvim is 0-based
	-- And the row is from the top of the screen, not the top of the buffer
	vim.api.nvim_win_set_cursor(0, { first_line + y - 1, x - 1 })
	-- TODO: reset scrolloff?
end

return {
	--- Ansify the current buffer, and position the scroll and cursor based on the provided
	--- arguments. These are intended to come from Kitty's "special arguments" or similar.
	---@param first_line  The number of the first line to show in the buffer.
	---  Kitty's "@first-line-on-screen"
	---@param y Y position of cursor, on the screen, with 1 being the first visible row
	---  Kitty's "@cursor-y"
	---@param x X position of cursor, with 1 being the first column.
	---  Kitty's "@cursor-x"
	---@see https://sw.kovidgoyal.net/kitty/launch/#special-arguments
	scroll_to = function(first_line, y, x)
		ansify.pager {
			on_finish = function()
				navigate(first_line, y, x)
			end,
		}
	end,
	--- Parse the KITTY_PIPE_DATA environment variable, and use it to determine
	--- the proper scroll position for the buffer. Then Ansify the current buffer,
	--- and scroll to the position from the parsed data.
	---@see https://sw.kovidgoyal.net/kitty/launch/#the-piping-environment
	from_env = function()
		local data = get_pipe_data()
		if not data then
			return
		end
		ansify.pager {
			on_finish = function()
				vim.wo.scrolloff = 0
				vim.cmd {
					cmd = "normal",
					bang = true,
					-- Scroll to the bottom, then scroll up by "scrolled-by"
					args = { "G" .. data.scrolled_by .. vim.keycode "<c-y>" },
				}
			end,
		}
	end,
}
