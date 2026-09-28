-- SRX_BIN=/path/to/srx SRX_STD_DIR=/path/to/syrox/std nvim --headless -u NONE -l tests/std.lua
local runtime = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local root = vim.env.SRX_STD_DIR
local function run()
  assert(root and vim.fn.isdirectory(root) == 1, "set SRX_STD_DIR to the Syrox std source directory")
  root = vim.fn.fnamemodify(root, ":p"):gsub("/$", "")
  vim.opt.runtimepath:prepend(runtime)
  if vim.env.SYROX_NVIM_USER_CONFIG ~= "1" then
    require("syrox").setup({ cmd = { vim.env.SRX_BIN or "srx", "lsp" }, standard_library_root = root })
  end
  local publications = {}
  local handler = vim.lsp.handlers["textDocument/publishDiagnostics"]
  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    publications[result.uri] = (publications[result.uri] or 0) + 1
    return handler(err, result, ctx, config)
  end
  vim.cmd.edit(vim.fn.fnameescape(root .. "/main.srx"))
  local buffer = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(buffer)
  assert(vim.wait(10000, function() return (publications[uri] or 0) >= 2 end, 10), "std analysis completed")
  assert(#vim.diagnostic.get(buffer) == 0, vim.inspect(vim.diagnostic.get(buffer)))
  local client = assert(vim.lsp.get_clients({ name = "syrox", bufnr = buffer })[1])
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
  local position
  for index, line in ipairs(lines) do
    local col = line:find("PackageId", 1, true)
    if col then position = { line = index - 1, character = col - 1 }; break end
  end
  local response = client:request_sync("textDocument/definition", { textDocument = { uri = uri }, position = position }, 2000, buffer)
  assert(response and response.result and response.result.uri == vim.uri_from_fname(root .. "/package.srx"), vim.inspect(response))
  vim.cmd.edit(vim.fn.fnameescape(root .. "/collections/map.srx"))
  local sibling = vim.api.nvim_get_current_buf()
  local sibling_uri = vim.uri_from_bufnr(sibling)
  assert(vim.wait(10000, function() return (publications[sibling_uri] or 0) >= 2 end, 10), "sibling analysis completed")
  assert(#vim.diagnostic.get(sibling) == 0, vim.inspect(vim.diagnostic.get(sibling)))
  vim.cmd.edit(vim.fn.fnameescape(root .. "/catalog.srx"))
  local catalog = vim.api.nvim_get_current_buf()
  local catalog_uri = vim.uri_from_bufnr(catalog)
  assert(vim.wait(10000, function() return (publications[catalog_uri] or 0) >= 2 end, 10), "catalog analysis completed")
  local row, line
  for index, candidate in ipairs(vim.api.nvim_buf_get_lines(catalog, 0, -1, false)) do
    if candidate:find("map_from_entries(", 1, true) then
      row, line = index - 1, candidate:gsub("map_from_entries", "map_from_en")
      break
    end
  end
  assert(row, "catalog calls map_from_entries")
  vim.api.nvim_buf_set_lines(catalog, row, row + 1, false, { line })
  local start = assert(line:find("map_from_en", 1, true))
  local completion = client:request_sync("textDocument/completion", {
    textDocument = { uri = catalog_uri }, position = { line = row, character = start - 1 + #"map_from_en" },
  }, 5000, catalog)
  local entry
  for _, item in ipairs(completion and completion.result and completion.result.items or {}) do
    if item.label == "map_from_entries" then entry = item end
  end
  assert(entry and entry.kind == 3, "map_from_entries must complete as Function immediately after editing")
  print("Syrox std authoring: imports, physical definitions, siblings and typed completion passed")
end
local ok, err = xpcall(run, debug.traceback)
for _, client in ipairs(vim.lsp.get_clients({ name = "syrox" })) do client:stop(true) end
if not ok then vim.api.nvim_err_writeln(err); vim.cmd("cquit 1") else vim.cmd("qa!") end
