local function cursor_location()
  local pos = vim.api.nvim_win_get_cursor(0)
  local line = pos[1] - 1
  local col = pos[2]

  return {
    uri = vim.uri_from_bufnr(0),
    range = {
      start = { line = line, character = col },
      ["end"] = { line = line, character = col },
    },
  }
end

return {
  "zk-org/zk-nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  ft = { "markdown" },
  config = function()
    require("zk").setup({})
  end,
  keys = {
    { "<leader>zn", "<cmd>ZkNew<cr>", desc = "Zk new note" },
    { "<leader>zi", "<cmd>ZkInsertLink<cr>", desc = "Zk insert link" },
    { "<leader>zf", "<cmd>ZkNotes<cr>", desc = "Zk find notes" },
    {
      "<leader>zg",
      function()
        local query = vim.fn.input("Search: ")
        if query == nil or query == "" then
          return
        end

        require("zk.commands").get("ZkNotes")({
          sort = { "modified" },
          match = { query },
        })
      end,
      desc = "Zk match search",
    },
    { "<leader>zt", "<cmd>ZkTags<cr>", desc = "Zk tags" },
    {
      "<leader>zT",
      function()
        local input = vim.fn.input("Tags search: ")
        if input == nil or input == "" then
          return
        end

        local tags = {}
        for tag in input:gmatch("%S+") do
          table.insert(tags, tag)
        end

        if #tags == 0 then
          return
        end

        require("zk.commands").get("ZkNotes")({
          sort = { "modified" },
          tags = tags,
        })
      end,
      desc = "Zk multi-tag search",
    },
    {
      "<leader>zo",
      function()
        require("zk").new({
          insertLinkAtLocation = cursor_location(),
        })
      end,
      desc = "Zk new note + link",
    },
  },
}
