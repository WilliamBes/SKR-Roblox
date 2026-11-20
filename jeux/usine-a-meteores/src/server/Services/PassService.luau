-- Vérifie quels game passes chaque joueur possède (avec cache).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local PassService = {}

local owned: { [Player]: { [string]: boolean } } = {}
local changedEvent = Instance.new("BindableEvent")
PassService.Changed = changedEvent.Event -- (player, passKey)

local function check(player: Player, key: string): boolean
	local id = Config.GamePasses[key].id
	if id == 0 then
		return false
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
	end)
	return ok and result == true
end

function PassService.load(player: Player)
	local passes = {}
	owned[player] = passes
	for key in Config.GamePasses do
		passes[key] = check(player, key)
	end
end

function PassService.owns(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

function PassService.all(player: Player): { [string]: boolean }
	return owned[player] or {}
end

function PassService.init()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased or not owned[player] then
			return
		end
		for key, pass in Config.GamePasses do
			if pass.id == passId then
				owned[player][key] = true
				changedEvent:Fire(player, key)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
	end)
end

return PassService
