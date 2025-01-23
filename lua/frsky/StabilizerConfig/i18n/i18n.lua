local locale = system.getLocale()
print("Get system language flag: ", locale)

local I18nMap = {
  en = assert(loadfile(GlobalPath .. "i18n/en.lua"))(),
}

local function translate(key, paramTable)
  local map = I18nMap[locale] or I18nMap['en']
  local string = map[key] or I18nMap['en'][key]
  if paramTable ~= nil and type(paramTable) == 'table' then
    string = string:gsub("{{%s*(%w+)%s*}}", function(key)
      return tostring(paramTable[key] or "")
    end)
  end
  return string
end

return { translate = translate }
