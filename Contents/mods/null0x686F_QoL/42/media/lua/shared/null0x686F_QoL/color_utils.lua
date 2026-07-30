local color_utils = {}

-- predefined basic colors (using snake_case standards)
color_utils.named_colors = {
  red    = { r = 1.0, g = 0.0, b = 0.0, a = 1.0 },
  green  = { r = 0.0, g = 1.0, b = 0.0, a = 1.0 },
  blue   = { r = 0.0, g = 0.0, b = 1.0, a = 1.0 },
  black  = { r = 0.0, g = 0.0, b = 0.0, a = 1.0 },
  white  = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 },
  yellow = { r = 1.0, g = 1.0, b = 0.0, a = 1.0 },
  cyan   = { r = 0.0, g = 1.0, b = 1.0, a = 1.0 },
  purple = { r = 0.5, g = 0.0, b = 0.5, a = 1.0 },
}

---@param r number Float 0.0-1.0
---@param g number Float 0.0-1.0
---@param b number Float 0.0-1.0
---@return string Hex string #RRGGBB
function color_utils.rgb_to_hex(r, g, b)
  local ir = math.floor((r or 0) * 255 + 0.5)
  local ig = math.floor((g or 0) * 255 + 0.5)
  local ib = math.floor((b or 0) * 255 + 0.5)

  -- clamp values to prevent overflow
  ir = math.max(0, math.min(255, ir))
  ig = math.max(0, math.min(255, ig))
  ib = math.max(0, math.min(255, ib))

  return string.format("#%02X%02X%02X", ir, ig, ib)
end

---@param hex string Hex string #RRGGBB or RRGGBB
---@return number, number, number # R, G, B Floats 0.0-1.0
function color_utils.hex_to_rgb(hex)
  if type(hex) ~= "string" then return 1.0, 1.0, 1.0 end
  hex = hex:gsub("#", "")
  if string.len(hex) ~= 6 then return 1.0, 1.0, 1.0 end

  local r = tonumber("0x" .. hex:sub(1, 2)) or 255
  local g = tonumber("0x" .. hex:sub(3, 4)) or 255
  local b = tonumber("0x" .. hex:sub(5, 6)) or 255

  return r / 255.0, g / 255.0, b / 255.0
end

---@param r_255 number 0-255
---@param g_255 number 0-255
---@param b_255 number 0-255
---@return number, number, number # R, G, B Floats 0.0-1.0
function color_utils.rgb255_to_float(r_255, g_255, b_255)
  return (r_255 or 255) / 255.0, (g_255 or 255) / 255.0, (b_255 or 255) / 255.0
end

---@param r number Float 0.0-1.0
---@param g number Float 0.0-1.0
---@param b number Float 0.0-1.0
---@return number, number, number # R, G, B 0-255
function color_utils.float_to_rgb255(r, g, b)
  return math.floor((r or 1.0) * 255), math.floor((g or 1.0) * 255), math.floor((b or 1.0) * 255)
end

---@param name string Color name (e.g. "red")
---@return number, number, number, number # R, G, B, A floats
function color_utils.get_named_color(name)
  if not name or type(name) ~= "string" then return 1.0, 1.0, 1.0, 1.0 end
  local color = color_utils.named_colors[string.lower(name)]
  if color then
    return color.r, color.g, color.b, color.a
  end
  return 1.0, 1.0, 1.0, 1.0   -- fallback to white
end

return color_utils
