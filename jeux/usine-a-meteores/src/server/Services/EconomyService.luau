-- Argent, améliorations, rebirths, revenu passif et envoi de l'état au client.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Commun.Format)
local PassService = require(script.Parent.PassService)
local PlotService = require(script.Parent.PlotService)

local EconomyService = {}

local store -- PlayerData
local remotes: Folder
local dirty: { [Player]: boolean } = {}
local actionHandlers: { [string]: (Player, any) -> () } = {}
local stateExtras: { (Player, any, { [string]: any }) -> () } = {}
local multipliers: { (Player, any) -> number } = {}

-- Permet aux autres services d'ajouter un multiplicateur de gains (ex : familiers)
function EconomyService.registerMultiplier(fn: (Player, any) -> number)
	table.insert(multipliers, fn)
end

-- Permet aux autres services d'ajouter des actions client (ex : "claimGift")
function EconomyService.registerAction(name: string, handler: (Player, any) -> ())
	actionHandlers[name] = handler
end

-- Permet aux autres services d'ajouter des infos dans l'état envoyé au client
function EconomyService.registerStateExtra(fn: (Player, any, { [string]: any }) -> ())
	table.insert(stateExtras, fn)
end

-- Envoie une notification : le client la traduit lui-même dans sa langue (clé + valeurs)
function EconomyService.notify(player: Player, key: string, args: { any }?, kind: string?)
	remotes.Notify:FireClient(player, key, args or {}, kind or "info")
end

function EconomyService.data(player: Player)
	return store and store:get(player)
end

function EconomyService.boostRemaining(data): number
	return math.max(0, (data.boostUntil or 0) - os.time())
end

function EconomyService.multiplier(player: Player): number
	local data = EconomyService.data(player)
	if not data then
		return 1
	end
	local mult = Config.rebirthMultiplier(data.rebirths)
	if PassService.owns(player, "DoubleCash") then
		mult *= 2
	end
	if EconomyService.boostRemaining(data) > 0 then
		mult *= Config.Boost.multiplier
	end
	for _, fn in multipliers do
		mult *= fn(player, data)
	end
	return mult
end

local function updateLeaderstats(player: Player, data)
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		return
	end
	stats.Argent.Value = Format.number(data.cash)
	stats.Rebirths.Value = data.rebirths
end

function EconomyService.pushState(player: Player)
	dirty[player] = true
end

local function sendState(player: Player)
	local data = EconomyService.data(player)
	if not data then
		return
	end
	local state = {
		cash = data.cash,
		rebirths = data.rebirths,
		upgrades = data.upgrades,
		boostRemaining = EconomyService.boostRemaining(data),
		multiplier = EconomyService.multiplier(player),
		passiveIncome = Config.refineryIncome(data.upgrades.Refinery) * EconomyService.multiplier(player),
		passes = PassService.all(player),
		plotModel = (PlotService.get(player) or {}).model,
	}
	for _, extra in stateExtras do
		extra(player, data, state)
	end
	updateLeaderstats(player, data)
	remotes.State:FireClient(player, state)
end

-- Ajoute de l'argent (montant de base, les multiplicateurs sont appliqués ici). Renvoie le montant réel.
function EconomyService.earn(player: Player, base: number): number
	local data = EconomyService.data(player)
	if not data then
		return 0
	end
	local amount = math.floor(base * EconomyService.multiplier(player))
	data.cash += amount
	data.totalEarned += amount
	EconomyService.pushState(player)
	return amount
end

-- Ajoute de l'argent sans multiplicateur (achats Robux)
function EconomyService.grant(player: Player, amount: number)
	local data = EconomyService.data(player)
	if not data then
		return
	end
	data.cash += math.floor(amount)
	data.totalEarned += math.floor(amount)
	EconomyService.pushState(player)
end

function EconomyService.buyUpgrade(player: Player, key: string)
	local data = EconomyService.data(player)
	local upgrade = Config.Upgrades[key]
	if not data or not upgrade then
		return
	end
	local level = data.upgrades[key] or 0
	if level >= upgrade.max then
		return
	end
	local cost = Config.upgradeCost(key, level)
	if data.cash < cost then
		return
	end
	data.cash -= cost
	data.upgrades[key] = level + 1
	local plot = PlotService.get(player)
	if plot then
		PlotService.updateVisuals(plot, data)
	end
	EconomyService.pushState(player)
end

function EconomyService.rebirth(player: Player)
	local data = EconomyService.data(player)
	if not data then
		return
	end
	local cost = Config.rebirthCost(data.rebirths)
	if data.cash < cost then
		return
	end
	data.rebirths += 1
	data.cash = 0
	for key in data.upgrades do
		data.upgrades[key] = 0
	end
	local plot = PlotService.get(player)
	if plot then
		PlotService.updateVisuals(plot, data)
		plot.meteors:ClearAllChildren()
	end
	remotes.Announce:FireAllClients("msg_rebirth", { player.DisplayName, data.rebirths }, "rebirth")
	EconomyService.pushState(player)
end

function EconomyService.addBoost(player: Player, seconds: number)
	local data = EconomyService.data(player)
	if not data then
		return
	end
	data.boostUntil = math.max(data.boostUntil or 0, os.time()) + seconds
	EconomyService.pushState(player)
end

function EconomyService.setupPlayer(player: Player, data)
	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Argent"
	cash.Parent = stats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = stats
	stats.Parent = player
	updateLeaderstats(player, data)
	EconomyService.pushState(player)
end

function EconomyService.init(playerData, remoteFolder: Folder)
	store = playerData
	remotes = remoteFolder

	-- Actions envoyées par le client (avec limite anti-spam)
	local lastActions: { [Player]: { number } } = {}
	remotes.Action.OnServerEvent:Connect(function(player, action, arg)
		local now = os.clock()
		local history = lastActions[player] or {}
		lastActions[player] = history
		while history[1] and now - history[1] > 1 do
			table.remove(history, 1)
		end
		if #history >= 15 then
			return
		end
		table.insert(history, now)

		if action == "upgrade" and typeof(arg) == "string" then
			EconomyService.buyUpgrade(player, arg)
		elseif action == "rebirth" then
			EconomyService.rebirth(player)
		elseif typeof(action) == "string" and actionHandlers[action] then
			actionHandlers[action](player, arg)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		lastActions[player] = nil
		dirty[player] = nil
	end)

	PassService.Changed:Connect(function(player)
		EconomyService.pushState(player)
	end)

	-- Revenu passif de la raffinerie, chaque seconde
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local data = EconomyService.data(player)
				if data then
					local income = Config.refineryIncome(data.upgrades.Refinery)
					if income > 0 then
						EconomyService.earn(player, income)
					end
					-- Renvoie aussi l'état quand le boost se termine
					if data.boostUntil > 0 and EconomyService.boostRemaining(data) == 0 then
						data.boostUntil = 0
						EconomyService.pushState(player)
					end
				end
			end
		end
	end)

	-- Envoi groupé de l'état (au plus 5 fois par seconde par joueur)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local toSend = dirty
			dirty = {}
			for player in toSend do
				if player.Parent then
					sendState(player)
				end
			end
		end
	end)
end

return EconomyService
