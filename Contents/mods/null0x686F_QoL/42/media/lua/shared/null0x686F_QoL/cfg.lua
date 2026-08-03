local cfg = {}

local _is_debug_mode = (isDebugEnabled and isDebugEnabled()) or false

-- automatic log level: "debug" when launched with -debug flag, "info" (silent) for regular players
cfg.LOG_LEVEL = _is_debug_mode and "debug" or "info"

cfg.ZOMBIE_OUTLINE = {
  enabled = true,
  -- custom outline color (R, G, B, A) in float values (0.0 to 1.0)
  -- default: Electric Cyan highlight
  colorRGBA = { 0.0, 1.0, 0.8, 1.0 },
}

return cfg
