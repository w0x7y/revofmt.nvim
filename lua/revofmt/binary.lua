local release = require('revofmt.release')
local M = {}
local installing = false
local size_limit = 16 * 1024 * 1024

function M.path()
  return vim.fn.stdpath('data') .. '/revofmt/' .. release.version .. '/revofmt'
end

function M.resolve(executable)
  if executable then return executable end
  local managed = M.path()
  if vim.fn.executable(managed) == 1 then return managed end
  local found = vim.fn.exepath('revofmt')
  if found ~= '' then return found end
  return nil, 'formatter not found; run :RevoFmtInstall, then :RevoFormat, or set executable explicitly'
end

local function verified(path)
  local stat = vim.uv.fs_lstat(path)
  if not stat or stat.type ~= 'file' then return false, 'download is not a regular file' end
  if stat.size == 0 or stat.size > size_limit then return false, 'download size is outside the allowed limit' end
  -- Neovim 0.10 converts NUL-bearing Lua strings to Vim Blobs, which its
  -- sha256() rejects. Hash the file directly without decoding binary bytes.
  local launched, hash = pcall(function()
    return vim.system({ 'sha256sum', '--zero', '--', path }, { text = true, timeout = 5000 }):wait()
  end)
  if not launched or hash.code ~= 0 or hash.signal ~= 0 then
    return false, 'could not verify checksum; install sha256sum or configure executable'
  end
  if not hash.stdout or hash.stdout:match('^(%x+)%s') ~= release.sha256 then
    return false, 'formatter checksum mismatch; no binary was installed'
  end
  return true
end

local function publish(candidate, target)
  local ok, err = verified(candidate)
  if not ok then return false, err end
  ok, err = vim.uv.fs_chmod(candidate, 448) -- 0700, only after checksum validation.
  if not ok then return false, 'could not make formatter executable: ' .. tostring(err) end
  local launched, version = pcall(function()
    return vim.system({ candidate, '--version' }, { text = true, timeout = 5000 }):wait()
  end)
  if not launched or version.code ~= 0 or version.signal ~= 0
    or not version.stdout or not version.stdout:match('^revofmt ' .. release.version:gsub('%.', '%%.') .. ' ') then
    local detail = launched and (version.stderr or '') or tostring(version)
    return false, 'formatter cannot run on this system; the prebuilt binary requires Linux x86_64 GNU with glibc >=2.34: ' .. detail:sub(1, 2048)
  end
  ok, err = vim.uv.fs_rename(candidate, target)
  if not ok then return false, 'could not publish formatter: ' .. tostring(err) end
  return true
end

-- Explicit installation only. Normal setup and formatting never use the network.
-- Sync mode returns success, error. Async mode returns whether work started and
-- reports completion through on_done(success, error), on the editor thread.
function M.install(opts)
  opts = opts or {}
  if installing then return false, 'formatter installation is already in progress' end
  local platform = vim.uv.os_uname()
  if platform.sysname ~= 'Linux' or platform.machine ~= 'x86_64' then
    return false, 'prebuilt formatter supports Linux x86_64 GNU only; configure executable for another platform'
  end
  if vim.fn.executable('sha256sum') ~= 1 then
    return false, 'install sha256sum to verify the formatter, or configure executable'
  end
  local target = M.path()
  if not opts.force and vim.fn.executable(target) == 1 and verified(target) then
    if opts.on_done then opts.on_done(true) end
    return true
  end
  if vim.fn.executable('curl') ~= 1 then return false, 'install curl to download the formatter, or configure executable' end
  local directory = vim.fn.fnamemodify(target, ':h')
  local made, mkdir_error = pcall(vim.fn.mkdir, directory, 'p', 448)
  if not made then return false, 'could not create install directory: ' .. tostring(mkdir_error) end
  local staging, stage_error = vim.uv.fs_mkdtemp(directory .. '/.install-XXXXXX')
  if not staging then return false, 'could not create download directory: ' .. tostring(stage_error) end
  local candidate = staging .. '/revofmt'
  installing = true
  local function finish(result, start_error)
    local ok, err = false, start_error
    if result then
      if result.code ~= 0 or result.signal ~= 0 then
        err = 'formatter download failed: ' .. (result.stderr or ''):sub(1, 2048)
      else
        local completed, success, reason = pcall(publish, candidate, target)
        if completed then ok, err = success, reason else err = tostring(success) end
      end
    end
    vim.fn.delete(staging, 'rf')
    installing = false
    if opts.on_done then opts.on_done(ok, err) end
    return ok, err
  end
  local args = { 'curl', '--fail', '--location', '--silent', '--show-error',
    '--proto', '=https', '--proto-redir', '=https', '--connect-timeout', '10',
    '--max-time', '60', '--max-filesize', tostring(size_limit), '--output', candidate, release.url }
  if opts.async == false then
    local ok, result = pcall(function()
      return vim.system(args, { text = true, stdout = false, timeout = 65000 }):wait()
    end)
    if not ok then return finish(nil, 'could not start download: ' .. tostring(result)) end
    return finish(result)
  end
  local ok, err = pcall(vim.system, args, { text = true, stdout = false, timeout = 65000 }, function(result)
    vim.schedule(function() finish(result) end)
  end)
  if not ok then return finish(nil, 'could not start download: ' .. tostring(err)) end
  return true
end

return M
