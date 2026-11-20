-- Petit moteur de traduction réutilisable par tous les jeux.
-- Usage :
--   local i18n = I18n.new(require(ReplicatedStorage.Shared.Lang), "en")
--   i18n:get(player.LocaleId, "msg_rebirth", { "Bob", 3 })  --> "Bob did rebirth #3!"
-- Les textes utilisent {1}, {2}… pour les valeurs à insérer.
local I18n = {}
I18n.__index = I18n

function I18n.new(languages: { [string]: { [string]: string } }, fallback: string)
	return setmetatable({ languages = languages, fallback = fallback }, I18n)
end

-- "fr-fr" -> "fr", "pt-br" -> "pt", "zh-cn" -> "zh-cn" si cette langue existe, sinon "zh"
function I18n:resolve(localeId: string?): string
	local id = string.lower(localeId or "")
	if self.languages[id] then
		return id
	end
	local prefix = string.match(id, "^(%a+)")
	if prefix and self.languages[prefix] then
		return prefix
	end
	return self.fallback
end

function I18n:get(localeId: string?, key: string, args: { any }?): string
	local lang = self.languages[self:resolve(localeId)]
	local text = (lang and lang[key]) or self.languages[self.fallback][key] or key
	if args then
		text = string.gsub(text, "{(%d+)}", function(i)
			local value = args[tonumber(i)]
			return if value == nil then "" else tostring(value)
		end)
	end
	return text
end

return I18n
