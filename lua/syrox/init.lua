local M = {}

local function virtual_source(event)
  local uri = vim.api.nvim_buf_get_name(event.buf)
  local last_error = "No Syrox LSP client is running"
  for _, client in ipairs(vim.lsp.get_clients({ name = "syrox" })) do
    local response, err = client:request_sync("syrox/readSource", { uri = uri }, 2000)
    if response and response.result and type(response.result.text) == "string" then
      local buffer = event.buf
      vim.bo[buffer].modifiable = true
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, vim.split(response.result.text, "\n", { plain = true }))
      vim.bo[buffer].buftype = "nofile"
      vim.bo[buffer].bufhidden = "hide"
      vim.bo[buffer].swapfile = false
      vim.bo[buffer].readonly = true
      vim.bo[buffer].modifiable = false
      vim.bo[buffer].modified = false
      vim.bo[buffer].filetype = "syrox"
      vim.lsp.buf_attach_client(buffer, client.id)
      return
    end
    last_error = response and response.err and response.err.message or err or last_error
  end
  error("Syrox virtual source unavailable; repeat Go to Definition from the source buffer. " .. tostring(last_error))
end

local function attach(client, buffer, opts)
  if opts.inlay_hints ~= false and client:supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
  end
  vim.bo[buffer].omnifunc = "v:lua.vim.lsp.omnifunc"
  if opts.completion ~= false and client.server_capabilities.completionProvider then
    vim.lsp.completion.enable(true, client.id, buffer, { autotrigger = true })
  end
  if opts.diagnostics ~= false then
    vim.diagnostic.config({ virtual_text = true, underline = true, severity_sort = true },
      vim.lsp.diagnostic.get_namespace(client.id))
  end
  if opts.keymaps ~= false then
    local function map(mode, key, action, description)
      vim.keymap.set(mode, key, action, { buffer = buffer, desc = "Syrox: " .. description })
    end
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
    map({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>ds", vim.lsp.buf.document_symbol, "Document symbols")
    map("n", "<leader>e", vim.diagnostic.open_float, "Line diagnostics")
    map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, "Previous diagnostic")
    map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, "Next diagnostic")
    if opts.completion ~= false then
      map("i", "<C-Space>", vim.lsp.completion.get, "Completion")
    end
  end
end

--- Configure Syrox for Neovim 0.11+. No lspconfig/completion plugin is required.
--- Options: cmd, standard_library_root, completion, diagnostics, keymaps, inlay_hints,
--- and lsp (extra LSP config).
function M.setup(opts)
  opts = opts or {}
  assert(vim.fn.has("nvim-0.11") == 1, "Syrox requires Neovim 0.11 or newer")
  vim.filetype.add({ extension = { srx = "syrox" } })
  vim.cmd("filetype plugin on")
  vim.cmd("syntax enable")
  local group = vim.api.nvim_create_augroup("SyroxVirtualSources", { clear = true })
  vim.api.nvim_create_autocmd("BufReadCmd", {
    group = group,
    pattern = "syrox-source://*",
    callback = virtual_source,
    desc = "Read revision-scoped Syrox standard-library sources",
  })
  local config = vim.tbl_deep_extend("force", {
    cmd = opts.cmd or { "srx", "lsp" },
    filetypes = { "syrox" },
    root_markers = { "Syrox.lock", "main.srx", ".git" },
    capabilities = {
      workspace = { workspaceEdit = { documentChanges = true } },
    },
  }, opts.lsp or {})
  local user_attach = config.on_attach
  local user_before_init = config.before_init
  config.before_init = function(params, resolved)
    if user_before_init then user_before_init(params, resolved) end
    if opts.standard_library_root
      and vim.fs.normalize(resolved.root_dir or "") == vim.fs.normalize(opts.standard_library_root) then
      params.initializationOptions = vim.tbl_deep_extend("force", params.initializationOptions or {}, {
        workspaceMode = "standard-library",
      })
    end
  end
  config.on_attach = function(client, buffer)
    attach(client, buffer, opts)
    if user_attach then user_attach(client, buffer) end
  end
  vim.lsp.config("syrox", config)
  vim.lsp.enable("syrox")
end

return M
