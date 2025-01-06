assert(loadfile("config.lua"))()

local parameters = {
  { fieldFunction = CreateChoiceField, fieldName = "Rotation direction", pageAddress = 0x80, extraInfo = {valuePairs = {{"Normal", 0}, {"Reversed", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "Use sin start", pageAddress = 0x81, defaultValue = 1, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "Soft Start", pageAddress = 0x82, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateChoiceField, fieldName = "ESC beep", pageAddress = 0x83, defaultValue = 1, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateNumberField, fieldName = "PWM min(Effective after restart)", pageAddress = 0x84, defaultValue = 1000, extraInfo = {min = 885, max = 1500}},
  { fieldFunction = CreateNumberField, fieldName = "PWM max(Effective after restart)", pageAddress = 0x85, defaultValue = 2000, extraInfo = {min = 1500, max = 2115}},
  { fieldFunction = CreateNumberField, fieldName = "Soft brake", pageAddress = 0x86, extraInfo = {min = 0, max = 100, suffix = "%"}},
  { fieldFunction = CreateChoiceField, fieldName = "3D Mode(Effective after restart)", pageAddress = 0x87, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreateNumberField, fieldName = "Current calibration", pageAddress = 0x88, defaultValue = 100, extraInfo = {min = 75, max = 125, suffix = "%"}},
  { fieldFunction = CreateNumberField, fieldName = "Current limit", pageAddress = 0x89, defaultValue = 40, getValue = function (value)
    return value / 100
  end, setValue = function(param, newValue)
    param.value = newValue * 100
    param.state = FieldState.DIRTY
  end, extraInfo = {min = 0, max = 655, suffix = "A"}},
  { fieldFunction = CreateNumberField, fieldName = "BEC voltage", pageAddress = 0x8A, defaultValue = 50, getValue = function (value)
    return value / 10
  end, setValue = function(param, newValue)
    param.value = newValue * 10
    param.state = FieldState.DIRTY
  end, extraInfo = {min = 50, max = 84, suffix = "V", prec = 1}},
  { fieldFunction = CreateChoiceField, fieldName = "Trapezoidal mode", pageAddress = 0x8B, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
  { fieldFunction = CreatePhyIdField, fieldName = "Physical Id", pageAddress = 0x8C, defaultValue = 10, extraInfo = {} },
  { fieldFunction = CreateAppIdField, fieldName = "Application Id", pageAddress = 0x8D, extraInfo = {} },
  { fieldFunction = CreateNumberField, fieldName = "Data rate", pageAddress = 0x8E, defaultValue = 1, extraInfo = {min = 0, max = 10, suffix = "00ms"}},
  { fieldFunction = CreateNumberField, fieldName = "Motor pole count", pageAddress = 0x8F, defaultValue = 14, extraInfo = {min = 2, max = 255}},
  { fieldFunction = CreateNumberField, fieldName = "F.Bus thr. CH(Effective after restart)", pageAddress = 0x90, defaultValue = 1, extraInfo = {min = 1, max = 255}},
  { fieldFunction = CreateChoiceField, fieldName = "High demag prot.", pageAddress = 0x91, extraInfo = {valuePairs = {{"OFF", 0}, {"ON", 1}}} },
}

local function create()
  Params = parameters
  InitPage()
  local sensor = sport.getSensor({appIdStart = 0x0E50, appIdEnd = 0x0E5F})
  return {sensor = sensor, needIdle = true}
end

return {create = create, name = "ESC", wakeup = Wakeup, close = PageClose}
