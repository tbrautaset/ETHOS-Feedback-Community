-- FrSky lua device config basic
---@diagnostic disable: unused-local

FieldState = {
  INIT = 1,
  IDLE = 2,
  RECEIVED = 3,
  DIRTY = 4,
  SKIPPED = 5,
}

local function getValue(param)
  if param.getValue ~= nil then
    return param.getValue(param.value)
  end

  if param.value == nil then
    return param.defaultValue ~= nil and param.defaultValue or 0
  else
    if param.valueIndex then
      return (param.value >> ((param.valueIndex - 1) * 8)) & 0xFF
    else
      return param.value
    end
  end
end

local function setValue(param, newValue)
  if param.setValue ~= nil then
    param.setValue(param, newValue)
    return
  end

  if param.valueIndex then
    local shift = (param.valueIndex - 1) * 8
    param.value = param.value & ~(0xFF << shift) | (newValue << shift)
  else
    param.value = newValue
  end
  param.state = FieldState.DIRTY
end

--[[
  CreateChoiceField(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, setValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      setValue (function) - Optional. Only needed when the field requires a special setValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      defaultValue (number) - Optional. Only needed when the field hasn't been read yet. To set the value which should be displayed
      extraInfo (table) - Necessary. extraInfo = { valuePairs }
        valuePairs (table) - Necessary. The pairs for choice field to map value with test. Should be in form like {{0, "value1"}, {1, "value2"}, ...}

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateChoiceField(param)
  if param.extraInfo == nil or param.extraInfo.valuePairs == nil then
    print("Field create failed (" .. param.fieldName .. ") - Missing valuePairs")
    return
  end

  local line = form.addLine(param.fieldName)
  local field = form.addChoiceField(line, nil, param.extraInfo.valuePairs, function()
    return getValue(param)
  end, function(value)
    return setValue(param, value)
  end)
  field:enable(false)
  param.field = field
end

--[[
  CreateNumberField(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, setValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      setValue (function) - Optional. Only needed when the field requires a special setValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      defaultValue (number) - Optional. Only needed when the field hasn't been read yet. To set the value which should be displayed
      extraInfo (table) - Necessary. extraInfo = { min, max, step, suffix, prefix, prec, text }
        min (number) - Necessary. Min value for the number edit
        max (number) - Necessary. Max value for the number edit
        step (number) - Optional. Step during the number edit
        suffix (string) - Optional. Display suffix for the number edit
        prefix (string) - Optional. Display prefix for the number edit
        prec (number) - Optional. Represent the display's resolution
        text (function) - Optional. Custom function to get display text from a value.

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateNumberField(param)
  if param.extraInfo == nil or param.extraInfo.min == nil or param.extraInfo.max == nil then
    print("Field create failed (" .. param.fieldName .. ") - Missing min/max")
    return
  end

  local line = form.addLine(param.fieldName)
  local field = form.addNumberField(line, nil, param.extraInfo.min, param.extraInfo.max, function()
    return getValue(param)
  end, function(value)
    return setValue(param, value)
  end)
  field:enableInstantChange(false)
  if param.extraInfo.step then
    field:step(param.extraInfo.step)
  end
  if param.extraInfo.suffix then
    field:suffix(param.extraInfo.suffix)
  end
  if param.extraInfo.prefix then
    field:prefix(param.extraInfo.prefix)
  end
  if param.extraInfo.prec then
    field:decimals(param.extraInfo.prec)
  end
  if param.extraInfo.text then
    field:text(param.extraInfo.text)
  end
  field:enable(false)
  param.field = field
end

--[[
  CreateTextButton(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, setValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      setValue (function) - Optional. Only needed when the field requires a special setValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      extraInfo (table) - Necessary. extraInfo = { buttonText }
        buttonText (string) - Necessary. The text displays on the button

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateTextButton(param)
  if param.extraInfo == nil or param.extraInfo.buttonText == nil then
    print("Field create failed (" .. param.fieldName .. ") - Missing buttonText")
    return
  end

  local line = form.addLine(param.fieldName)
  local field = form.addTextButton(line, nil, param.extraInfo.buttonText, function()
    setValue(param)
    return 0
  end)
  field:enable(false)
  param.field = field
end

--[[
  CreateStaticText(param)
    param (table) - { fieldFunction, fieldName, pageAddress, getValue, valueIndex, extraInfo }
      fieldFunction (function) - Necessary. The function creates the field
      fieldName (string) - Necessary. The field name displays at the begining
      pageAddress (number) - Necessary.
      getValue (function) - Optional. Only needed when the field requires a special getValue handler
      valueIndex (number) - Optional. Only needed when the field doesn't need the whole received value. Normally would be 1 ~ 3
      defaultValue (number) - Optional. Only needed when the field hasn't been read yet. To set the value which should be displayed
      extraInfo (table) - Optional. extraInfo = { }

      The following field will be added by code automaticlly
        value (number) - The current value for the address. 3 bytes
        state (number) - The field state, see FieldState
--]]
function CreateStaticText(param)
  local line = form.addLine(param.fieldName)
  form.addStaticText(line, nil, function()
    return getValue(param)
  end)
end

local appIdPairs = {{"0000", 0}, {"0001", 1}, {"0002", 2}, {"0003", 3}, {"0004", 4}, {"0005", 5}, {"0006", 6}, {"0007", 7},
                    {"0008", 8}, {"0009", 9}, {"000A", 10}, {"000B", 11}, {"000C", 12}, {"000D", 13}, {"000E", 14}, {"000F", 15},}

function CreateAppIdField(param)
  param.isAppId = true
  if param.extraInfo == nil then
    param.extraInfo = {}
  end
  param.extraInfo.valuePairs = appIdPairs
  CreateChoiceField(param)
end

local phyIdPairs = {{"00", 0}, {"01", 1}, {"02", 2}, {"03", 3}, {"04", 4}, {"05", 5}, {"06", 6}, {"07", 7},
                    {"08", 8}, {"09", 9}, {"0A", 10}, {"0B", 11}, {"0C", 12}, {"0D", 13}, {"0E", 14}, {"0F", 15},
                    {"10", 16}, {"11", 17}, {"12", 18}, {"13", 19}, {"14", 20}, {"15", 21}, {"16", 22}, {"17", 23},
                    {"18", 24}, {"19", 25}, {"1A", 26},}

function CreatePhyIdField(param)
  if param.extraInfo == nil then
    param.extraInfo = {}
  end
  param.extraInfo.valuePairs = phyIdPairs
  CreateChoiceField(param)
end

local requestInProgress
local lastRquestTime
Params = {}

function InitPage()
  print("Enter config page, InitPage()")
  requestInProgress = false
  lastRquestTime = 0

  for index, parameter in pairs(Params) do
    if parameter.fieldFunction == nil then
      print("Missing field function!")
    elseif parameter.fieldName == nil then
      print("Missing field name")
    elseif parameter.pageAddress == nil then
      print("Missing field page address")
    else
      parameter.state = FieldState.INIT
      parameter.fieldFunction(parameter)
    end
  end
end

function Wakeup(data)
  if Params == nil or not data.sensor:alive() then
    return
  end
  if data.needIdle == nil or data.needIdle then
    for index, parameter in pairs(Params) do
      if parameter.state == FieldState.INIT then
        if data.sensor:idle(true) then
          parameter.state = FieldState.IDLE
        end
        return
      end
    end
  else
    for index, parameter in pairs(Params) do
      parameter.state = FieldState.IDLE
    end
  end

  if requestInProgress then
    local receivedValue = data.sensor:getParameter()
    if receivedValue ~= nil then
      print("data.sensor:getParameter(): ", string.format("%X", receivedValue))
      local pageAddress = receivedValue & 0xFF
      local value = receivedValue >> 8
      for index, parameter in pairs(Params) do
        if parameter.pageAddress == pageAddress then
          parameter.value = value
          parameter.state = FieldState.RECEIVED
          if parameter.field ~= nil then
            parameter.field:enable(true)
          end
        end
      end
      requestInProgress = false
    elseif lastRquestTime + 1 < os.time() then
      requestInProgress = false
    end
  else
    for index, parameter in pairs(Params) do
      if parameter.state == FieldState.IDLE then
        if data.sensor:requestParameter(parameter.pageAddress) then
          print("data.sensor:requestParameter(" .. string.format("%X", parameter.pageAddress) .. ")")
          requestInProgress = true
          lastRquestTime = os.time()
          return
        end
      elseif parameter.state == FieldState.DIRTY then
        if data.sensor:writeParameter(parameter.pageAddress, parameter.value) then
          print("data.sensor:writeParameter(" .. string.format("%X", parameter.pageAddress) .. "): " .. string.format("%X", parameter.value))
          if parameter.isAppId ~= nil and parameter.isAppId then
            local oldAppId = data.sensor:appId()
            data.sensor:appId(oldAppId & 0xFFF0 | parameter.value)
          end
          requestInProgress = false
          parameter.state = FieldState.IDLE
          return
        end
      end
    end
  end
end

function PageClose(data)
  if data.needIdle then
    data.sensor:idle(false)
  end
end
