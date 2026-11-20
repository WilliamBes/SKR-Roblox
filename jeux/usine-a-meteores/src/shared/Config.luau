-- Tous les réglages du jeu. Pour équilibrer l'économie, c'est ici qu'il faut toucher.
local Config = {}

Config.DataStoreName = "UsineAMeteores_v1"

-- Remplace les 0 par les ID créés dans le Creator Dashboard (Monétisation).
-- Un ID à 0 affiche « Bientôt » dans la boutique.
Config.GamePasses = {
	DoubleCash = { id = 0, name = "Argent x2", description = "Double tout l'argent gagné, pour toujours." },
	AutoCollect = { id = 0, name = "Ramassage auto", description = "Les météores sont ramassés dès qu'ils touchent le sol." },
	LuckyMeteors = { id = 0, name = "Météores chanceux", description = "Trois fois plus de météores rares et légendaires." },
}
Config.GamePassOrder = { "DoubleCash", "AutoCollect", "LuckyMeteors" }

Config.Products = {
	Boost = { id = 0, name = "Boost x3 (5 min)", description = "Triple tes gains pendant 5 minutes. Se cumule." },
	CashPack = { id = 0, name = "Pluie d'argent", description = "Reçois l'équivalent de 15 minutes de revenus." },
	MeteorShower = { id = 0, name = "Pluie de météores", description = "Fait tomber 30 météores dont au moins 3 légendaires sur ton usine." },
}
Config.ProductOrder = { "Boost", "CashPack", "MeteorShower" }

Config.Boost = { multiplier = 3, duration = 300 }
Config.CashPackMinutes = 15

Config.Upgrades = {
	SpawnRate = { name = "Fréquence", description = "Les météores tombent plus souvent.", baseCost = 40, growth = 1.55, max = 25 },
	MeteorValue = { name = "Valeur", description = "Chaque météore rapporte plus.", baseCost = 25, growth = 1.45, max = 100 },
	Refinery = { name = "Raffinerie", description = "Revenu passif chaque seconde.", baseCost = 150, growth = 1.6, max = 100 },
	Magnet = { name = "Aimant", description = "Ramasse les météores de plus loin.", baseCost = 300, growth = 2.2, max = 10 },
}
Config.UpgradeOrder = { "MeteorValue", "SpawnRate", "Refinery", "Magnet" }

Config.Rebirth = { baseCost = 25000, growth = 4, bonusPerRebirth = 0.5 }

Config.Meteor = {
	baseInterval = 2.5, -- secondes entre deux météores au niveau 0
	minInterval = 0.35,
	baseValue = 5,
	lifetime = 25, -- secondes avant qu'un météore au sol ne disparaisse
	maxOnPlot = 30,
	fallHeight = 140,
	fallTime = 1.1,
}

-- Raretés : chance de base (sur 1), multiplicateur de valeur, apparence
Config.Rarities = {
	{ key = "Commun", chance = 0.86, multiplier = 1, color = Color3.fromRGB(255, 120, 40), size = 3 },
	{ key = "Rare", chance = 0.12, multiplier = 6, color = Color3.fromRGB(60, 200, 255), size = 4 },
	{ key = "Légendaire", chance = 0.02, multiplier = 40, color = Color3.fromRGB(255, 220, 50), size = 5.5 },
}
Config.LuckyMultiplier = 3

Config.Plot = { count = 6, size = 72, ringRadius = 110 }

function Config.upgradeCost(key: string, level: number): number
	local u = Config.Upgrades[key]
	return math.floor(u.baseCost * u.growth ^ level)
end

function Config.meteorInterval(level: number): number
	return math.max(Config.Meteor.minInterval, Config.Meteor.baseInterval * 0.9 ^ level)
end

function Config.meteorValue(level: number): number
	return math.floor(Config.Meteor.baseValue * (1 + level) * 1.12 ^ level)
end

function Config.refineryIncome(level: number): number
	if level <= 0 then
		return 0
	end
	return math.floor(2 * level * 1.17 ^ level)
end

function Config.magnetRadius(level: number): number
	return 8 + level * 3
end

function Config.rebirthCost(rebirths: number): number
	return math.floor(Config.Rebirth.baseCost * Config.Rebirth.growth ^ rebirths)
end

function Config.rebirthMultiplier(rebirths: number): number
	return 1 + rebirths * Config.Rebirth.bonusPerRebirth
end

-- Revenu moyen estimé par seconde (sans multiplicateurs), utilisé pour la Pluie d'argent
function Config.estimatedIncome(upgrades): number
	local meteorsPerSecond = 1 / Config.meteorInterval(upgrades.SpawnRate or 0)
	local averageRarity = 0
	for _, r in Config.Rarities do
		averageRarity += r.chance * r.multiplier
	end
	return Config.meteorValue(upgrades.MeteorValue or 0) * averageRarity * meteorsPerSecond
		+ Config.refineryIncome(upgrades.Refinery or 0)
end

return Config
