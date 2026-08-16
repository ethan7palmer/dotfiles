return {
    {
        'rose-pine/neovim',              -- GitHub repo (owner/name) lazy.nvim clones and manages
        lazy = false,                    -- load on startup, not deferred - a colorscheme has to be ready immediately
        priority = 1000,                 -- load before other plugins, so they don't render before colors exist
        name = 'rose-pine',              -- internal name lazy.nvim refers to this plugin by
        config = function()              -- runs once the plugin is loaded, to set it up
            require('rose-pine').setup({
                dark_variant = 'moon',                     -- use rose-pine's "moon" palette variant
                dim_inactive_windows = false,               -- don't dim inactive split windows
                extend_background_behind_borders = false,   -- don't paint the background color behind window border chars
                styles = {
                    italic = false,             -- no italics (e.g. for comments)
                    -- Darwin/Linux/string.find(...,'Windows') covers every OS this ever runs on,
                    -- so transparency is effectively always true here - it lets Kitty's own
                    -- background_opacity show through instead of nvim painting an opaque background.
                    transparency = vim.uv.os_uname().sysname == 'Darwin'
                        or vim.uv.os_uname().sysname == 'Linux'
                        or string.find(vim.uv.os_uname().sysname, 'Windows') ~= nil,
                },
            })

            vim.cmd('colorscheme rose-pine')   -- actually activate the colorscheme (setup() above only configures it)

            -- Make the dimmed directory path in the Snacks picker readable
            local palette = require('rose-pine.palette')     -- access rose-pine's raw color values
            vim.api.nvim_set_hl(0, 'SnacksPickerDir', { fg = palette.subtle })  -- override just this one highlight group

            -- gitsigns' default add/change/delete colors on rose-pine are foam (cyan)
            -- / rose (pink) / love (pink) - change and delete are both pinkish and hard
            -- to tell apart at a glance. Remap to the standard green/yellow/red diff
            -- convention instead, using colors that are actually distinct hues in this
            -- palette. GitSignsAddNr/ChangeNr/DeleteNr link to these by default, so the
            -- number-column variant picks the change up automatically.
            vim.api.nvim_set_hl(0, 'GitSignsAdd', { fg = palette.leaf })
            vim.api.nvim_set_hl(0, 'GitSignsChange', { fg = palette.gold })
            vim.api.nvim_set_hl(0, 'GitSignsDelete', { fg = palette.love })

            -- Staged hunks use the *same glyph* as unstaged ones (both "┃"), so
            -- color is the only signal telling them apart - gitsigns' default
            -- (mix 50% toward black) leaves the staged color barely legible
            -- against the background, so both ends up reading as one indistinct
            -- dark smudge instead of two colors. Darken by less (25%, chosen by
            -- checking the resulting contrast ratio against the background
            -- stays >= ~4:1) and add bold, so staged is readable as its own
            -- color *and* visually heavier - two signals instead of a subtle
            -- shade shift on one.
            local function staged(hex)
                local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
                local f = 0.25
                return string.format('#%02X%02X%02X', r * (1 - f), g * (1 - f), b * (1 - f))
            end
            vim.api.nvim_set_hl(0, 'GitSignsStagedAdd', { fg = staged(palette.leaf), bold = true })
            vim.api.nvim_set_hl(0, 'GitSignsStagedChange', { fg = staged(palette.gold), bold = true })
            vim.api.nvim_set_hl(0, 'GitSignsStagedDelete', { fg = staged(palette.love), bold = true })
        end,
    },
}
