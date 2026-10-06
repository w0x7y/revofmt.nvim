# Standalone Neovim distribution

The approved goal is a public Neovim repository under `w0x7y/revofmt.nvim`, cloned at `/home/idan/GitRepo/revofmt.nvim`, with ordinary plugin-manager installation and no local compiler requirement.

## Design

Keep the existing whole-buffer adapter, codec and transport. Add a binary manager that downloads one pinned Linux x86_64 GNU release from `w0x7y/revo-formatter`, verifies its SHA-256 before making it executable, and atomically installs it under Neovim's data directory. Downloads happen only through the explicit install command or plugin-manager build hook. Explicit executable overrides take precedence; otherwise use the managed binary, then PATH. Missing binaries explain how to install.

Register `:RevoFmtInstall` and `:checkhealth revofmt`. Keep save formatting off by default, preserve opaque bytes and stale-result guards, and reuse transport for health smoke checks. Keep the embedded plugin in the formatter repository working; its guide points to the standalone distribution.

## Implementation plan

- [x] Create and clone the remote repository, retain MIT attribution, adapt the existing 32-test suite to the standalone root.
- [x] Add failing installation tests for checksum rejection, download errors, idempotence, unsupported platforms, executable selection, asynchronous completion and command registration.
- [x] Implement `lua/revofmt/release.lua`, `binary.lua`, `health.lua` and public install/resolve entry points without changing codec or transport.
- [x] Write quick-start README and help, record pinned binary provenance, add standalone CI and release verification instructions.
- [x] Verify the source formatter with pinned Zig, publish its binary plus checksum and license notices, then test a real download and unsaved-buffer formatting in an isolated Neovim data directory.
- [x] Commit and push the standalone repository; update and verify the current formatter guides.

## Verification

Run `REVOFMT_BIN=/absolute/path/to/revofmt nvim --headless -u NONE -i NONE -n -l tests/run.lua` and `tests/install.lua` from this repository. Installer tests replace only the network process with a controlled executable and keep filesystem publication, hashing and formatter execution real. Use a separate data directory so no personal editor settings or binaries change. Verify checksums, syntax preservation and idempotence through the real CLI before publishing the release.

## Verified outcome

The public repository and formatter release are live. All 32 adapter tests and
13 installation tests passed on Neovim 0.10.4 and 0.12.5, locally and in
[GitHub CI](https://github.com/w0x7y/revofmt.nvim/actions/runs/37486921926).
A fresh lazy.nvim install cloned the remote plugin, executed its documented
build hook, downloaded and verified the real release, recognized a `.rv` buffer
and formatted unsaved source. All checks used isolated editor data.

Minimum-version testing found two issues before release: Neovim 0.10's
`uv.walk` crashes on native editor handles, so tests now track the actual
transport allocations; its Vim `sha256()` rejects NUL-bearing Lua strings, so
installation hashes files through `sha256sum` with an argument array. The codec
and formatting transport remain byte-identical to the original adapter.

A separate code review approved the implementation after correcting a success
return tuple. The formatter's full Rust, Zig, checksum and editor verification
passed before its pinned binary was published.
