return {
  -- 1. The Core Engine: VimTeX
  {
    "lervag/vimtex",
    lazy = false, -- VimTeX needs to load on startup to detect filetypes correctly
    init = function() -- VimTeX uses global variables for configuration
      -- Set Zathura as the default PDF viewer
      vim.g.vimtex_view_method = "zathura"

      -- Disable auto-opening the quickfix window for minor warnings
      vim.g.vimtex_quickfix_mode = 0

      -- Enable LaTeX concealing (makes math symbols look like actual math in Neovim)
      vim.opt.conceallevel = 1
      vim.g.vimtex_syntax_conceal = {
        math_bounds = 1,
        math_delimiters = 1,
        math_fracs = 1,
        math_super_sub = 1,
        math_symbols = 1,
      }
    end,
  },

  -- 2. The LSP: TexLab
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        texlab = {
          -- You can add TexLab-specific settings here if needed
          settings = {
            texlab = {
              build = {
                executable = "latexmk",
                args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
                onSave = true,
                forwardSearchAfter = false,
              },
            },
          },
        },
      },
    },
  },
}
