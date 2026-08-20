return {
    {
        'folke/which-key.nvim',   -- popup that shows what my leader keys do
        lazy = false,             -- load on startup, not deferred - needs to be active to catch any prefix keypress right away
        -- By default which-key also triggers on a bare ModeChanged into
        -- Visual/Operator-pending mode (see its README's "Triggers"
        -- section) - i.e. just pressing V pops up a help menu, not
        -- something tied to any specific keymap. Scoping triggers to
        -- <leader> only keeps the popup for actual leader sequences and
        -- drops that mode-entry popup entirely.
        opts = {
            triggers = {
                { '<leader>', mode = { 'n', 'v' } },
            },
        },
    },
}

