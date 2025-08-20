return {
  "nvim-treesitter/nvim-treesitter",
	prefer_git = false,
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      highlight = {
        enable = true,
      },
      -- enable indentation
      indent = { enable = true },

      -- ensure these language parsers are installed
      ensure_installed = {
        "odin",
        "glsl",
        "json",
        "javascript",
        "html",
        "css",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "c",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })
  end,
}
