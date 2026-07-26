local cfg = require("hortWiz_QoL/cfg")
local core_log = require("hortWiz_Core/log")

return core_log.newFileLogger("HortWiz_QoL", cfg.LOG_LEVEL or "info", "HortWiz_QoL_debug.log")
