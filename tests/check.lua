local function check()
  for _, file in ipairs(vim.fn.glob("**/*.lua", false, true)) do
    assert(loadfile(file), file)
  end
  vim.opt.runtimepath:append(vim.fn.getcwd())
  require("syrox").setup()
end

local ok, err = xpcall(check, debug.traceback)
if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit 1")
else
  vim.cmd("qa!")
end
