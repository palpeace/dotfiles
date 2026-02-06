return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      -- 初回インストール時に自動で npm install を実行する
      vim.fn["mkdp#util#install"]()
    end,

    init = function()
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_filetypes = { "markdown" }
    end,

    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_mermaid = 1
    end,
  },
}
