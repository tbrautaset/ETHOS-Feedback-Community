local CALIBRATION_ADDRESS = 0xB2
local CALIBRATION_INIT = 0
local CALIBRATION_WRITE = 1
local CALIBRATION_READ = 2
local CALIBRATION_WAIT = 3
local CALIBRATION_OK = 4

local step = 0
local bitmap
local nextStep = false
local calibrationState = CALIBRATION_INIT
local OPERATION_TIMEOUT = 3 -- Second(s)
local nextOpTime

local caliButton = nil

local CALI_LABELS = {
  "Place your Stabilizer Rx horizontal, top side up.",
  "Place your Stabilizer Rx horizontal, top side down.",
  "Place your Stabilizer Rx vertical, pins up.",
  "Place your Stabilizer Rx vertical, pins down.",
  "Place your Stabilizer Rx with label facing you, pins right.",
  "Place your Stabilizer Rx with label facing you, pins left.",
  "Calibration finished. You can exit this page now"
}

local function doCalibrate()
  local button = {{label = "Close", action = function ()
    Dialog.closeDialog()
  end}}

  calibrationState = CALIBRATION_WRITE
  Dialog.openDialog({title = "Calibrating", message = "Please wait until calibration finished ...\n", buttons = button, wakeup = function ()
    if calibrationState == CALIBRATION_WRITE then
      if Sensor.writeParameter(CALIBRATION_ADDRESS, step) == true then
        print("Sensor.writeParameter(), step: " .. step)
        calibrationState = CALIBRATION_READ
      end

    elseif calibrationState == CALIBRATION_READ then
      if Sensor.requestParameter(CALIBRATION_ADDRESS) == true then
        print("Sensor.requestParameter()")
        calibrationState = CALIBRATION_WAIT
        nextOpTime = os.clock() + OPERATION_TIMEOUT
      end

    elseif calibrationState == CALIBRATION_WAIT then
      local value = Sensor.getParameter()
      if value then
        print("Sensor.getParameter(): " .. value)
        local fieldId = value % 256
        if fieldId == CALIBRATION_ADDRESS then
          if step == 5 then
            calibrationState = CALIBRATION_OK
            step = 6
            print("Cali finished")
            if caliButton ~= nil then
              caliButton:enable(false)
            end
            nextStep = true
          else
            calibrationState = CALIBRATION_INIT
            step = (step + 1) % 6
            print("Cali success. Next step")
            nextStep = true
          end
        end
      elseif os.clock() >= nextOpTime then
        calibrationState = CALIBRATION_WRITE
      end
    end
  end})
end

local function pageInit()
  step = 0
  calibrationState = CALIBRATION_INIT

  local line = form.addLine("", nil, false)
  caliButton = form.addTextButton(line, nil, "Calibrate", function() doCalibrate() end)

  bitmap = lcd.loadBitmap("cali/cali_"..step..".png")
end

local function paint()
  local width, height = lcd.getWindowSize()

  lcd.color(lcd.GREY(0xFF))
  local tw, th = lcd.getTextSize(CALI_LABELS[step + 1])
  lcd.drawText(width / 2, height / 3, CALI_LABELS[step + 1], CENTERED)
  if step < 6 or calibrationState ~= CALIBRATION_OK then
    lcd.drawText(width / 2, height / 3 + th, "Press \"Calibrate\" button to start", CENTERED)
  end

  if bitmap ~= nil then
    local w = bitmap:width()
    local h = bitmap:height()
    local x = width / 2 - w / 2
    local y = height / 3 * 2 - h / 2
    lcd.drawBitmap(x, y, bitmap)
  end
end

local function wakeup()
  if nextStep then
    if step < 6 then
      bitmap = lcd.loadBitmap("cali/cali_"..step..".png")
      Dialog.closeDialog()
    else
      bitmap = lcd.loadBitmap("cali/cali_ok.png")
      Dialog.message("Calibration finished!")
    end
    nextStep = false
    lcd.invalidate()
  end
end

return {pageInit = pageInit, paint = paint, wakeup = wakeup}
