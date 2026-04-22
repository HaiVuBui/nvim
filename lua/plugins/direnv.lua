-- lua/plugins/direnv.lua
return {
  {
    "actionshrimp/direnv.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      type = "buffer",
      buffer_setup = {
        autocmd_event = "BufReadPre",
        autocmd_pattern = "*",
      },
    },
  },
}
