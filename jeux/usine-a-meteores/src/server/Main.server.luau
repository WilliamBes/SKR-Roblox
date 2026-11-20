-- Point d'entrée du serveur : crée les remotes, charge les données et démarre les services.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage.Shared.Config)
local PlayerData = require(ServerScriptService.Commun.PlayerData)

local Services = script.Parent.Services
local PlotService = require(Services.PlotService)
local PassService = require(Services.PassService)
local EconomyService = require(Services.EconomyService)
local MeteorService = require(Services.MeteorService)
local ShopService = require(Services.ShopService)
local RewardService = require(Services.RewardService)
local LeaderboardService = require(Services.LeaderboardService)

-- Remotes (communication serveur <-> client)
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in { "State", "Action", "Collected", "Impact", "Announce", "Notify" } do
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
}
for key in Config.Upgrades do
	template.upgrades[key] = 0
end

PlotService.init()
PassService.init()

-- Le jeu doit être prêt avant de charger les joueurs
local store
local function onLoaded(player: Player, data)
	PassService.load(player)
	if player.Parent == nil then
		return
	end
	local plot = PlotService.assign(player)
	if not plot then
		player:Kick("Le serveur est plein, rejoins-en un autre !")
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
	EconomyService.setupPlayer(player, data)
end

store = PlayerData.new(Config.DataStoreName, template)
EconomyService.init(store, remotes)
MeteorService.init(remotes)
ShopService.init(store)
RewardService.init()
LeaderboardService.init(store)
store.Loaded:Connect(onLoaded)

-- Les joueurs déjà chargés avant la connexion (rare, surtout en test)
for _, player in Players:GetPlayers() do
	local data = store:get(player)
	if data and not PlotService.get(player) then
		task.spawn(onLoaded, player, data)
	end
end
