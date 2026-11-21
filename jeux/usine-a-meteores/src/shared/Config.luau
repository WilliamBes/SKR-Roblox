-- Tous les réglages du jeu. Pour équilibrer l'économie, c'est ici qu'il faut toucher.
local Config = {}

Config.DataStoreName = "UsineAMeteores_v1"

-- Mode test : UNIQUEMENT dans Roblox Studio (jamais dans le vrai jeu), donne de l'argent de départ
-- et des rebirths pour tester vite les œufs, les mondes et la boutique. Mets 0 pour désactiver.
Config.Studio = { minCash = 0, minRebirths = 0 }

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

Config.Rebirth = { baseCost = 400000, growth = 2.5, bonusPerRebirth = 0.75 }

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

-- Objectifs du tutoriel, dans l'ordre. type : collect, upgrade, earned, rebirth
Config.Quests = {
	{ text = "Marche sur les météores pour en ramasser 10", type = "collect", target = 10, reward = 60 },
	{ text = "Achète l'amélioration Valeur", type = "upgrade", key = "MeteorValue", target = 1, reward = 80 },
	{ text = "Achète l'amélioration Fréquence", type = "upgrade", key = "SpawnRate", target = 1, reward = 120 },
	{ text = "Construis ta Raffinerie", type = "upgrade", key = "Refinery", target = 1, reward = 250 },
	{ text = "Ramasse 150 météores", type = "collect", target = 150, reward = 800 },
	{ text = "Monte la Valeur au niveau 10", type = "upgrade", key = "MeteorValue", target = 10, reward = 2500 },
	{ text = "Gagne 25K $ au total", type = "earned", target = 25000, reward = 5000 },
	{ text = "Fais ton premier rebirth", type = "rebirth", target = 1, reward = 10000 },
}

-- Cadeaux de temps de jeu (minutes depuis l'arrivée sur le serveur) et valeur en minutes de revenu
Config.Gifts = {
	{ minutes = 3, incomeMinutes = 2 },
	{ minutes = 8, incomeMinutes = 4 },
	{ minutes = 15, incomeMinutes = 6, boostSeconds = 120 },
	{ minutes = 25, incomeMinutes = 10 },
	{ minutes = 40, incomeMinutes = 15, boostSeconds = 300 },
}
Config.GiftMinimum = 150

-- Récompense quotidienne : minutes de revenu par jour de série (le jour 7 et plus donne le maximum)
Config.Daily = { incomeMinutesPerDay = 3, maxStreak = 7, minimum = 300 }

-- Codes promo (en MAJUSCULES). cash = argent fixe, incomeMinutes = minutes de revenu, boostSeconds = boost x3
Config.Codes = {
	LANCEMENT = { incomeMinutes = 5, boostSeconds = 300 },
	METEORE = { cash = 1000 },
}

-- Sons. Les rbxasset:// sont fournis avec Roblox ; tu peux les remplacer par des ID du Creator Store
-- (onglet Toolbox > Audio) au format "rbxassetid://123456".
Config.Sounds = {
	collect = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.35 },
	impact = { id = "rbxasset://sounds/collide.wav", volume = 0.5 },
	buy = { id = "rbxasset://sounds/button.wav", volume = 0.6 },
	reward = { id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.8, pitch = 0.7 },
}

-- Couleur de la bordure de l'usine selon le nombre de rebirths
Config.RebirthColors = {
	Color3.fromRGB(255, 120, 40),
	Color3.fromRGB(60, 200, 255),
	Color3.fromRGB(150, 70, 230),
	Color3.fromRGB(70, 220, 110),
	Color3.fromRGB(255, 60, 90),
	Color3.fromRGB(255, 220, 50),
}

Config.Leaderboard = { refreshSeconds = 120, size = 10 }

-- Familiers : ils restent après un rebirth et donnent un bonus de gains (les meilleurs sont actifs)
Config.PetSlots = 3
Config.Pets = {
	Comet = { bonus = 0.10, color = Color3.fromRGB(255, 150, 60), size = 1.6 },
	Moonling = { bonus = 0.25, color = Color3.fromRGB(120, 200, 255), size = 1.8 },
	Nova = { bonus = 0.60, color = Color3.fromRGB(190, 110, 255), size = 2.0 },
	Phoenix = { bonus = 1.50, color = Color3.fromRGB(255, 80, 60), size = 2.4 },
}
Config.PetOrder = { "Comet", "Moonling", "Nova", "Phoenix" }
-- Poids de tirage : plus le nombre est grand, plus le familier est fréquent
Config.Eggs = {
	Basic = { cost = 20000, weights = { Comet = 70, Moonling = 26, Nova = 4 } },
	Cosmic = { cost = 2000000, weights = { Moonling = 55, Nova = 38, Phoenix = 7 } },
}
Config.EggOrder = { "Basic", "Cosmic" }

function Config.petBonus(pets: { [string]: number }): number
	local bonuses = {}
	for key, count in pets do
		local pet = Config.Pets[key]
		if pet then
			for _ = 1, count do
				table.insert(bonuses, pet.bonus)
			end
		end
	end
	table.sort(bonuses, function(a, b)
		return a > b
	end)
	local total = 0
	for i = 1, math.min(Config.PetSlots, #bonuses) do
		total += bonuses[i]
	end
	return total
end

-- Liste des familiers actifs (les meilleurs), du plus fort au plus faible
function Config.equippedPets(pets: { [string]: number }): { string }
	local list = {}
	for key, count in pets do
		if Config.Pets[key] then
			for _ = 1, count do
				table.insert(list, key)
			end
		end
	end
	table.sort(list, function(a, b)
		return Config.Pets[a].bonus > Config.Pets[b].bonus
	end)
	while #list > Config.PetSlots do
		table.remove(list)
	end
	return list
end

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

-- Mondes : le monde le plus avancé débloqué grâce aux rebirths est actif automatiquement.
-- Chaque monde multiplie tous les gains et change l'apparence de l'usine.
Config.Worlds = {
	{ key = "Plains", rebirths = 0, mult = 1, base = Color3.fromRGB(45, 42, 58), material = Enum.Material.Slate },
	{ key = "Frost", rebirths = 4, mult = 2, base = Color3.fromRGB(150, 205, 235), material = Enum.Material.Ice },
	{ key = "Magma", rebirths = 8, mult = 3.5, base = Color3.fromRGB(95, 32, 22), material = Enum.Material.Basalt },
	{ key = "Void", rebirths = 12, mult = 6, base = Color3.fromRGB(28, 16, 55), material = Enum.Material.SmoothPlastic },
}

function Config.worldIndex(rebirths: number): number
	local index = 1
	for i, world in Config.Worlds do
		if rebirths >= world.rebirths then
			index = i
		end
	end
	return index
end

function Config.rebirthMultiplier(rebirths: number): number
	return (1 + rebirths * Config.Rebirth.bonusPerRebirth) * Config.Worlds[Config.worldIndex(rebirths)].mult
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

-- Récompense = X minutes de revenu estimé (avec le bonus de rebirth), avec un minimum
function Config.incomeReward(data, minutes: number, minimum: number): number
	local perSecond = Config.estimatedIncome(data.upgrades) * Config.rebirthMultiplier(data.rebirths)
	return math.floor(math.max(minimum, perSecond * 60 * minutes))
end

return Config
