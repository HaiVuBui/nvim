return {
  {
    "amitds1997/remote-nvim.nvim",
    version = "*",
    cmd = {
      "RemoteStart",
      "RemoteStop",
      "RemoteInfo",
      "RemoteCleanup",
      "RemoteConfigDel",
      "RemoteLog",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      progress_view = {
        type = "split",
      },
    },
    config = function(_, opts)
      local ok, ProgressView = pcall(require, "remote-nvim.ui.progressview")
      if ok and ProgressView and not ProgressView._polaris_safe_render_patch then
        local collapse = ProgressView._collapse_all_nodes
        local expand = ProgressView._expand_all_nodes

        ProgressView._collapse_all_nodes = function(...)
          local success, err = pcall(collapse, ...)
          if not success and not tostring(err):match("Invalid buffer id") then
            error(err)
          end
        end

        ProgressView._expand_all_nodes = function(...)
          local success, err = pcall(expand, ...)
          if not success and not tostring(err):match("Invalid buffer id") then
            error(err)
          end
        end

        ProgressView._polaris_safe_render_patch = true
      end

      require("remote-nvim").setup(opts)
    end,
  },
}
