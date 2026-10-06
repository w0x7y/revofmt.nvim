# revofmt.nvim

Format Revo files in Neovim without building Rust or Zig. The plugin recognizes
`.rv` and `.revo`, formats the current unsaved buffer, and keeps format-on-save
opt-in.

Requires Neovim **0.10 or newer**. The downloadable formatter currently supports
**Linux x86_64 GNU with glibc 2.34 or newer** and normal system libraries,
including `libgcc_s`. Other platforms need a separately verified formatter build.

## Install with lazy.nvim

Add this plugin spec to your configuration:

```lua
{
  'w0x7y/revofmt.nvim',
  main = 'revofmt',
  lazy = false,
  opts = {},
  build = function()
    local ok, err = require('revofmt').install({ async = false })
    if not ok then error(err) end
  end,
}
```

Install or sync your plugins, open a `.rv` or `.revo` file, then run:

```vim
:RevoFormat
```

The build hook downloads the formatter, verifies its pinned SHA-256, and stores
it in Neovim's data directory. It requires `curl` and `sha256sum` during installation. You do not
need a formatter checkout, Rust, Zig, or an executable path in your settings.
A verified installation is reused on subsequent plugin updates. Updating the
plugin can select a newer pinned formatter release.

## Other plugin managers

Install `w0x7y/revofmt.nvim` with your plugin manager, then run `:RevoFmtInstall`
once. The plugin loads with working defaults; `setup()` is optional.

For Neovim's native packages:

```sh
git clone https://github.com/w0x7y/revofmt.nvim.git \
  ~/.local/share/nvim/site/pack/revofmt/start/revofmt.nvim
```

Restart Neovim, run `:RevoFmtInstall`, then `:RevoFormat`. The native package path
above assumes the default Linux data directory.

## Migrating from the local package

Replace the old local `dir` plugin spec with the repository spec above, or remove
the old manual `runtimepath:prepend(...)` entry. Load one copy of the plugin.
Remove the old `executable` override to use the managed binary; keep your layout
and save-formatting preferences in `opts`.

## Commands

| Command | Purpose |
| --- | --- |
| `:RevoFormat` | Format the whole unsaved buffer asynchronously |
| `:RevoFmtInstall` | Install the pinned formatter, or reuse verified installed bytes |
| `:RevoFmtInstall!` | Download and verify the formatter again |
| `:checkhealth revofmt` | Show the executable and run a formatting smoke check |

Installation is asynchronous from the command line. Wait for the installed
notification before formatting. Failed downloads leave an existing working
formatter intact. Setup, formatting and health checks never download anything.

## Configuration

```lua
require('revofmt').setup({
  -- executable = '/absolute/path/to/revofmt', -- optional override
  indent_width = 2,       -- 1 through 8 spaces
  line_width = 80,        -- 20 through 240 columns; a soft target
  timeout_ms = 5000,
  format_on_save = false,
})
```

With lazy.nvim, put these values in `opts`. Set `format_on_save = true` to opt
into formatting Revo buffers before saving. A formatting failure keeps the
buffer unchanged and allows the user's source to be saved.

Executable selection uses the explicit override first, then the managed binary,
then `revofmt` on PATH. To always use PATH, set `executable = 'revofmt'`.
Executable paths are passed directly, without a shell; use an absolute path
rather than `~` or environment-variable substitutions.

The Lua API also supports synchronous formatting and installation:

```lua
require('revofmt').format({ bufnr = 0, async = false })
require('revofmt').install({ async = false }) -- returns success, error
```

The managed executable lives at
`stdpath('data')/revofmt/<formatter-version>/revofmt`. Remove that version directory
to uninstall it. Removing the plugin through your plugin manager does not remove
the downloaded formatter. Explicitly configured binaries are never replaced.

## Preservation and failures

The [formatter](https://github.com/w0x7y/revo-formatter) validates syntax, exact
interleaved token/comment bytes and idempotence. The plugin preserves that output
through the Neovim buffer representation. It supports nonbinary UTF-8 Unix and
DOS buffers without a BOM. Output containing NUL bytes or line endings that the
current buffer cannot represent exactly is rejected.

Formatting has a five-second default deadline. Cancellation, process failure,
excessive output, buffer changes and superseded requests cannot apply a result.
The plugin preserves window views and applies one minimal line region. Empty
buffers stay untouched. Source and stdout are limited to 262,144 bytes; stderr
to 65,536 bytes. The CLI also checks token and recursive-form admission limits.
See the [input policy](https://github.com/w0x7y/revo-formatter/blob/main/docs/verification/input-limits.md).

Disable unrelated whitespace-cleanup save hooks for Revo when they would change
opaque multiline literals or comments. Syntax highlighting, completion and
language diagnostics belong to your existing language tooling.

## Development

The adapter originated in `revo-formatter/editors/neovim` at commit
`312cd365bd6b25382754ccae46193df3d57ddd40`. It retains its MIT license.
The bundled release selection and upstream notices are documented in
[docs/releases.md](docs/releases.md).

With a real formatter and Python 3 installed, run:

```sh
REVOFMT_BIN=/absolute/path/to/revofmt scripts/verify
```

Tests load no personal Neovim configuration. They cover real CLI formatting,
byte preservation, undo, deadlines, inherited pipes, stale results, save opt-in,
installation failures, checksums, executable selection and health reporting.
