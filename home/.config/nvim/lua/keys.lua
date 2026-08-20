-- select all (Ctrl + a)
vim.keymap.set('n', '<C-a>', 'ggVG', { desc = 'Select All' })
-- pasting over a selection no longer clobbers your clipboard
-- this is a workaround for when selecting some text, yanking it, and then selecting some other text and pasting over it, which would normally replace your clipboard with the text you just replaced. This mapping allows you to paste over a selection without losing your original yanked text.
vim.cmd([[ xnoremap <expr> p 'pgv"'.v:register.'y' ]])

-- vim.keymap.set(mode, lhs, rhs, opts)
-- mode: 'n' (normal)
-- lhs: key combination to trigger the mapping
-- rhs: command to execute when the mapping is triggered
-- opts: optional table of options, e.g. { desc = 'description' } for the mapping