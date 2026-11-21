-- Sauvegarde générique des joueurs (DataStore), réutilisable par tous les jeux.
-- Usage :
--   local PlayerData = require(ServerScriptService.Commun.PlayerData)
--   local store = PlayerData.new("MonJeu_v1", modeleParDefaut)
--   store.Loaded:Connect(function(player, data) ... end)
--   store:get(player) -> table des données (ou nil si pas encore chargé)
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AUTOSAVE_INTERVAL = 60

local PlayerData = {}
PlayerData.__index = PlayerData

local function deepCopy(value)
	if typeof(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in value do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- Ajoute les champs manquants (utile quand on ajoute une nouvelle stat après la sortie du jeu)
local function reconcile(data, template)
	for k, v in template do
		if data[k] == nil then
			data[k] = deepCopy(v)
		elseif typeof(v) == "table" and typeof(data[k]) == "table" and next(v) ~= nil then
			reconcile(data[k], v)
		end
	end
end

local function withRetries(label: string, fn: () -> any): (boolean, any)
	for attempt = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn(string.format("[PlayerData] %s a échoué (essai %d) : %s", label, attempt, tostring(result)))
		if attempt < 3 then
			task.wait(attempt * 2)
		end
	end
	return false, nil
end

-- options.noSave : n'écrit rien dans le DataStore (mode test : évite de polluer ta vraie sauvegarde)
-- options.kickMessage(player) : texte affiché si les données ne peuvent pas être chargées (traduisible)
function PlayerData.new(storeName: string, template: { [string]: any }, options: { kickMessage: ((Player) -> string)?, noSave: boolean? }?)
	local self = setmetatable({}, PlayerData)
	self._template = template
	self._kickMessage = options and options.kickMessage
	self._noSave = options ~= nil and options.noSave == true
	self._profiles = {} :: { [Player]: any }
	self._loadedEvent = Instance.new("BindableEvent")
	self.Loaded = self._loadedEvent.Event
	self._offline = false

	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(storeName)
	end)
	if ok then
		self._store = store
	else
		warn("[PlayerData] DataStore indisponible, les données ne seront pas sauvegardées. Active « Studio Access to API Services » dans les paramètres du jeu.")
		self._offline = true
	end

	Players.PlayerAdded:Connect(function(player)
		self:_load(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(self._load, self, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		self:_save(player)
		self._profiles[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_INTERVAL)
			for player in self._profiles do
				task.spawn(self._save, self, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in self._profiles do
			pending += 1
			task.spawn(function()
				self:_save(player)
				pending -= 1
			end)
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)

	return self
end

function PlayerData:_key(player: Player): string
	return "player_" .. player.UserId
end

function PlayerData:_load(player: Player)
	local data
	if not self._offline then
		local ok, result = withRetries("Chargement", function()
			return self._store:GetAsync(self:_key(player))
		end)
		if not ok then
			if RunService:IsStudio() then
				warn("[PlayerData] Chargement impossible dans Studio, on continue avec des données vides.")
			else
				player:Kick(self._kickMessage and self._kickMessage(player) or "Could not load your data. Please come back in a moment!")
				return
			end
		end
		data = result
	end
	if player.Parent == nil then
		return
	end
	data = data or deepCopy(self._template)
	reconcile(data, self._template)
	self._profiles[player] = data
	self._loadedEvent:Fire(player, data)
end

function PlayerData:_save(player: Player)
	local data = self._profiles[player]
	if not data or self._offline or self._noSave then
		return
	end
	withRetries("Sauvegarde", function()
		self._store:SetAsync(self:_key(player), data, { player.UserId })
	end)
end

function PlayerData:get(player: Player)
	return self._profiles[player]
end

-- Sauvegarde immédiate (après un achat Robux par exemple)
function PlayerData:saveNow(player: Player)
	self:_save(player)
end

return PlayerData
