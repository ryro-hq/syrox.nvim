local runtime = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local binary = vim.env.SRX_BIN or "srx"
local root = vim.fn.tempname()
local text = 'fn example() -> std::PackageId { std::PackageId("hello") }'

local function check(condition, message)
  assert(condition, message)
end

local function run()
  check(vim.fn.executable(binary) == 1, "build srx or set SRX_BIN")
  vim.fn.mkdir(root, "p")
  vim.fn.writefile({ text }, root .. "/main.srx")
  vim.opt.runtimepath:prepend(runtime)
  if vim.env.SYROX_NVIM_USER_CONFIG ~= "1" then
    require("syrox").setup({ cmd = { binary, "lsp" } })
  end
  vim.cmd.edit(vim.fn.fnameescape(root .. "/main.srx"))
  local buffer = vim.api.nvim_get_current_buf()
  check(vim.bo.filetype == "syrox", ".srx filetype detection")
  check(vim.bo.syntax == "syrox", "syntax enabled")
  check(vim.bo.commentstring == "// %s", "commentstring")
  check(vim.fn.synIDattr(vim.fn.synID(1, 1, 1), "name") == "syroxFn", "keyword highlighting")
  local type_column = text:find("PackageId", 1, true)
  check(vim.fn.synIDattr(vim.fn.synID(1, type_column, 1), "name") == "syroxType", "type highlighting")
  local client
  check(vim.wait(10000, function()
    client = vim.lsp.get_clients({ bufnr = buffer, name = "syrox" })[1]
    return client and client.initialized
  end, 10), "LSP attachment")
  check(client.server_capabilities.codeActionProvider.resolveProvider, "versioned code actions negotiated")
  check(vim.fn.maparg("gd", "n") ~= "", "definition mapping")
  local uri = vim.uri_from_bufnr(buffer)
  local definition
  check(vim.wait(10000, function()
    local response = client:request_sync("textDocument/definition", {
      textDocument = { uri = uri }, position = { line = 0, character = type_column - 1 },
    }, 1000, buffer)
    definition = response and response.result
    return type(definition) == "table" and definition.uri ~= nil
  end, 20), "semantic definition")
  check(definition.uri:match("^syrox%-source:"), "std virtual URI")
  local completion = client:request_sync("textDocument/completion", {
    textDocument = { uri = uri }, position = { line = 0, character = type_column + 2 },
  }, 2000, buffer)
  local found = false
  for _, item in ipairs(completion and completion.result and completion.result.items or {}) do
    found = found or item.label == "PackageId"
  end
  check(found, "LSP completion candidates")
  check(vim.lsp.util.show_document(definition, client.offset_encoding, { focus = true }), "definition jump")
  local virtual = vim.api.nvim_get_current_buf()
  check(virtual ~= buffer and vim.bo.buftype == "nofile", "virtual source buffer")
  check(vim.bo.readonly and not vim.bo.modifiable, "virtual source read-only")
  check(vim.bo.filetype == "syrox", "virtual source filetype")
  check(table.concat(vim.api.nvim_buf_get_lines(virtual, 0, -1, false), "\n"):find("PackageId", 1, true), "std source contents")
  vim.api.nvim_set_current_buf(buffer)
  local broken = 'outputs { item: std::PackageId = std::PackageId("hello") }'
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { broken })
  check(vim.wait(10000, function() return #vim.diagnostic.get(buffer) > 0 end, 10), "live diagnostics")
  local column = broken:find("}", 1, true) - 1
  local actions = client:request_sync("textDocument/codeAction", {
    textDocument = { uri = uri },
    range = { start = { line = 0, character = column }, ["end"] = { line = 0, character = column } },
    context = { diagnostics = {}, only = { "quickfix" } },
  }, 2000, buffer)
  check(actions and actions.result and #actions.result == 1, "quick fix available")
  vim.lsp.util.apply_workspace_edit(actions.result[1].edit, client.offset_encoding)
  check(vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1]:find(";}", 1, true), "versioned quick fix applied")
  check(vim.wait(10000, function() return #vim.diagnostic.get(buffer) == 0 end, 10), "diagnostics clear after fix")
  print("Syrox Neovim smoke: filetype, colors, completion, LSP, virtual std, diagnostics and quick fix passed")
end

local ok, err = xpcall(run, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients({ name = "syrox" })) do client:stop(true) end
vim.fn.delete(root, "rf")
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
