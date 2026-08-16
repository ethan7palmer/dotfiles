return {
    {
        'folke/which-key.nvim',   -- popup that shows what my leader keys do
        lazy = false,             -- load on startup, not deferred - needs to be active to catch any prefix keypress right away
        config = true,            -- shorthand for require('which-key').setup({}) - defaults, no custom options needed
    },
}

