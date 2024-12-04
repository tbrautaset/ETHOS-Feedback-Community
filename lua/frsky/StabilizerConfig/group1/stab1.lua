local requestInProgress = false
local refreshIndex = 0
local modifications = {}
local fields = {}

local function getValue(parameter)
  if parameter[5] == nil then
    return 0
  else
    local sub = parameter[4]
    local value = ((parameter[5] >> (8 * (sub - 1))) & 0xFF)
    if #parameter >= 9 then
      value = value - parameter[9]
    end
    return value
  end
end

local function setValue(parameter, value)
  local sub = parameter[4]
  local D1 = parameter[5] & 0xFF
  local D2 = (parameter[5] >> 8) & 0xFF
  local D3 = (parameter[5] >> 16) & 0xFF

  if #parameter >= 9 then
    value = value + parameter[9]
  end

  if sub == 1 then
    D1 = value
  elseif sub == 2 then
    D2 = value
  elseif sub == 3 then
    D3 = value
  end
  value = D1 + D2 * 256 + D3 * 256 * 256
  local fieldId = parameter[3]
  modifications[#modifications+1] = {fieldId, value}
  for index = 2, #fields do
    if fields[index] then
      fields[index]:enable(false)
    end
  end
end

local function createNumberField(line, parameter)
  local field = form.addNumberField(line, nil, parameter[6], parameter[7], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enableInstantChange(false)
  if #parameter >= 8 then
    field:suffix(parameter[8])
  end
  if #parameter >= 10 then
    field:prefix(parameter[10])
  end
  field:enable(false)
  return field
end

local function createChoiceField(line, parameter)
  local field = form.addChoiceField(line, nil, parameter[6], function() return getValue(parameter) end, function(value) setValue(parameter, value) end)
  field:enable(false)
  return field
end

-- local function createTextButton(line, parameter)
--   local field = form.addTextButton(line, nil, parameter[6], function() setValue(parameter, parameter[7]) end)
--   field:enable(false)
--   return field
-- end

local function createResetButton(line, parameter)
  local field = form.addTextButton(line, nil, parameter[6], function()
    local buttons = {
      {label="Cancel", action=function () return true end},
      {label="Reset", action=function() setValue(parameter, parameter[7]) return true end},
    }
    form.openDialog({
      title="Confirm reset",
      message="Settings are about to be reset.\nPlease confirm to continue.",
      buttons=buttons
    })
  end)
  field:enable(false)
  return field
end

local parameters = {
  -- { name, type, page, sub, value, min, max, unit, offset }
  {"Reset", createResetButton, 0xA5, 3, nil, "Start", 0x81},
  {"Stabilizer", createChoiceField, 0xA5, 1, nil, {{"Off", 0}, {"On", 1}} },
  -- {"Self check", createTextButton, 0xA5, 2, nil, "Start", 1},
  {"Quick mode", createChoiceField, 0xA6, 1, nil, {{"Disable", 0}, {"Enable", 1}} },

  {"Wing type", createChoiceField, 0xA6, 2, nil, {{"Normal", 0}, {"Delta", 1}, {"VTail", 2}} },
  {"Mounting type", createChoiceField, 0xA6, 3, nil, {{"Horizontal", 0}, {"Horizontal reverse", 1}, {"Vertical", 2}, {"Vertical reverse", 3}} },

  {"CH1 mode", createChoiceField, 0xA7, 1, nil, {{"AIL1", 0}, {"AUX", 1}} },
  {"CH2 mode", createChoiceField, 0xA7, 2, nil, {{"ELE1", 0}, {"AUX", 1}} },
  {"CH4 mode", createChoiceField, 0xA7, 3, nil, {{"RUD", 0}, {"AUX", 1}} },
  {"CH5 mode", createChoiceField, 0xA8, 1, nil, {{"AIL2", 0}, {"AUX", 1}} },
  {"CH6 mode", createChoiceField, 0xA8, 2, nil, {{"ELE2", 0}, {"AUX", 1}} },

  {"AIL inverted", createChoiceField, 0xA9, 1, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"ELE inverted", createChoiceField, 0xA9, 2, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"RUD inverted", createChoiceField, 0xA9, 3, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"AIL2 inverted", createChoiceField, 0xAA, 1, nil, {{"Off", 0}, {"On", 0xFF}} },
  {"ELE2 inverted", createChoiceField, 0xAA, 2, nil, {{"Off", 0}, {"On", 0xFF}} },

  {"AIL stab gain", createNumberField, 0xAB, 1, nil, 0, 200, "%"},
  {"ELE stab gain", createNumberField, 0xAB, 2, nil, 0, 200, "%"},
  {"RUD stab gain", createNumberField, 0xAB, 3, nil, 0, 200, "%"},
  {"AIL auto 1v1 gain", createNumberField, 0xAC, 1, nil, 0, 200, "%"},
  {"ELE auto 1v1 gain", createNumberField, 0xAC, 2, nil, 0, 200, "%"},
  {"ELE hover gain", createNumberField, 0xAD, 2, nil, 0, 200, "%"},
  {"RUD hover gain", createNumberField, 0xAD, 3, nil, 0, 200, "%"},
  {"AIL knife gain", createNumberField, 0xAE, 1, nil, 0, 200, "%"},
  {"RUD knife gain", createNumberField, 0xAE, 3, nil, 0, 200, "%"},

  {"AIL auto 1v1 offset", createNumberField, 0xAF, 1, nil, -20, 20, "%", 0x80},
  {"ELE auto 1v1 offset", createNumberField, 0xAF, 2, nil, -20, 20, "%", 0x80},
  {"ELE hover offset", createNumberField, 0xB0, 2, nil, -20, 20, "%", 0x80},
  {"RUD hover offset", createNumberField, 0xB0, 3, nil, -20, 20, "%", 0x80},
  {"AIL knife offset", createNumberField, 0xB1, 1, nil, -20, 20, "%", 0x80},
  {"RUD knife offset", createNumberField, 0xB1, 3, nil, -20, 20, "%", 0x80},

  {"Roll degree", createNumberField, 0xB3, 1, nil, 0, 80, "°"},
  {"Pitch degree", createNumberField, 0xB3, 2, nil, 0, 80, "°"},

  {"AIL1 stick priority", createNumberField, 0xB4, 1, nil, 0, 100, "%"},
  {"AIL1 rev. stick priority", createNumberField, 0xB4, 2, nil, 0, 100, "%", 0, "-"},
  {"ELE1 stick priority", createNumberField, 0xB5, 1, nil, 0, 100, "%"},
  {"ELE1 rev. stick priority", createNumberField, 0xB5, 2, nil, 0, 100, "%", 0, "-"},
  {"RUD stick priority", createNumberField, 0xB6, 1, nil, 0, 100, "%"},
  {"RUD rev. stick priority", createNumberField, 0xB6, 2, nil, 0, 100, "%", 0, "-"},
  {"AIL2 stick priority", createNumberField, 0xB7, 1, nil, 0, 100, "%"},
  {"AIL2 rev. stick priority", createNumberField, 0xB7, 2, nil, 0, 100, "%", 0, "-"},
  {"ELE2 stick priority", createNumberField, 0xB8, 1, nil, 0, 100, "%"},
  {"ELE2 rev. stick priority", createNumberField, 0xB8, 2, nil, 0, 100, "%", 0, "-"},
}

local restoreFileName = ""
local addressIndex = 3
local valueIndex = 5
local function buildBackupForm(ePanel, focusRefresh)
  ePanel:clear()

  local ePanelLine = ePanel:addLine("")
  local slots = form.getFieldSlots(ePanelLine, {270, "- Load -","- Save -"})

  form.addFileField(ePanelLine, slots[1], "", "csv+ext", function ()
    return restoreFileName
  end, function (newFile)
    restoreFileName = newFile
  end)

  form.addTextButton(ePanelLine, slots[2], "Load", function()
    if refreshIndex == 0 then
      Dialog.openDialog({title = "Load failed", message = "Please read the settings firstly.", buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
      return
    end

    if not restoreFileName or restoreFileName == "" then
      Dialog.openDialog({title = "No file selected", message = "Please select the file you\nwant to load the configures from.", buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
      return
    end

    local file = io.open(restoreFileName, "r+")
    if file == nil then
      Dialog.openDialog({title = "Load failed", message = "File read error.", buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
      return
    end

    local line = file:read("l")
    while line do
      local lineData = {}
      for value in line:gmatch("([^,]+)") do
        lineData[#lineData + 1] = tonumber(value)
        if #lineData >= 2 then
          break
        end
      end
      if lineData[1] ~= nil and lineData[2] ~= nil then
        modifications[#modifications + 1] = {lineData[1], lineData[2]}
      end
      line = file:read("l")
    end
    file:close()
    for index = 1, #fields do
      if fields[index] then
        fields[index]:enable(false)
      end
    end
    Dialog.openDialog({title = "Configure loaded", message = "Configure has been loaded from\n" .. restoreFileName, buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
  end)

  local button = form.addTextButton(ePanelLine, slots[3], "Save", function()
    if refreshIndex == 0 then
      Dialog.openDialog({title = "Save failed", message = "Please read the settings firstly.", buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
      return
    end

    local output = ""
    local addresses = {}
    local fullTable = parameters

    for pi = 1, #fullTable do
      local find = false
      local param = fullTable[pi]
      for ai = 1, #addresses do
        if addresses[ai] == param[addressIndex] then
          find = true
          break
        end
      end
      if not find and param[valueIndex] ~= nil then
        output = output .. param[addressIndex] .. "," .. param[valueIndex] .. ",\n"
        addresses[#addresses + 1] = param[addressIndex]
      end
    end

    local file
    local configPrefix = model.name():gsub("%s", "_")
    local configSuffix = ".csv"
    local fileName = configPrefix .. configSuffix
    file = io.open(fileName, "r")
    if file ~= nil then
      for i = 2, 99 do
        fileName = configPrefix .. string.format("%02d", i) .. configSuffix
        file = io.open(fileName, "r")
        if file == nil then
          break
        end
        file:close()
        if i == 99 then
          Dialog.openDialog({title = "Save failed", message = "Cannot save to file!", buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
          return
        end
      end
    end

    file = io.open(fileName, "w+")
    if file ~= nil then
      file:write(output)
      file:close()
      Dialog.openDialog({title = "Configure saved", message = "Configure has been saved into\n" .. fileName, buttons = {{label = "OK", action = function ()
        Dialog.closeDialog()
        buildBackupForm(ePanel, true)
      end}},})
    else
      Dialog.openDialog({title = "Save failed", message = "File operation error.", buttons = {{label = "OK", action = function () Dialog.closeDialog() end}},})
    end
  end)
  if focusRefresh then
    button:focus()
  else
    ePanel:open(false)
  end
end

local function pageInit()
  requestInProgress = false
  refreshIndex = 0
  modifications = {}
  fields = {}

  local configureForm = form.addExpansionPanel("Save & Load configures")
  buildBackupForm(configureForm)

  for index = 1, #parameters do
    local parameter = parameters[index]
    local line = form.addLine(parameter[1])
    local field = parameter[2](line, parameter)
    fields[index] = field
  end
end

local function wakeup(widget)
  if requestInProgress then
    local value = Sensor.getParameter()
    -- print("widget.sensor:getParameter = ", value)
    if value then
      local fieldId = value % 256
      local parameter = parameters[refreshIndex + 1]
      if fieldId == parameter[3] then
        value = math.floor(value / 256)
        while (parameters[refreshIndex + 1][3] == fieldId)
        do
          parameters[refreshIndex + 1][5] = value
          if value ~= nil then
            if fields[refreshIndex + 1] then
              fields[refreshIndex + 1]:enable(true)
            end
          end
          refreshIndex = refreshIndex + 1
          if refreshIndex > (#parameters - 1) then break end
        end
        requestInProgress = false
      end
    else
      requestInProgress = false
    end
  else
    if #modifications > 0 then
      -- print("writeParameter", modifications[1][1], modifications[1][2])
      if Sensor.writeParameter(modifications[1][1], modifications[1][2]) == true then
        if modifications[1][1] == 0x13 then -- appId changed
          Sensor.appId(Sensor.APPID + ((modifications[1][2] >> 8) & 0xFF))
        end
        refreshIndex = 0
        requestInProgress = false
        table.remove(modifications, 1)
      end
    elseif refreshIndex <= (#parameters - 1) then
      local parameter = parameters[refreshIndex + 1]
      -- print("requestParameter", parameter[3])
      if Sensor.requestParameter(parameter[3]) then
        requestInProgress = true
      end
    end
  end
end

return {pageInit = pageInit, wakeup = wakeup}
