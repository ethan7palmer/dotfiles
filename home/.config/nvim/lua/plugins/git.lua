return {
    {
        'NeogitOrg/neogit',   -- Magit-style git porcelain UI: stage, commit, branch, etc. from inside nvim
        -- plenary = shared utility lib neogit needs; diffview = the diff-view UI neogit opens internally
        dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
        -- lazy-load trigger: neogit isn't loaded at all until <leader>g is pressed the first time,
        -- at which point it's loaded and this function opens it in the same step
        keys = { { '<leader>g', function() require('neogit').open() end, desc = 'Neogit' } },
    },
    {
        'lewis6991/gitsigns.nvim',   -- add/change/delete markers in the sign column, next to line numbers
        event = 'BufWinEnter',       -- different lazy-load trigger: loads as soon as any buffer is shown in a window
        opts = { current_line_blame = true },  -- who last touched this line (opts is passed straight to gitsigns' setup())
    },
}

