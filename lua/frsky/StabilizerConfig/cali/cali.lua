local CALIBRATION_ADDRESS = 0xB2
local CALIBRATION_INIT = 0
local CALIBRATION_WRITE = 1
local CALIBRATION_READ = 2
local CALIBRATION_WAIT = 3
local CALIBRATION_OK = 4

local GYRO_MODE_CHECK_REQUEST = 0
local GYRO_MODE_CHECK_RESPONSE = 1
local GYRO_MODE_CHECK_PASS = 2
local GYRO_MODE_CHECK_REJECT = 3
local gyroModeCheck = GYRO_MODE_CHECK_REQUEST
local GYRO_MODE_CHECK_DETAIL = {address = 0xA4, passFunction = function(value4Bytes) return ((value4Bytes >> 8) & 0xFF) > 0  end}

local step = 0
local bitmap
local nextStep = false
local calibrationState = CALIBRATION_INIT
local OPERATION_TIMEOUT = 3 -- Second(s)
local nextOpTime

local caliButton = nil

local function isSR6Mini()
  return Product.family and Product.family == 2 and Product.id and (Product.id == 79 or Product.id == 80)
end

local SR6_CALI_LABELS = {
  "Place your SR6 horizontal, top side up.",
  "Place your SR6 horizontal, top side down.",
  "Place your SR6 vertical, ANT down.",
  "Place your SR6 vertical, ANT up.",
  "Place your SR6 with ANT right, top side facing you.",
  "Place your SR6 with ANT right, back side facing you.",
  "Calibration finished. You can exit this page now"
}

local CALI_LABELS = {
  "Place your Stabilizer Rx horizontal with the front facing up.",
  "Place your Stabilizer Rx horizontal with the back facing up.",
  "Place your Stabilizer Rx vertical with the label tilted to the left.",
  "Place your Stabilizer Rx vertical with the label tilted to the right.",
  "Place your Stabilizer Rx vertical with the label displayed upright.",
  "Place your Stabilizer Rx vertical with the label displayed upside down.",
  "Calibration finished. You can exit this page now"
}

local function getCaliBitmapPath()
  if isSR6Mini() then
    return GlobalPath .. "cali/cali_sr6_" .. step .. ".png"
  else
    return GlobalPath .. "cali/cali_" .. step .. ".png"
  end
end

local function getCaliLabel()
  if gyroModeCheck <= GYRO_MODE_CHECK_RESPONSE then
    return "Checking gyro mode ..."
  elseif gyroModeCheck == GYRO_MODE_CHECK_REJECT then
    return "Gyro mode not enable!"
  elseif isSR6Mini() then
    return SR6_CALI_LABELS[step + 1]
  else
    return CALI_LABELS[step + 1]
  end
end

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
  gyroModeCheck = GYRO_MODE_CHECK_REQUEST

  local line = form.addLine("", nil, false)
  caliButton = form.addTextButton(line, nil, "Calibrate", function() doCalibrate() end)
  caliButton:enable(false)

  bitmap = lcd.loadBitmap(getCaliBitmapPath())
end

local function paint()
  local width, height = lcd.getWindowSize()

  lcd.color(lcd.GREY(0xFF))
  local tw, th = lcd.getTextSize(getCaliLabel())
  lcd.drawText(width / 2, height / 3, getCaliLabel(), CENTERED)
  if gyroModeCheck == GYRO_MODE_CHECK_PASS and (step < 6 or calibrationState ~= CALIBRATION_OK) then
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
  if gyroModeCheck == GYRO_MODE_CHECK_REQUEST then
    if Sensor.requestParameter(GYRO_MODE_CHECK_DETAIL.address) then
      gyroModeCheck = GYRO_MODE_CHECK_RESPONSE
      nextOpTime = os.clock() + OPERATION_TIMEOUT
    end
  elseif gyroModeCheck == GYRO_MODE_CHECK_RESPONSE then
    local value = Sensor.getParameter()
    if value and value % 256 == GYRO_MODE_CHECK_DETAIL.address then
      if GYRO_MODE_CHECK_DETAIL.passFunction(value) then
        gyroModeCheck = GYRO_MODE_CHECK_PASS
        if caliButton ~= nil then
          caliButton:enable(true)
        end
      else
        gyroModeCheck = GYRO_MODE_CHECK_REJECT
      end
      lcd.invalidate()
    elseif os.clock() >= nextOpTime then
      gyroModeCheck = GYRO_MODE_CHECK_REQUEST
    end
  elseif nextStep then
    if step < 6 then
      bitmap = lcd.loadBitmap(getCaliBitmapPath())
      Dialog.closeDialog()
    else
      bitmap = lcd.loadBitmap(GlobalPath .. "cali/cali_ok.png")
      Dialog.message("Calibration finished!")
    end
    nextStep = false
    lcd.invalidate()
  end
end

return {pageInit = pageInit, paint = paint, wakeup = wakeup}
