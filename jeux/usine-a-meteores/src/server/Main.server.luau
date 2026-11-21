-- Point d'entrée du serveur : crée les remotes, charge les données et démarre les services.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ServerScriptService.Commun.PlayerData)
local T = require(ReplicatedStorage.Shared.T)

local Services = script.Parent.Services
local PlotService = require(Services.PlotService)
local PassService = require(Services.PassService)
local EconomyService = require(Services.EconomyService)
local MeteorService = require(Services.MeteorService)
local ShopService = require(Services.ShopService)
local RewardService = require(Services.RewardService)
local LeaderboardService = require(Services.LeaderboardService)
local PetService = require(Services.PetService)

-- Remotes (communication serveur <-> client)
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "State", "Action", "Collected", "Impact", "Announce", "Notify", "Hatched", "WorldUnlocked" } do
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = remotes
end
remotes.Parent = ReplicatedStorage

local template = {
	cash = 0,
	totalEarned = 0,
	rebirths = 0,
	upgrades = {},
	boostUntil = 0,
	purchases = {},
	robuxSpent = 0,
	meteorsCollected = 0,
	questIndex = 1,
	lastDaily = 0,
	dailyStreak = 0,
	codesUsed = {},
	pets = {},
}
for key in Config.Upgrades do
	template.upgrades[key] = 0
end

PlotService.init()
PassService.init()

-- Le jeu doit être prêt avant de charger les joueurs
local store
local function onLoaded(player: Player, data)
	-- Mode test (Studio seulement)
	if RunService:IsStudio() then
		data.cash = math.max(data.cash, Config.Studio.minCash)
		data.rebirths = math.max(data.rebirths, Config.Studio.minRebirths)
	end
	PassService.load(player)
	if player.Parent == nil then
		return
	end
	local plot = PlotService.assign(player)
	if not plot then
		player:Kick(T:get(player.LocaleId, "kick_full"))
		return
	end
	PlotService.updateVisuals(plot, data)

	local function placeCharacter(character: Model)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if root and plot.owner == player then
			task.wait() -- laisse Roblox finir de placer le personnage
			character:PivotTo(PlotService.spawnCFrame(plot))
		end
	end
	player.CharacterAdded:Connect(placeCharacter)
	if player.Character then
		task.spawn(placeCharacter, player.Character)
	end

	RewardService.setupPlayer(player)
	PetService.setupPlayer(player, data)
	EconomyService.setupPlayer(player, data)
end

local testMode = RunService:IsStudio() and (Config.Studio.minCash > 0 or Config.Studio.minRebirths > 0)
store = PlayerData.new(Config.DataStoreName, template, {
	noSave = testMode, -- en mode test, rien n'est sauvegardé
	kickMessage = function(player: Player)
		return T:get(player.LocaleId, "kick_data")
	end,
})
EconomyService.init(store, remotes)
MeteorService.init(remotes)
ShopService.init(store)
RewardService.init()
PetService.init(remotes)
LeaderboardService.init(store)
store.Loaded:Connect(onLoaded)

-- Les joueurs déjà chargés avant la connexion (rare, surtout en test)
for _, player in Players:GetPlayers() do
	local data = store:get(player)
	if data and not PlotService.get(player) then
		task.spawn(onLoaded, player, data)
	end
end
