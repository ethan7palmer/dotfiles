-- Save when leaving insert mode (you press Esc to exit insert mode anyway,
-- so why not save at the same time?). This is an InsertLeave autocmd, not a
-- Normal-mode <Esc> keymap - a bare <Esc> mapping only fires on a *second*,
-- separate Escape press, since the one that actually leaves insert mode is
-- consumed by leaving insert mode itself. Confirmed by reproducing it: a
-- single continuous keystroke sequence ending in Esc left the buffer
-- modified with a Normal-mode mapping, every time - only splitting it into
-- two distinct keypresses (not how real typing works) made it fire.
-- buftype == '' skips special buffers (help, terminal, Oil, the picker
-- input, etc.) that either aren't real files or handle their own saving.
vim.api.nvim_create_autocmd('InsertLeave', {
    callback = function()
        if vim.bo.modified and vim.bo.buftype == '' and vim.fn.expand('%') ~= '' then
            vim.cmd('silent! write')
        end
    end,
    desc = 'Save on leaving insert mode',
})
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