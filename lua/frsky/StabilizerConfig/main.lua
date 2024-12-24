local LUA_VERSION = "3.0.1";
local nameI18n = {en = "Stabilizer config"}

local function name()
  local locale = system.getLocale()
  return nameI18n[locale] or nameI18n["en"]
end

TEST = false
GlobalPath = ""

local REMOTE_VERSION_CONSTRAINT = function (major, minor, revision)
  if major > 3 then
    return true
  elseif major == 3 then
    if minor > 0 then
      return true
    elseif minor == 0 then
      return revision >= 0
    else
      return false
    end
  else
    return false
  end
end

local CommonFile = assert(loadfile(GlobalPath .. "common.lua"))()
Product = CommonFile.Product
Module = CommonFile.Module
Sensor = CommonFile.Sensor
Dialog = CommonFile.Dialog
Progress = CommonFile.Progress

-- Data related
local STATE_READ = 1
local STATE_RECEIVE = 2
local STATE_FINISHED = 3
local STATE_PASS = 4

local nextOpTime = nil
local finalTime = nil
local OPERATION_TIMEOUT = 1 -- second(s)
local MAX_TIMEOUT = 10

local supportFields = nil

local createFunction = nil

local REMOTE_DEVICE = {address = 0xFE, state = STATE_READ, field = nil, label = "Remote device", dataHandler = function (value, task)
  Product.family = (value >> 8) & 0xFF
  Product.id = (value >> 16) & 0xFF
  print("Remote device family: " .. Product.family .. ", product: " .. Product.id)
  local FrSkyProducts = assert(loadfile(GlobalPath .. "products.lua"))()
  for i, family in pairs(FrSkyProducts) do
    if family.ID == Product.family then
      for j, product in pairs(family.Products) do
        if product.ID == Product.id then
          supportFields = product.SupportFields
          if task.field ~= nil then
            task.field:value(product.Name)
            task.state = STATE_PASS
            return
          end
        end
      end
    end
  end
  if task.field ~= nil then
    task.field:value("Unsupport device")
  end
end}
local REMOTE_VERSION = {address = 0xFF, state = STATE_READ, field = nil, label = "Remote version", dataHandler = function (value, task)
  local major = (value >> 8) & 0xFF
  local minor = (value >> 16) & 0xFF
  local revision = (value >> 24) & 0xFF
  local remoteVersion = string.format("%d.%d.%d", major, minor, revision)
  print("Remote version: " .. remoteVersion)
  if REMOTE_VERSION_CONSTRAINT(major, minor, revision) then
    if task.field ~= nil then
      task.field:value(remoteVersion)
      task.state = STATE_PASS
    end
  else
    if task.field ~= nil then
      task.field:value("Uncompitable version")
    end
  end
end}
local tasks = {REMOTE_DEVICE, REMOTE_VERSION}
local currentTask = nil
local function clearAllTasks()
  for i, task in pairs(tasks) do
    task.state = STATE_READ
    if task.field ~= nil then
      task.field:value("Reading ...")
    end
  end
  supportFields = nil
  Product.resetProduct()
end

local pages = {{file = assert(loadfile(GlobalPath .. "basic/basic.lua")()), label = "Basic configure"},
               {
                 name = "Stabilizer group 1",
                 subPages = {
                   {file = assert(loadfile(GlobalPath .. "group1/precali1.lua")()), label = "Calibration"},
                   {file = assert(loadfile(GlobalPath .. "group1/stab1.lua")()), label = "Configuration"},}
                 },
               {
                 name = "Stabilizer group 2",
                 subPages = {
                   {file = assert(loadfile(GlobalPath .. "group2/precali2.lua")()), label = "Calibration"},
                   {file = assert(loadfile(GlobalPath .. "group2/stab2.lua")()), label = "Configuration"},}
                 },
               {file = assert(loadfile(GlobalPath .. "cali/cali.lua")()), label = "6-axis calibration"}}

local currentPage = nil

local function getPage(page)
  return page.file
end

local function buildpage()
  if supportFields == nil then
    return
  end

  for index, page in pairs(pages) do
    for i, supportField in pairs(supportFields) do
      if supportField == index then
        if page.name ~= nil then
          local line = form.addLine(page.name)
          local fieldLabels = {}
          for j, subPage in pairs(page.subPages) do
            fieldLabels[#fieldLabels + 1] = "_ "..subPage.label.." _"
          end
          local slots = form.getFieldSlots(line, fieldLabels)
          for j, subPage in pairs(page.subPages) do
            form.addTextButton(line, slots[j], subPage.label, function()
              form.clear()
              local backLine = form.addLine(page.name .. " " .. subPage.label)
              local rect = form.getFieldSlots(backLine, {nil})
              form.addTextButton(backLine, rect[1], "Back", function ()
                if currentPage ~= nil then
                  if getPage(currentPage).close ~= nil then
                    getPage(currentPage).close()
                  end
                  currentPage = nil
                  if createFunction ~= nil then
                    createFunction()
                  end
                  lcd.invalidate()
                  return true
                end
              end)
              currentPage = subPage
              if getPage(currentPage).pageInit ~= nil then
                getPage(currentPage).pageInit()
              end
            end)
          end

        else
          local line = form.addLine(page.label)
          form.addTextButton(line, nil, "Open", function()
            form.clear()
            local backLine = form.addLine(page.label)
            local rect = form.getFieldSlots(backLine, {nil})
            form.addTextButton(backLine, rect[1], "Back", function ()
              if currentPage ~= nil then
                if getPage(currentPage).close ~= nil then
                  getPage(currentPage).close()
                end
                currentPage = nil
                if createFunction ~= nil then
                  createFunction()
                end
                lcd.invalidate()
                return true
              end
            end)
            currentPage = page
            if getPage(currentPage).pageInit ~= nil then
              getPage(currentPage).pageInit()
            end
          end)
        end

        goto continue
      end
    end
    ::continue::
  end
end

local function checkNextTask()
  local allPass = true
  if TEST then
    supportFields = {1, 2, 3, 4}
    Product.family = 2
    Product.id = 79
  end

  for i, task in pairs(tasks) do
    if TEST then
      task.state = STATE_PASS
    end
    if task.state ~= STATE_PASS then
      allPass = false
    end
    if task.state < STATE_FINISHED then
      print("Current task address: ", task.address)
      finalTime = os.clock() + (MAX_TIMEOUT / #tasks)
      return task
    end
  end

  if allPass and supportFields ~= nil then
    buildpage()
  end
  print("All task finished")
  return nil
end

local function taskInit()
  print("Task init")
  clearAllTasks()
  currentTask = checkNextTask()
  nextOpTime = os.clock() + OPERATION_TIMEOUT
end

createFunction = function ()
  if TEST then
    print("Test mode enabled")
  end
  taskInit()

  form.clear()

  local line = form.addLine("Script version")
  form.addStaticText(line, nil, LUA_VERSION)

  for i, task in pairs(tasks) do
    line = form.addLine(task.label)
    task.field = form.addStaticText(line, nil, "Reading ...")
  end

  line = form.addLine("Module")
  form.addChoiceField(line, nil, {{"Internal", Module.INTERNAL_MODULE}, {"External", Module.EXTERNAL_MODULE}}, function() return Module.CurrentModule end, function(value)
    Sensor.setModule(value)
    taskInit()
  end)

  if TEST then
    buildpage()
  end
  return {}
end

local function wakeup()
  if currentPage ~= nil then
    if getPage(currentPage).wakeup ~= nil then
      getPage(currentPage).wakeup()
    end
  else
    if currentTask == nil then
      return
    end

    if currentTask.state == STATE_READ or os.clock() >= nextOpTime then
      if Sensor.requestParameter(currentTask.address) then
        print("sensor:requestParameter(), address: ", currentTask.address)
        currentTask.state = STATE_RECEIVE
        nextOpTime = os.clock() + OPERATION_TIMEOUT
      end

    elseif currentTask.state == STATE_RECEIVE then
      local value = Sensor.getParameter()
      if value == nil then
        return
      end

      print("Sensor.getParameter(): " .. value)
      if value & 0xFF ~= currentTask.address then
        return
      end

      currentTask.state = STATE_FINISHED
      currentTask.dataHandler(value, currentTask)
      currentTask = checkNextTask()
    end

    if os.clock() >= finalTime and currentTask ~= nil then
      print("Retries reached")
      currentTask.state = STATE_FINISHED
      if currentTask.field ~= nil then
        currentTask.field:value("Unable to read")
      end
      currentTask = checkNextTask()
    end
  end
end

local function paint()
  if currentPage ~= nil and getPage(currentPage).paint ~= nil then
    getPage(currentPage).paint()
  end
end

local function event(pagesData, category, value, x, y)
  if currentPage ~= nil and getPage(currentPage).event ~= nil then
    if getPage(currentPage).event(pagesData, category, value, x, y) then
      return true
    end
  end

  if category == EVT_KEY and value == KEY_EXIT_BREAK then
    if currentPage ~= nil then
      if getPage(currentPage).close ~= nil then
        getPage(currentPage).close()
      end
      currentPage = nil
      if createFunction ~= nil then
        createFunction()
      end
      lcd.invalidate()
      return true
    end
  end
end

local function close()
  currentPage = nil
end

local icon = lcd.loadBitmap("sc.png");

local function init()
  if system.registerDeviceConfig then
    system.registerDeviceConfig({category = DEVICE_CATEGORY_RECEIVERS, name = name, bitmap = icon, appIdStart = Sensor.APPID, appIdEnd = Sensor.APPID, version = LUA_VERSION, pages = { {name = name, create = createFunction, wakeup = wakeup, paint = paint, event = event, close = close} }})
  else
    system.registerSystemTool({name = name, icon = icon, create = createFunction, wakeup = wakeup, paint = paint, event = event, close = close})
  end
end

return { init = init }
