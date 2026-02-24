return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      return vim.tbl_deep_extend("force", opts, {
        explorer = {
          hidden = true,
        },
        picker = {
          sources = {
            files = { hidden = true },
            explorer = { hidden = true },
          },
        },
      })
    end,
  },
}
