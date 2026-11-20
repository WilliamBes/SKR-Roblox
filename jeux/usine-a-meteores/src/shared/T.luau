-- Accès aux traductions : T:get(player.LocaleId, "clé", { valeurs })
-- Sur le client, utilise T:get(Players.LocalPlayer.LocaleId, ...) ou T.local_
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local I18n = require(ReplicatedStorage.Commun.I18n)
local Lang = require(script.Parent.Lang)

return I18n.new(Lang, "en")
