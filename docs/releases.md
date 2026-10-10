# Formatter releases

The plugin downloads `revofmt` from the public
[`w0x7y/revo-formatter` releases](https://github.com/w0x7y/revo-formatter/releases).
It never builds or downloads the Zig toolchain. Downloads happen only through
`:RevoFmtInstall` or an explicit plugin-manager install hook.

## Current pin

- Formatter version: `0.2.0`
- Release tag: `v0.2.0`
- Source commit: `9912c6902e14603089397533e6ace8126faceb5d`
- Asset: `revofmt-linux-x86_64-gnu`
- SHA-256: `497b274d0e26f479f1af64177b26b9ca261fb1e07d347cdd0596c79c22264349`
- Syntax revision: Revo `f0034ab75aaf49d65bc1b4769987f99380383fcb`
- Build compiler: exact Zig `0.17.0`, native Rust release build
- Binary platform: Linux x86_64 GNU, glibc >=2.34, `libgcc_s`

The formatter statically includes the Revo frontend. The formatter and plugin
are MIT licensed; Revo's unchanged MIT notice is included in
[licenses/REVO-LICENSE.txt](../licenses/REVO-LICENSE.txt). Formatter releases carry
`LICENSE`, `REVO-LICENSE.txt`, `THIRD_PARTY.md` and `SHA256SUMS` alongside the binary.

## Updating the pin

1. Build the intended formatter commit using the exact pinned toolchain and
   run all verification commands from its README, including debug/release
   admission tests, corpus checks, Zig tests and editor checks.
2. Publish a new versioned release with the binary, SHA-256 manifest, source
   provenance and complete license notices. Do not overwrite an existing pin's
   binary with different bytes.
3. Update `lua/revofmt/release.lua` with the version, URL, checksum and source
   commit, and update this guide.
4. Run `scripts/verify` against the new binary, then test a real install into an
   isolated Neovim data directory with no existing formatter on PATH. Confirm
   formatting an unsaved buffer and formatting it twice preserve exact output.
5. Release the plugin update. Keep explicit executable overrides working.

A new platform requires native build, linking, syntax and resource verification
before adding a downloadable asset or claiming support. Plugin CI exercises the
pinned GNU binary on Ubuntu; support is not inferred merely from the operating
system name.
