vim.opt_local.conceallevel = 0
vim.opt_local.concealcursor = ""

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

local function paste_image_from_clipboard()
  -- Get image from wl-clipboard
  local handle = io.popen("wl-paste --type image/png 2>/dev/null | wc -c")
  local size = tonumber(handle:read("*a"))
  handle:close()

  if not size or size == 0 then
    vim.notify("No image found in clipboard", vim.log.levels.WARN)
    return
  end

  -- Create assets directory if it doesn't exist
  local cwd = vim.fn.getcwd()
  local assets_dir = cwd .. "/assets"
  vim.fn.mkdir(assets_dir, "p")

  -- Generate unique filename with human-readable timestamp
  local timestamp = os.date("%Y_%m_%d_%H_%M_%S")
  local filename = timestamp .. ".png"
  local filepath = assets_dir .. "/" .. filename

  -- Save image from clipboard
  local cmd = string.format("wl-paste --type image/png > %s", vim.fn.shellescape(filepath))
  local result = os.execute(cmd)

  if result == 0 then
    -- Insert markdown link at cursor
    local image_ref = string.format("![](./assets/%s)", filename)
    insert_text_at_cursor(image_ref)
    vim.notify("Image saved to ./assets/" .. filename, vim.log.levels.INFO)
  else
    vim.notify("Failed to save image from clipboard", vim.log.levels.ERROR)
  end
end

local function paste_video_from_screenrecords()
  local screenrecords_dir = vim.fn.expand("~/Pictures/screenrecords")
  local handle = io.popen(string.format("ls -t %s/*.mp4 2>/dev/null | head -1", vim.fn.shellescape(screenrecords_dir)))
  local latest = handle:read("*a"):gsub("%s+$", "")
  handle:close()

  if latest == "" then
    vim.notify("No mp4 files found in ~/Pictures/screenrecords", vim.log.levels.WARN)
    return
  end

  local cwd = vim.fn.getcwd()
  local assets_dir = cwd .. "/assets"
  vim.fn.mkdir(assets_dir, "p")

  local timestamp = os.date("%Y_%m_%d_%H_%M_%S")
  local filename = timestamp .. ".mp4"
  local dest = assets_dir .. "/" .. filename

  local ok = os.execute(string.format("cp %s %s", vim.fn.shellescape(latest), vim.fn.shellescape(dest)))
  if ok ~= 0 then
    vim.notify("Failed to copy video to ./assets/", vim.log.levels.ERROR)
    return
  end

  local video_ref = string.format('<video src="./assets/%s" controls></video>', filename)
  insert_text_at_cursor(video_ref)
  vim.notify("Video linked: ./assets/" .. filename, vim.log.levels.INFO)
end

local function paste_media_picker()
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local items = {
    { label = "Paste Image  (from clipboard)", action = paste_image_from_clipboard },
    { label = "Paste Video  (latest screenrecord)", action = paste_video_from_screenrecords },
  }

  pickers.new({
    layout_strategy = "cursor",
    layout_config = { width = 50, height = 6 },
  }, {
    prompt_title = "Paste Media",
    finder = finders.new_table({
      results = items,
      entry_maker = function(item)
        return { value = item, display = item.label, ordinal = item.label }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(buf, _)
      actions.select_default:replace(function()
        actions.close(buf)
        action_state.get_selected_entry().value.action()
      end)
      return true
    end,
  }):find()
end

vim.keymap.set("n", "<C-A-v>", paste_media_picker, {
  buffer = true,
  desc = "Paste image or video (telescope picker)",
})

local function path_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local i = 1
  while true do
    local s, e, path = line:find("%]%(([^)]+)%)", i)
    if not s then break end
    if col >= s and col <= e then return path end
    i = e + 1
  end
  local cfile = vim.fn.expand("<cfile>")
  return cfile ~= "" and cfile or nil
end

vim.keymap.set("n", "gY", function()
  local path = path_under_cursor()
  if not path then
    vim.notify("No path under cursor", vim.log.levels.WARN)
    return
  end
  if path:match("^%w+://") then
    vim.fn.setreg("+", path)
    vim.notify("Copied URL: " .. path)
    return
  end
  local expanded = vim.fn.expand(path)
  local abs
  if expanded:sub(1, 1) == "/" then
    abs = expanded
  else
    abs = vim.fn.fnamemodify(vim.fn.expand("%:p:h") .. "/" .. expanded, ":p")
  end
  vim.fn.setreg("+", abs)
  vim.notify("Copied: " .. abs)
end, { buffer = true, desc = "Copy absolute path of link/file under cursor" })

vim.keymap.set("n", "gx", function()
  local path = path_under_cursor()
  if not path then
    vim.notify("No link under cursor", vim.log.levels.WARN)
    return
  end
  local target
  if path:match("^%w+://") or path:match("^mailto:") then
    target = path
  else
    local expanded = vim.fn.expand(path)
    if expanded:sub(1, 1) == "/" then
      target = expanded
    else
      target = vim.fn.fnamemodify(vim.fn.expand("%:p:h") .. "/" .. expanded, ":p")
    end
  end
  vim.ui.open(target)
end, { buffer = true, desc = "Open link/file under cursor" })
