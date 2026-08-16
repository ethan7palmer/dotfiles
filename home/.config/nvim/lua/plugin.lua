-- Where lazy.nvim itself lives: Neovim's data dir (e.g. ~/.local/share/nvim), then lazy/lazy.nvim.
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

-- fs_stat returns nil if the path doesn't exist yet - i.e. lazy.nvim isn't installed.
if not vim.uv.fs_stat(lazypath) then
    -- First run only: clone lazy.nvim from GitHub into lazypath.
    -- --filter=blob:none defers downloading file contents until needed, for a faster clone.
    -- --branch=stable pins to lazy.nvim's stable releases, not its main/dev branch.
    vim.fn.system({ 'git', 'clone', '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git', '--branch=stable', lazypath })
end

-- Add lazy.nvim's directory to Neovim's runtimepath so `require('lazy')` below can find it.
vim.opt.rtp:prepend(lazypath)

-- Hand off to lazy.nvim: load every file in lua/plugins/ as a plugin spec and
-- install/load whatever they declare.
require('lazy').setup('plugins')

-- Ubuntu's neovim apt package ships treesitter parsers (lua, c, vim, vimdoc,
-- markdown) to /usr/lib/nvim/parser but never adds that directory to the
-- runtimepath, so core ftplugins that auto-start treesitter for those
-- filetypes (e.g. ftplugin/lua.lua) error with "Parser could not be created".
-- Must run after lazy.nvim's setup above, not in vim_config.lua - lazy.nvim
-- rebuilds the runtimepath during its own setup and would wipe out an
-- earlier append.
vim.opt.rtp:append('/usr/lib/nvim')

