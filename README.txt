syrox.nvim

Neovim 0.11+ client for Syrox (.srx), using the external srx lsp server.
Source: https://github.com/ryro-hq/syrox.nvim
Language server: https://github.com/ryro-hq/syrox

Install with lazy.nvim:

  {
    "ryro-hq/syrox.nvim",
    lazy = false,
    opts = { cmd = { "srx", "lsp" } },
    config = function(_, opts) require("syrox").setup(opts) end,
  }

Install/build srx separately and put it on PATH, or use an absolute cmd path.
The server must include the srx lsp command; client and server are pre-release.

Provides filetype detection, lexical highlighting, standard Neovim LSP features,
type hints when supported, and read-only virtual standard-library sources.
For blink.cmp set completion=false and supply its capabilities in lsp.capabilities.
Set keymaps=false to keep your own buffer mappings. See :help syrox-setup.

Tests from this repository:
  SRX_BIN=/path/to/srx nvim --headless -u NONE -l tests/smoke.lua
  SRX_BIN=/path/to/srx SRX_STD_DIR=/path/to/syrox/std nvim --headless -u NONE -l tests/std.lua

Each editor client has its own repository and release cycle. Language semantics,
type checking and ownership analysis remain in the Syrox server.
