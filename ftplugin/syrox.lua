if vim.b.did_syrox_ftplugin then
  return
end
vim.b.did_syrox_ftplugin = true
vim.bo.commentstring = "// %s"
vim.bo.comments = "://"
vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.b.undo_ftplugin = (vim.b.undo_ftplugin and vim.b.undo_ftplugin .. " | " or "")
  .. "setlocal commentstring< comments< expandtab< shiftwidth< softtabstop< | unlet! b:did_syrox_ftplugin"
