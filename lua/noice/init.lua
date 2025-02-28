local require = require("noice.util.lazy")

local Health = require("noice.health")
local Api = require("noice.api")
local Config = require("noice.config")

local M = {}

M.api = Api

---@param opts? NoiceConfig
function M.setup(opts)
  -- run some checks before setting up
  if not Health.check({ checkhealth = false, loaded = false }) then
    return
  end

  local function load()
    require("noice.util").try(function()
      require("noice.config").setup(opts)
      require("noice.commands").setup()
      require("noice.message.router").setup()
      M.enable()
    end)
  end

  if vim.v.vim_did_enter == 0 then
    -- Schedule loading after VimEnter. Get the UI up and running first.
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = load,
    })
  else
    -- Schedule on the event loop
    vim.schedule(load)
  end
end

function M.disable()
  Config._running = false
  if Config.options.notify.enabled then
    require("noice.source.notify").disable()
  end
  require("noice.message.router").disable()
  require("noice.ui").disable()
  require("noice.util.hacks").disable()
end

function M.cmd(name)
  require("noice.commands").cmd(name)
end

function M.enable()
  Config._running = true
  if Config.options.notify.enabled then
    require("noice.source.notify").enable()
  end
  require("noice.util.hacks").enable()
  require("noice.ui").enable()
  require("noice.message.router").enable()

  if Config.options.health.checker then
    Health.checker()
  end
end

-- Redirect any messages generated by a command or function
---@param cmd string|fun() command or function to execute
---@param routes? NoiceRouteConfig[] custom routes. Defaults to `config.redirect`
function M.redirect(cmd, routes)
  return require("noice.message.router").redirect(cmd, routes)
end

---@param msg string
---@param level number|string
---@param opts? table<string, any>
function M.notify(msg, level, opts)
  return require("noice.source.notify").notify(msg, level, opts)
end

return M
