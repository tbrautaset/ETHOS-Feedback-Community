local locale = system.getLocale()

I18nMap = {
  en = {
    ScriptName = "Stabilizer config",
    ScriptVersion = "Script version",
    RemoteDevice = "Remote device",
    RemoteVersion = "Remote version",
    UnsupportDevice = "Unsupport device",
    UncompitableVersion = "Uncompitable version",
    Reading = "Reading ...",
    UnableToRead = "Unable to read",

    Module = "Module",
    Internal = "Internal",
    External = "External",

    BasicConfig = "Basic configure",
    StabilizerGroup1 = "Stabilizer group 1",
    StabilizerGroup2 = "Stabilizer group 2",
    SixAxisCali = "6-axis calibration",
    Calibration = "Calibration",
    Configuration = "Configuration",

    Back = "Back",
    Open = "Open",

    OK = "OK",
    Load = "Load",
    Save = "Save",
    LoadFailed = "Load failed",
    SaveFailed = "Save failed",
    ReadSettingsFirstly = "Please read the settings firstly!",
    NoFileSelected = "No file selected",
    SelectFileFirstly = "Please select the file you\nwant to load the configures from!",
    FileReadError = "File read error!",
    ConfigurationLoaded = "Configuration loaded",
    ConfigFileLoaded = "Configure has been loaded from\n",
    CannotSaveToFile = "Cannot save to file!",
    configurationSaved = "ConfigurationSaved",
    ConfigSaveToFile = "Configure has been saved into\n",
    FSError = "File operation error!",

    GyroMode = "Gyro mode",
    Off = "Off",
    Basic = "Basic",
    ADV = "ADV",

    ADVConfig = "ADV config",
    Disable = "Disable",
    Enable = "Enable",
  }
}

local function translate(key)
  local map = I18nMap[locale] or I18nMap['en']
  local string = map[key]
  return string or I18nMap['en'][key]
end

return { translate = translate }
