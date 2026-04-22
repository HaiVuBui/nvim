local function next_footnote_id(bufnr)
  bufnr = bufnr or 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local max_id = 0

  for _, line in ipairs(lines) do
    for id in line:gmatch("%[%^(%d+)%]") do
      max_id = math.max(max_id, tonumber(id))
    end
    for id in line:gmatch("^%[%^(%d+)%]:") do
      max_id = math.max(max_id, tonumber(id))
    end
  end

  return max_id + 1
end

local function insert_text_at_cursor(text)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col + 1) .. text .. line:sub(col + 2)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, { row, col + #text })
end

local function insert_next_footnote_with_def()
  local id = next_footnote_id(0)
  local footnote = ("[^%d]: "):format(id)
  local last_line = vim.api.nvim_buf_line_count(0)
  insert_text_at_cursor(("[^%d]"):format(id))
  vim.api.nvim_buf_set_lines(0, -1, -1, false, { footnote })
  vim.api.nvim_win_set_cursor(0, { last_line + 1, #footnote })
end

vim.keymap.set("n", "<localleader>c", insert_next_footnote_with_def, {
  buffer = true,
  desc = "Insert next footnote cite + definition",
})
