local M = {}
function M.check()
  vim.health.start('revofmt')
  if vim.fn.has('nvim-0.10') == 0 then
    vim.health.error('Neovim >=0.10 is required')
    return
  end
  local executable, err = require('revofmt').executable()
  if not executable then
    vim.health.error(err)
  else
    vim.health.info('Formatter: ' .. executable)
    local process, start_error = require('revofmt.transport').start({
      executable = executable, indent_width = 2, line_width = 80, indent_style = 'space',
      max_blank_lines = 1, timeout_ms = 2000,
    }, 'let x=1')
    local result = process and process.wait()
    if result and not result.error and result.code == 0 and result.stdout == 'let x = 1\n' then
      vim.health.ok('Formatter smoke check passed')
    else
      local detail = start_error or (result and (result.error or result.stderr)) or 'unknown process failure'
      vim.health.error('Formatter smoke check failed: ' .. detail)
    end
  end
  for _, tool in ipairs({ 'curl', 'sha256sum' }) do
    if vim.fn.executable(tool) == 1 then
      vim.health.ok(tool .. ' is available for :RevoFmtInstall')
    else
      vim.health.warn(tool .. ' is unavailable; configure an existing executable or install ' .. tool)
    end
  end
end
return M
