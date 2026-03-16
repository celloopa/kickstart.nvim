local function clear_registers()
  local registers = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/-"'
  for register in registers:gmatch '.' do
    vim.fn.setreg(register, {})
  end
  print 'Registers Cleared'
end

vim.keymap.set('n', '<leader>re', clear_registers, { noremap = true, silent = true, desc = '[R]egisters [E]mpty' })

vim.keymap.set('n', '<leader>ee', 'oif err != nil {<CR>}<Esc>Oreturn err<Esc>', {
  noremap = true,
  desc = 'Go [E][E]rrors',
})

vim.keymap.set('n', '<leader>x', '<cmd>bdelete<CR>', {
  noremap = true,
  silent = true,
  desc = 'Close current buffer',
})

vim.keymap.set('n', 'SS', '<cmd>write<CR>', {
  noremap = true,
  silent = true,
  desc = 'Save buffer',
})

vim.keymap.set('n', '<leader>l', 'ggVG', {
  noremap = true,
  desc = 'Select whole buffer',
})

vim.keymap.set('n', '<leader>m', '<cmd>write<CR><cmd>quit<CR>', {
  noremap = true,
  silent = true,
  desc = 'Save and quit',
})

vim.keymap.set('n', '<leader>j', '<cmd>quit!<CR>', {
  noremap = true,
  silent = true,
  desc = 'Quit without saving',
})

vim.keymap.set('n', 'J', '<C-d>', {
  noremap = true,
  desc = 'Half-page down',
})

vim.keymap.set('n', 'K', '<C-u>', {
  noremap = true,
  desc = 'Half-page up',
})

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {
  desc = 'Previous diagnostic',
})

vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {
  desc = 'Next diagnostic',
})

vim.keymap.set('n', '<leader>ed', vim.diagnostic.open_float, {
  desc = 'Show diagnostic float',
})

vim.keymap.set('n', '<leader>ef', vim.diagnostic.setloclist, {
  desc = 'Open diagnostic quickfix list',
})
