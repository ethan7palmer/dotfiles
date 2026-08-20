return {
    {
        'jake-stewart/multicursor.nvim',   -- VSCode-style multiple cursors
        branch = '1.0',
        lazy = false,   -- needs to be active on startup to catch the keymaps below immediately, not deferred behind a trigger
        config = function()
            local mc = require('multicursor-nvim')
            mc.setup()

            -- Add a cursor directly above/below the current one, VSCode-
            -- style. Bound to Ctrl+Alt+Up/Down specifically, not the
            -- plugin's own suggested plain Up/Down - those would silently
            -- change what normal arrow-key navigation does everywhere.
            vim.keymap.set({ 'n', 'x' }, '<C-A-Down>', function() mc.lineAddCursor(1) end, { desc = 'Add Cursor Below' })
            vim.keymap.set({ 'n', 'x' }, '<C-A-Up>', function() mc.lineAddCursor(-1) end, { desc = 'Add Cursor Above' })

            -- Esc collapses every extra cursor back down to one.
            -- addKeymapLayer only applies this mapping while more than one
            -- cursor exists, so a plain Esc still does whatever it
            -- normally does the rest of the time.
            mc.addKeymapLayer(function(layerSet)
                layerSet('n', '<esc>', mc.clearCursors)
            end)
        end,
    },
}
