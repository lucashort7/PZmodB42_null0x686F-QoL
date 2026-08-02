local cfg = require("null0x686F_QoL/cfg")
local core_log = require("null0x686F_CoreLib/utils/log")

return core_log.newFileLogger("null0x686F_QoL", cfg.LOG_LEVEL or "info")
