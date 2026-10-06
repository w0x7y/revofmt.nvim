**This project is making heavily use of AI Agents, if you have a problem with that just don't use it. Thanks!**

# `revofmt.nvim`, revo formatting in neovim

open a `.rv` or `.revo` file and run `:RevoFormat`.
it formats your unsaved buffer. format-on-save is off by default.

## install

you need neovim >=0.10. the downloadable formatter supports linux x86_64 GNU
with glibc >=2.34 and `libgcc_s`. other platforms need their own verified build.
installation needs `curl` and `sha256sum`.

with lazy.nvim:

```lua
{
  'w0x7y/revofmt.nvim',
  main = 'revofmt',
  lazy = false,
  opts = {
    indent_width = 2, -- 1 to 8 spaces
    line_width = 80,  -- 20 to 240 columns; a soft target
  },
  build = function()
    local ok, err = require('revofmt').install({ async = false })
    if not ok then error(err) end
  end,
}
```

the build hook downloads and verifies the formatter. no rust or zig needed.
sync your plugins, open a revo file, then run:

```vim
:RevoFormat
```

before:

```text
let x=1
```

after:

```text
let x = 1
```

with another plugin manager, install `w0x7y/revofmt.nvim` and run `:RevoFmtInstall`
once. wait for the installed notification before formatting.

## settings

with lazy.nvim, change `opts` in the spec above.
set `format_on_save = true` if you want formatting before each save.

with another plugin manager, call `setup()`. these are the defaults:

```lua
require('revofmt').setup({
  indent_width = 2,
  line_width = 80,
  timeout_ms = 5000,
  format_on_save = false,
})
```

to use your own formatter, set `executable = '/absolute/path/to/revofmt'`.
set `executable = 'revofmt'` to use PATH. `~` and environment variables aren't expanded.

## commands

| command | what it does |
| --- | --- |
| `:RevoFormat` | format the current buffer asynchronously |
| `:RevoFmtInstall` | install the formatter, or reuse a verified install |
| `:RevoFmtInstall!` | download and verify it again |
| `:checkhealth revofmt` | check the executable and try formatting |

## your source

the formatter preserves token and comment bytes, and checks that formatting twice
gives the same result. the plugin preserves window views and lets you undo the edit.
if formatting fails or you edit the buffer while it runs, the result isn't applied.
a failed format-on-save still saves your source.

turn off other whitespace-cleanup hooks for revo if they could change multiline
literals or comments.

for the API, buffer requirements, and uninstall instructions, see `:help revofmt`
or the [help file](doc/revofmt.txt).
see [formatter releases](docs/releases.md) for downloads and platform support.

## development

with a real formatter and python 3 installed:

```sh
REVOFMT_BIN=/absolute/path/to/revofmt scripts/verify
```

## credits

[MIT](LICENSE). uses [revo-formatter](https://github.com/w0x7y/revo-formatter)
and [revo](https://github.com/if-not-nil/revo).
revo's MIT notice is in [licenses/REVO-LICENSE.txt](licenses/REVO-LICENSE.txt).
