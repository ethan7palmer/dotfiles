-- vim.opt is Neovim's Lua interface for editor options (the Lua equivalent of Vimscript's :set).
local o = vim.opt            -- shorthand alias, so options below read as o.xxx instead of vim.opt.xxx
-- The leader key is a prefix reserved for custom mappings, so plugins can bind
-- <leader>x without colliding with Vim's built-in keys. Space here means every
-- <leader>-prefixed binding below is triggered as Space then the next key -
-- e.g. Space e opens Oil (navigation.lua), Space f/s/b open Snacks pickers for
-- files/grep/buffers (navigation.lua), and Space g opens Neogit (git.lua).
-- which-key.nvim (ui.lua) shows a popup of these options after you press Space.
vim.g.mapleader = ' '          -- space is the leader key
o.expandtab = true             -- spaces, not tabs
o.shiftwidth = 4               -- 4 spaces per indent level
o.number = true                -- show the line number in the gutter
o.ignorecase = true            -- search is case-insensitive by default
o.smartcase = true             -- case-sensitive only if i type a capital
o.clipboard = 'unnamedplus'    -- share the system clipboard
o.scrolloff = 16               -- keep cursor away from the screen edge
o.undofile = true              -- persistent undo across sessions
o.mouse = ''                   -- no mouse in nvim; also lets Herdr keep host mouse capture off so Escape isn't swallowed

