local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)
local real = assert(vim.env.REVOFMT_BIN, 'set REVOFMT_BIN to a real formatter')
local original_path, original_uname = vim.env.PATH, vim.uv.os_uname
local sandbox = vim.fn.tempname() .. ' installation; direct'
vim.fn.mkdir(sandbox .. '/tools', 'p')
assert(vim.uv.fs_symlink(root .. '/tests/downloader.py', sandbox .. '/tools/curl'))
-- Missing-formatter tests must not discover the user's installed revofmt.
for _, tool in ipairs({ 'python3', 'sha256sum' }) do
  local executable = vim.fn.exepath(tool)
  assert(executable ~= '', 'installation tests require ' .. tool)
  assert(vim.uv.fs_symlink(executable, sandbox .. '/tools/' .. tool))
end
vim.env.PATH = sandbox .. '/tools'
vim.notify = function() end
local count, failed = 0, 0
local function equal(a, b) assert(vim.deep_equal(a, b), vim.inspect(a) .. ' ~= ' .. vim.inspect(b)) end
local function test(name, body)
  count = count + 1
  vim.env.XDG_DATA_HOME = sandbox .. '/case-' .. count
  vim.env.REVOFMT_DOWNLOAD_LOG = sandbox .. '/download-' .. count
  vim.env.REVOFMT_DOWNLOAD_MODE = 'success'
  vim.uv.os_uname = original_uname
  local ok, err = pcall(body)
  if ok then print('PASS ' .. name) else failed = failed + 1; print('FAIL ' .. name .. ': ' .. tostring(err)) end
end
local function manager()
  local release = require('revofmt.release')
  -- CI may supply a fresh build. Use sha256sum as an independent hash oracle.
  release.sha256 = vim.fn.system({ 'sha256sum', real }):match('^(%x+)')
  vim.env.REVOFMT_EXPECT_URL = release.url
  return require('revofmt.binary')
end
local function install(binary)
  local ok, err = binary.install({ async = false })
  assert(ok, err)
  assert(err == nil, 'successful installation returned an error: ' .. tostring(err))
end
local function format_current()
  local fmt = require('revofmt')
  fmt.setup()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'let x=1' })
  vim.bo.endofline = false
  assert(fmt.format({ async = false }))
  equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { 'let x = 1' })
  assert(vim.bo.endofline)
end

test('registers the explicit install command', function()
  require('revofmt').setup()
  assert(vim.fn.exists(':RevoFmtInstall') == 2, 'install command is missing')
end)
test('install command reports subprocess start failures once and recovers', function()
  local binary = manager()
  local notifications = {}
  local original_system, original_notify = vim.system, vim.notify
  vim.notify = function(message) notifications[#notifications + 1] = message end
  vim.system = function(args, ...)
    if args[1] == 'curl' then error('controlled download spawn failure') end
    return original_system(args, ...)
  end
  local ok, err = pcall(function()
    vim.cmd('RevoFmtInstall')
    equal(#notifications, 1)
    assert(notifications[1]:find('controlled download spawn failure', 1, true))
    assert(vim.fn.filereadable(binary.path()) == 0)
    vim.system = original_system
    install(binary)
    format_current()
  end)
  vim.system, vim.notify = original_system, original_notify
  assert(ok, err)
end)
test('public install completes immediate failures through its callback once', function()
  local binary = manager()
  vim.uv.os_uname = function() return { sysname = 'Darwin', machine = 'arm64' } end
  local calls, success, reason = 0, nil, nil
  local ok, err = require('revofmt').install({ on_done = function(result, detail)
    calls, success, reason = calls + 1, result, detail
  end })
  assert(not ok and err:find('Linux x86_64', 1, true), tostring(err))
  equal(calls, 1); equal(success, false); equal(reason, err)
  assert(vim.fn.filereadable(binary.path()) == 0)
  assert(vim.fn.filereadable(vim.env.REVOFMT_DOWNLOAD_LOG) == 0)
end)
test('installs verified bytes and formats without an executable setting', function()
  local binary = manager()
  install(binary)
  assert(vim.fn.executable(binary.path()) == 1)
  equal(vim.fn.system({ binary.path(), '--version' }):match('^revofmt %S+'), 'revofmt ' .. require('revofmt.release').version)
  format_current()
end)
test('repeated installation reuses a verified binary without downloading again', function()
  local binary = manager()
  install(binary); install(binary)
  equal(#vim.fn.readfile(vim.env.REVOFMT_DOWNLOAD_LOG), 1)
end)
test('rejects wrong checksums before executable publication', function()
  local binary = manager()
  vim.env.REVOFMT_DOWNLOAD_MODE = 'mismatch'
  local ok, err = binary.install({ async = false })
  assert(not ok and err:find('checksum', 1, true), tostring(err))
  assert(vim.fn.filereadable(binary.path()) == 0)
end)
test('a failed download preserves an existing working formatter', function()
  local binary = manager()
  install(binary)
  local before = vim.fn.system({ 'sha256sum', binary.path() })
  vim.env.REVOFMT_DOWNLOAD_MODE = 'failure'
  local ok, err = binary.install({ async = false, force = true })
  assert(not ok and err:find('HTTP failure', 1, true), tostring(err))
  equal(vim.fn.system({ 'sha256sum', binary.path() }), before)
  format_current()
end)
test('rejects oversized downloads', function()
  local binary = manager()
  vim.env.REVOFMT_DOWNLOAD_MODE = 'oversize'
  local ok, err = binary.install({ async = false })
  assert(not ok and err:find('size', 1, true), tostring(err))
  assert(vim.fn.filereadable(binary.path()) == 0)
end)
test('rejects signal-terminated downloads', function()
  local binary = manager()
  vim.env.REVOFMT_DOWNLOAD_MODE = 'signal'
  local ok, err = binary.install({ async = false })
  assert(not ok and err:find('download', 1, true), tostring(err))
  assert(vim.fn.filereadable(binary.path()) == 0)
end)
test('unsupported platforms explain the available build instead of downloading', function()
  local binary = manager()
  vim.uv.os_uname = function() return { sysname = 'Darwin', machine = 'arm64' } end
  local ok, err = binary.install({ async = false })
  assert(not ok and err:find('Linux x86_64', 1, true), tostring(err))
  assert(vim.fn.filereadable(vim.env.REVOFMT_DOWNLOAD_LOG) == 0)
end)
test('explicit executable overrides take precedence over the managed binary', function()
  local binary = manager()
  install(binary)
  equal(binary.resolve('/explicit/missing'), '/explicit/missing')
  equal(binary.resolve('revofmt'), 'revofmt')
end)
test('falls back to PATH when no managed formatter exists', function()
  local binary = manager()
  assert(vim.uv.fs_symlink(real, sandbox .. '/tools/revofmt'))
  equal(binary.resolve(), sandbox .. '/tools/revofmt')
  vim.fn.delete(sandbox .. '/tools/revofmt')
end)
test('missing executables offer the install command', function()
  local binary = manager()
  local path, err = binary.resolve()
  assert(not path and err:find(':RevoFmtInstall', 1, true), tostring(err))
end)
test('asynchronous installation completes once and rejects overlapping downloads', function()
  local binary = manager()
  vim.env.REVOFMT_DOWNLOAD_MODE = 'delay'
  local calls, success = 0, nil
  local ok, err = binary.install({ on_done = function(result) calls = calls + 1; success = result end })
  assert(ok, err)
  local second, reason = binary.install()
  assert(not second and reason:find('progress', 1, true), tostring(reason))
  assert(vim.wait(3000, function() return calls > 0 end, 5))
  equal(calls, 1); assert(success)
  format_current()
end)
test('health reports missing binaries and succeeds after installation', function()
  local binary = manager()
  local reports = {}
  local saved = {}
  for _, name in ipairs({ 'start', 'ok', 'warn', 'error', 'info' }) do
    saved[name] = vim.health[name]
    vim.health[name] = function(message) reports[#reports + 1] = { name, message } end
  end
  local ok, err = pcall(function()
    require('revofmt').setup()
    require('revofmt.health').check()
    assert(vim.iter(reports):any(function(item) return item[1] == 'error' and item[2]:find('RevoFmtInstall', 1, true) end))
    install(binary); reports = {}
    require('revofmt.health').check()
    assert(vim.iter(reports):any(function(item) return item[1] == 'ok' and item[2]:find('smoke', 1, true) end))
    assert(not vim.iter(reports):any(function(item) return item[1] == 'error' end))
  end)
  for name, value in pairs(saved) do vim.health[name] = value end
  assert(ok, err)
end)
vim.env.PATH = original_path
vim.uv.os_uname = original_uname
vim.fn.delete(sandbox, 'rf')
print(string.format('%d installation tests, %d failures', count, failed))
vim.cmd(failed == 0 and 'qa!' or 'cquit 1')
