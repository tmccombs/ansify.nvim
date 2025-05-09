
local api = vim.api
local uv = vim.uv

local M = {}

M.file_prefix = "ansify://"

---@param stream uv_stream_t Stream to copy
---@param chan integer Channel to write to
---@param on_done (fun(): any) Callback to call when everything has been copied
local stream_to_channel = function(stream, chan, on_done)
  uv.read_start(stream, function(err, chunk)
    assert(not err, err)
    if chunk then
      vim.schedule(function()
        api.nvim_chan_send(chan, chunk)
      end)
    else
      assert(uv.close(stream))
      vim.schedule(on_done)
    end
  end)
end

---@param file integer file descriptor for file to copy
---@param chan integer Channel to write to
---@param on_done (fun(): any) Callback to call when everything has been copied
local file_to_channel = function(file, chan, on_done)
  print('Reading '..file)
  local bufsize = 4096
  local callback
  callback = function(err, chunk)
    assert(not err, err)
    if chunk and chunk ~= '' then
      vim.schedule(function()
        api.nvim_chan_send(chan, chunk)
        -- read the next chunk
        uv.fs_read(file, bufsize, nil, callback)
      end)
    else
      print('done')
      assert(uv.fs_close(file))
      vim.schedule(on_done)
    end
  end
  uv.fs_read(file, bufsize, nil, callback)
end

---@param fd integer File Descriptor to copy from
---@param chan integer Channel to write to
---@param on_done (fun(): any) Callback to call when everything has been copied
local fd_to_channel = function(fd, chan, on_done)
  local stat = uv.fs_fstat(fd)
  if stat.type == 'fifo' then
    local pipe = uv.pipe_new(false)
    pipe:open(fd)
    stream_to_channel(pipe, chan, on_done)
  else
    file_to_channel(fd, chan, on_done)
  end
end

--- Read the contents of a file (or pipe) at path into a channel
---@param path string path of the file to read
---@param chan integer The channel to write to
---@param on_done (fun(): any) Callback to call when everything has been copied
local read_path = function(path, chan, on_done)
  print('opening '..path)
  local fd, err = uv.fs_open(path, 'r', 0)
  assert(not err, err)
  fd_to_channel(fd, chan, on_done)
end

--- Set up the terminal channel for a buffer
--- and configure buffer for terminal usage
local create_term = function(buf)
  -- set scrollback to max size
  vim.bo[buf].scrollback = 100000

  -- TODO: custom keybindings?

  return api.nvim_open_term(buf, {})
end

---@class BufOpts
---@field buffer? integer Buffer to use as the source. Defaults to current buffer


--- Process terminal escapes in the current buffer, and create a new terminal buffer based on that
--- content.
---
---@param opts BufOpts
function  M.ansify_buffer(opts)
  -- TODO: make use of https://github.com/neovim/neovim/pull/33720
  local buf = opts.buffer
  if not src or src == 0 then
    buf =  vim.api.nvim_get_current_buf()
  end
  -- TODO: just read lines, then delete them, and use the current buffer?
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- Delete the lines we just read
  api.nvim_buf_set_lines(buf, 0, -1, false, {})
  --local buf = api.nvim_create_buf(false, true)
  local term = create_term(buf)
  api.nvim_chan_send(term, table.concat(lines, "\n"))
  api.nvim_exec_autocmds('BufRead', {buffer = buf })
  return buf
end

--- Open a file, while processing any ansi escapes
---@param path string Path to open
function M.open(path)
  local buf = api.nvim_create_buf(true, true)
  local filename = M.file_prefix .. path
  api.nvim_buf_set_name(buf, filename)
  local term = create_term(buf)
  local fullpath = vim.fn.expand(path)
  read_path(fullpath,  term, function()
    api.nvim_exec_autocmds('BufRead', { buffer = buf })
  end)
  api.nvim_win_set_buf(0, buf)
end

function M.buf_read(filename, buf)
  api.nvim_exec_autocmds('BufReadPre', { buffer = buf })
  local path = filename:match"^ansify://(.*)"
  vim.bo[buf].buflisted = true
  vim.bo[buf].modeline = false
  vim.bo[buf].bufhidden = 'hide'
  local term = create_term(buf)
  read_path(vim.fn.expand(path), term, function()
    api.nvim_exec_autocmds('BufReadPost', { buffer = buf })
  end)
end

return M
