
local api = vim.api

local M = {}

M.file_prefix = "ansify://"

local file_chunks = function(path)
  local f = io.open(path)
  return function()
    -- Read file in chunks of a typical page size
    local chunk = f:read(4096)
    if chunk == nil then
      f:close()
    end
    return chunk
  end
end

---@param src string|fun():string Either the text to process, or an iterator of chunks of strings
---@param opts Params
---@return integer buffer The buffer containing the processed content
local process_content = function(src, buf)

  -- set scrollback to max size
  vim.bo[buf].scrollback = 100000

  local trm = api.nvim_open_term(buf, {})
  if type(src) == 'string' then
    api.nvim_chan_send(trm, src)
  else
    for chunk in src do
      api.nvim_chan_send(trm, chunk)
    end
  end
  -- TODO: custom keybindings?
  -- TODO fire custom event
  -- TODO: set buffer name

  api.nvim_win_set_buf(0, buf)
  return buf
  -- TODO: parse kitty_pipe_data
end

---@class BufOpts
---@field close? boolean Whether the original buffer shoudl be closed
---@field buffer? integer Buffer to use as the source. Defaults to current buffer


--- Process terminal escapes in the current buffer, and create a new terminal buffer based on that
--- content.
---
---@param src_buf? integer The buffer to process. Defaults to current buffer
---@param close? boolean If true, close the source buffer after opening the new one
function  M.ansify_buffer(opts)
  -- TODO: set laststatus
  local src = opts.buffer
  if not src or src == 0 then
    src =  vim.api.nvim_get_current_buf()
  end
  local lines = vim.api.nvim_buf_get_lines(src, 0, -1, false)
  local buf = api.nvim_create_buf(false, true)
  local filename = M.file_prefix .. api.nvim_buf_get_name(src)
  api.nvim_buf_set_name(buf, filename)
  process_content(table.concat(lines, "\n"), buf)
  vim.cmd.doautocmd{ args = {'BufRead', filename }}
  if opts.close then
    vim.cmd.bdelete{src, bang = true}
  end
  api.nvim_win_set_buf(0, buf)
  return buf
end

--- Open a file, while processing any ansi escapes
---@param path string Path to open
function M.open(path)
  local buf = api.nvim_create_buf(true, true)
  local filename = M.file_prefix .. path
  api.nvim_buf_set_name(buf, filename)
  process_content(file_chunks(path), buf)
  vim.cmd.doautocmd{ args = {'BufRead', filename}}
end

function M.buf_read(filename, buf)
  vim.cmd.doautocmd{ args = {'BufReadPre', filename}}
  local path = filename:match"^ansify://(.*)"
  vim.bo[buf].buflisted = true
  vim.bo[buf].modeline = false
  vim.bo[buf].bufhidden = 'hide'
  process_content(file_chunks(path), buf)
  vim.cmd.doautocmd{ args = {'BufReadPost', filename}}
end

return M
