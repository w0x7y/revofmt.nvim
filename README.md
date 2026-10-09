**This project is making heavily use of AI Agents, if you have a problem with that just don't use it. Thanks!**

# `revofmt.nvim`, revo formatting in neovim

open a `.rv` or `.revo` file, run `:RevoFormat`, get formatted code.
it works on your unsaved buffer. format-on-save is off until you ask for it.

[install](#install-with-lazynvim) | [commands](#commands) | [settings](#settings) | [formatter](https://github.com/w0x7y/revo-formatter)

## install with lazy.nvim

you need neovim >=0.10. the downloadable formatter is for linux x86_64 GNU,
with glibc >=2.34 and `libgcc_s`. other platforms need a separately verified
formatter build.

installation needs `curl` and `sha256sum`.

put this in your plugin specs:

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

sync your plugins, open a revo file, then try:

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

the install hook downloads the pinned formatter, checks its SHA-256, and keeps
it in neovim's data directory. no rust or zig needed.
it reuses a verified installation on later updates; a plugin update can select
a newer pinned formatter.

### other plugin managers

install `w0x7y/revofmt.nvim`, restart neovim, and run `:RevoFmtInstall` once.
wait for the installed notification, then `:RevoFormat`. `setup()` is optional.

or use native packages, with the default linux data directory:

```sh
git clone https://github.com/w0x7y/revofmt.nvim.git \
  ~/.local/share/nvim/site/pack/revofmt/start/revofmt.nvim
```

### coming from the local package?

replace the old `dir` spec or manual `runtimepath:prepend(...)` entry with the
spec above. load one copy. remove the `executable` override to use the downloaded
binary, and keep your layout and save preferences in `opts`.

## commands

| command | what it does |
| --- | --- |
| `:RevoFormat` | format the whole unsaved buffer asynchronously |
| `:RevoFmtInstall` | install the pinned formatter, or reuse verified bytes |
| `:RevoFmtInstall!` | download and verify it again |
| `:checkhealth revofmt` | show the executable and try a formatting smoke check |

`:RevoFmtInstall` is asynchronous. wait for it to finish before formatting.
a failed reinstall keeps the working formatter for the current pin. after a
plugin update selects a new pin, run the install command again if its download
fails; older managed versions are retained but are not selected automatically.
setup, formatting and health checks never download anything.

## settings

these are the defaults. with lazy.nvim, put your changes in `opts` in the spec above.
with another plugin manager, call `setup()`:

```lua
require('revofmt').setup({
  -- executable = '/absolute/path/to/revofmt', -- optional override
  indent_width = 2,       -- 1 to 8 spaces
  line_width = 80,        -- 20 to 240 columns; a soft target
  timeout_ms = 5000,
  format_on_save = false, -- set true to format before saving
})
```

if save formatting fails, your buffer stays unchanged and the save still happens.
turn off other whitespace-cleanup hooks for revo if they'd change multiline
literals or comments.

executable selection goes: explicit setting, downloaded binary, then `revofmt`
on PATH. set `executable = 'revofmt'` to always use PATH. use literal paths;
`~`, environment variables and shell commands aren't expanded.

for synchronous calls:

```lua
require('revofmt').format({ bufnr = 0, async = false })
require('revofmt').install({ async = false }) -- returns success, error
```

`:help revofmt` has the API and buffer requirements.

<details>
<summary>where the binary lives, and removing it</summary>

`stdpath('data')/revofmt/<formatter-version>/revofmt`.
remove that version directory to uninstall it. removing the plugin doesn't
remove the binary. explicitly configured binaries are never replaced.

</details>

## what it preserves

[revofmt](https://github.com/w0x7y/revo-formatter) checks syntax, token and comment
bytes, and that formatting twice gives the same result. the plugin keeps those
bytes through neovim's buffer representation. it supports nonbinary UTF-8 unix
and DOS buffers without a BOM.
NUL output or line endings the buffer can't represent exactly are rejected.

formatting has a five-second default deadline. canceled, failed, stale and
superseded requests don't apply edits. successful edits preserve window views
and replace one minimal line region. empty buffers stay untouched.

source and stdout are limited to 262,144 bytes, stderr to 65,536 bytes.
the CLI has additional input limits; see its
[input policy](https://github.com/w0x7y/revo-formatter/blob/main/docs/verification/input-limits.md).
use your existing language tooling for highlighting, completion and diagnostics.

## development

with a real formatter and python 3 installed:

```sh
REVOFMT_BIN=/absolute/path/to/revofmt scripts/verify
```

For a formatter rebuilt against Revo `e94e6d8` or later, add
`REVOFMT_CURRENT_SYNTAX=1` to verify range adjacency and invalid interpolation
mode rejection without buffer edits. These checks are opt-in because the
downloaded formatter pin still uses the earlier compiler.

tests run without your personal neovim configuration. they cover real formatting,
byte preservation, undo, deadlines, inherited pipes, stale results, save opt-in,
install failures, checksums, executable selection and health reporting.
[release notes and pinning](docs/releases.md) explain the downloaded binary.

## credits

[MIT](LICENSE). the adapter started in `revo-formatter/editors/neovim` at commit
`312cd365bd6b25382754ccae46193df3d57ddd40`.
the formatter uses [revo](https://github.com/if-not-nil/revo), also MIT;
its unchanged notice is in [licenses/REVO-LICENSE.txt](licenses/REVO-LICENSE.txt).
