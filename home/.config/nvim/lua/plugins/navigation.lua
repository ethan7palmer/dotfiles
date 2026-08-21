return {
    {
        'stevearc/oil.nvim',   -- edit the filesystem like a normal buffer: rename/create/delete files as text edits
        opts = { view_options = { show_hidden = true } },   -- show dotfiles in the file browser
        -- no lazy=false above, so this `keys` entry is the lazy-load trigger itself:
        -- oil.nvim only loads the first time <leader>e is pressed.
        keys = { { '<leader>e', '<cmd>Oil<cr>', desc = 'File Browser' } },
    },
    {
        'folke/snacks.nvim',   -- grab-bag of small QoL utilities: fuzzy picker, notifications, input UI, etc.
        priority = 1000,       -- load before most other plugins
        lazy = false,          -- load on startup rather than deferring - notifier/input need to hook in immediately
        opts = {
            picker = {
                enabled = true,    -- fuzzy finder used by the keymaps below
                -- files/grep default to hidden=false (dotfiles excluded); override per-source
                -- so it sticks rather than a top-level `hidden` the source defaults could clobber.
                -- Toggle at runtime with Alt-h regardless; this just changes the starting state.
                sources = {
                    files = { hidden = true },
                    grep = { hidden = true },
                },
            },
            notifier = { enabled = true },  -- nicer popup notifications, replaces vim.notify
            input = { enabled = true },     -- nicer popup for vim.ui.input prompts
        },
        -- Since lazy=false already loads snacks.nvim on startup, these `keys` entries
        -- are just keymaps calling into its API - not a lazy-load trigger like oil.nvim's above.
        keys = {
            { '<leader>f', function() Snacks.picker.files() end, desc = 'Find Files' },         -- fuzzy-find files by name
            { '<leader>s', function() Snacks.picker.grep() end,  desc = 'Search Text' },         -- live grep across the project
            { '<leader>b', function() Snacks.picker.buffers() end, desc = 'Buffers' },           -- switch between open buffers
            { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },  -- jump to a symbol's definition via LSP
            {
                '<leader>?',
                function()
                    -- A hand-picked subset of built-in Vim/Neovim commands, not the full
                    -- `:help quickref` reference (comprehensive, but a lot to wade through).
                    -- Add to this list as more commands turn out worth remembering.
                    -- Mode tags show what mode a command is pressed from. Ex commands are
                    -- typed after ":" (from Normal mode); "Normal -> X" means it's pressed
                    -- in Normal mode but switches you into mode X.
                    local cheatsheet = {
                        { text = '── Ex commands (type : first) ──' },
                        { text = ':wq              save and quit                                          [Ex]' },
                        { text = ':q                quit                                                    [Ex]' },
                        { text = ':q!               quit without saving                                     [Ex]' },
                        { text = ':%s/old/new/gc    replace all occurrences of old with new, confirm each  [Ex]' },
                        { text = ':{N}              jump to line N, e.g. :1 for line 1                      [Ex]' },
                        { text = ':undolist         list undo history states (jump to one with :u {N})      [Ex]' },
                        { text = ':pwd              print the current directory                             [Ex]' },
                        { text = ':cd /path/to      change the current directory                            [Ex]' },
                        { text = ':Ex               open netrw (built-in file explorer) here                [Ex]' },
                        { text = ':Rex              return to the last netrw window                         [Ex]' },
                        { text = '── Search ──' },
                        { text = '/pattern          search forward in the file                          [Normal]' },
                        { text = '?pattern          search backward in the file                         [Normal]' },
                        { text = 'n                 repeat last search, same direction                 [Normal]' },
                        { text = 'N                 repeat last search, opposite direction              [Normal]' },
                        { text = '── Movement ──' },
                        { text = 'gg / G            jump to top / bottom of file                        [Normal]' },
                        { text = '0 / $             jump to start / end of the current line             [Normal]' },
                        { text = 'zz                center the screen on the cursor line                [Normal]' },
                        { text = 'Ctrl-o            jump back to previous location                      [Normal]' },
                        { text = '── Mode switches ──' },
                        { text = 'i                 insert mode                              [Normal -> Insert]' },
                        { text = 'v                 visual mode (select text)                [Normal -> Visual]' },
                        { text = '── Editing ──' },
                        { text = 'dd                delete (cut) the current line                       [Normal]' },
                        { text = 'y                 yank (copy)                                         [Normal]' },
                        { text = 'p                 paste                                                [Normal]' },
                        { text = 'u / Ctrl-r        undo / redo                                          [Normal]' },
                        { text = 'Ctrl-a            select all (remapped; vanilla default is increment)  [Normal]' },
                    }
                    Snacks.picker({
                        items = cheatsheet,
                        format = 'text',
                        title = 'Cheat Sheet',
                        layout = { preset = 'select' },
                        confirm = function(picker) picker:close() end,
                    })
                end,
                desc = 'Cheat Sheet',
            },
        },
    },
}

