local locale = system.getLocale()
print("Get system language flag: ", locale)

local I18nMap = {
  cs = assert(loadfile(GlobalPath .. "i18n/cs.lua"))(),
  de = assert(loadfile(GlobalPath .. "i18n/de.lua"))(),
  en = assert(loadfile(GlobalPath .. "i18n/en.lua"))(),
  es = assert(loadfile(GlobalPath .. "i18n/es.lua"))(),
  fr = assert(loadfile(GlobalPath .. "i18n/fr.lua"))(),
  it = assert(loadfile(GlobalPath .. "i18n/it.lua"))(),
  nl = assert(loadfile(GlobalPath .. "i18n/nl.lua"))(),
  no = assert(loadfile(GlobalPath .. "i18n/no.lua"))(),
  pb = assert(loadfile(GlobalPath .. "i18n/pb.lua"))(),
  pl = assert(loadfile(GlobalPath .. "i18n/pl.lua"))(),
  pt = assert(loadfile(GlobalPath .. "i18n/pt.lua"))(),
}

local function translate(key, paramTable)
  local map = I18nMap[locale] or I18nMap['en']
  local string = map[key] or I18nMap['en'][key]
  if paramTable ~= nil and type(paramTable) == 'table' then
    string = string:gsub("{{%s*(%w+)%s*}}", function(replacement)
      return tostring(paramTable[replacement] or "")
    end)
  end
  return string
end

return { translate = translate }
