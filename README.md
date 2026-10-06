**This project is making heavily use of AI Agents, if you have a problem with that just don't use it. Thanks!**

# `revofmt.nvim`, revo formatting in neovim

[revo](https://github.com/if-not-nil/revo)
| [formatter](https://github.com/w0x7y/revo-formatter)
| [install](#install)
| [options](#options)
| [commands](#commands)
| [credits](#credits)

revo formatting in neovim. open a `.rv` or `.revo` file, run `:RevoFormat`.
it formats what you've typed, even if you haven't saved yet.
format-on-save is off until you ask for it.

## install

you need neovim 0.10 or newer, and `curl` + `sha256sum` to install the formatter.
the download is currently for linux x86_64 GNU with glibc 2.34 or newer and
normal system libraries, including `libgcc_s`. other platforms need a separately
verified formatter build.

with lazy.nvim, put this in your plugins:

```lua
{
  'w0x7y/revofmt.nvim',
  main = 'revofmt',
  lazy = false,
  opts = {
    indent_width = 2, -- 1 through 8 spaces
    line_width = 80,  -- 20 through 240 columns; a soft target
  },
  build = function()
    local ok, err = require('revofmt').install({ async = false })
    if not ok then error(err) end
  end,
}
```

those are the default widths. change them to whatever you prefer within the ranges.
the build hook downloads the formatter and checks its pinned SHA-256.
you don't need rust, zig, or a formatter checkout.

install or sync your plugins, open a revo file, then:

```vim
:RevoFormat
```

<details>
<summary>other plugin managers</summary>

install `w0x7y/revofmt.nvim`, restart neovim, and run `:RevoFmtInstall` once.
wait for the installed notification, then run `:RevoFormat`.
`setup()` is optional, the defaults work without it.

for neovim's native packages, with the default linux data directory:

```sh
git clone https://github.com/w0x7y/revofmt.nvim.git \
  ~/.local/share/nvim/site/pack/revofmt/start/revofmt.nvim
```

</details>

<details>
<summary>moving from the old local package</summary>

replace your old `dir` spec with the one above, or remove the manual
`runtimepath:prepend(...)` entry. load one copy of the plugin.
remove the old `executable` override to use the downloaded formatter.
keep your width and save-formatting options in `opts`.

</details>

## options

these are the defaults. with lazy.nvim, put your changes in `opts`.
with another plugin manager, call `setup()`:

```lua
require('revofmt').setup({
  indent_width = 2,       -- 1 through 8 spaces
  line_width = 80,        -- 20 through 240 columns; a soft target
  timeout_ms = 5000,
  format_on_save = false, -- set true to format before saving
  -- executable = '/absolute/path/to/revofmt',
})
```

want it to format when you save? set `format_on_save = true`.
if formatting fails, your buffer stays as it was and the save still goes through.

<details>
<summary>using your own formatter</summary>

the plugin uses your `executable` override if set. otherwise it tries the
downloaded binary, then `revofmt` on PATH.
set `executable = 'revofmt'` to always use PATH.

paths go straight to the process, without a shell. use an absolute path,
not `~` or environment-variable substitutions.
the installer never replaces a binary you configured yourself.

</details>

## commands

| command | what it does |
| --- | --- |
| `:RevoFormat` | format the whole unsaved buffer asynchronously |
| `:RevoFmtInstall` | install the pinned formatter, or reuse a verified install |
| `:RevoFmtInstall!` | download and verify it again |
| `:checkhealth revofmt` | show the executable and try formatting a small example |

`:RevoFmtInstall` is asynchronous too. wait for the installed notification before
formatting. a failed download leaves an existing working formatter alone.
setup, formatting, and health checks never download anything.

from lua, if you need to wait for the result:

```lua
require('revofmt').format({ bufnr = 0, async = false })
require('revofmt').install({ async = false })
-- both return success, error
```

`:help revofmt` has the API and buffer requirements.

<details>
<summary>where the download goes</summary>

`stdpath('data')/revofmt/<formatter-version>/revofmt`

a verified install is reused on plugin updates. a newer plugin version can select
a newer pinned formatter release.

remove that version directory to uninstall the formatter.
removing the plugin through your plugin manager leaves the download there.

</details>

## what happens to your source

the [formatter](https://github.com/w0x7y/revo-formatter) checks syntax, preserves
the exact token and comment bytes in their original order, and checks that
formatting twice gives the same result. the plugin keeps your window views and
changes one minimal region, so you can undo the edit.

if you type while it's formatting, the old result gets discarded.
empty buffers stay untouched.

keep unrelated whitespace-cleanup save hooks disabled for revo if they could
change multiline literals or comments. use your existing language tools for
highlighting, completion, and diagnostics.

<details>
<summary>buffer support and limits</summary>

nonbinary UTF-8 unix and DOS buffers without a BOM are supported.
output with NUL bytes or line endings your buffer can't represent exactly is
rejected.

formatting has a five-second default deadline. cancellation, process failure,
excessive output, changed buffers, and superseded requests can't apply a result.
changes to buffer options also discard the result.

source and stdout are limited to 262,144 bytes, stderr to 65,536 bytes.
the CLI also limits tokens and recursive forms.
see the [input policy](https://github.com/w0x7y/revo-formatter/blob/main/docs/verification/input-limits.md).

</details>

## developing

with a real formatter, neovim, and python 3 installed:

```sh
REVOFMT_BIN=/absolute/path/to/revofmt scripts/verify
```

the tests don't load your neovim config. they cover real CLI formatting, byte
preservation, undo, deadlines, inherited pipes, stale results, save opt-in,
installation failures, checksums, executable selection, and health reporting.

## credits

licensed as [MIT](LICENSE).

the adapter came from `revo-formatter/editors/neovim` at commit
`312cd365bd6b25382754ccae46193df3d57ddd40`.
see [release notes and upstream notices](docs/releases.md) for the bundled
formatter.

the formatter uses [revo](https://github.com/if-not-nil/revo), also MIT.
its unchanged notice is in [licenses/REVO-LICENSE.txt](licenses/REVO-LICENSE.txt).
