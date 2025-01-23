local locale = system.getLocale()

local I18nMap = {
  en = assert(loadfile(GlobalPath .. "i18n/en.lua"))(),
}

local function translate(key, paramTable)
  local map = I18nMap[locale] or I18nMap['en']
  local string = map[key]
  return string or I18nMap['en'][key]
end

return { translate = translate }
