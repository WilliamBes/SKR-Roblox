-- Classements globaux (tous serveurs confondus) affichés sur deux grands panneaux au spawn.
local DataStoreService = game:GetService("DataStoreService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Commun.Format)

local LeaderboardService = {}

-- L'argent peut devenir énorme : on stocke son logarithme pour rester dans les limites des OrderedDataStore
local function encodeCash(n: number): number
	return math.floor(math.log10(math.max(n, 0) + 1) * 1e6)
end
local function decodeCash(v: number): number
	return 10 ^ (v / 1e6) - 1
end

local BOARDS = {
	{
		key = "TotalGagne",
		titleKey = "world_top_cash",
		value = function(data)
			return encodeCash(data.totalEarned)
		end,
		display = function(v)
			return Format.number(decodeCash(v)) .. " $"
		end,
		color = Color3.fromRGB(255, 210, 60),
		offset = CFrame.new(-16, 9, -26),
	},
	{
		key = "Rebirths",
		titleKey = "world_top_rebirths",
		value = function(data)
			return data.rebirths
		end,
		display = function(v)
			return tostring(v)
		end,
		color = Color3.fromRGB(170, 100, 255),
		offset = CFrame.new(16, 9, -26),
	},
}

local names: { [number]: string } = {}
local function nameFor(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = ok and name or "???"
	return names[userId]
end

local function buildBoard(board)
	local panel = Instance.new("Part")
	panel.Name = "Classement_" .. board.key
	panel.Anchored = true
	panel.Size = Vector3.new(18, 16, 1)
	panel.CFrame = CFrame.lookAt(board.offset.Position, Vector3.new(0, board.offset.Position.Y, 0))
	panel.Color = Color3.fromRGB(25, 22, 35)
	panel.Material = Enum.Material.SmoothPlastic
	panel.Parent = workspace:WaitForChild("Carte")

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(540, 480)
	gui.LightInfluence = 0
	gui.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.BackgroundColor3 = board.color
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(20, 15, 30)
	title.Text = ""
	title:SetAttribute("TextKey", board.titleKey)
	CollectionService:AddTag(title, "TranslatedLabel")
	title.Parent = gui

	-- Message d'état (chargement, erreur) traduit côté client
	local status = Instance.new("TextLabel")
	status.Position = UDim2.fromOffset(16, 64)
	status.Size = UDim2.new(1, -32, 0, 38)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.FredokaOne
	status.TextScaled = true
	status.TextColor3 = Color3.new(1, 1, 1)
	status.Text = ""
	status:SetAttribute("TextKey", "")
	CollectionService:AddTag(status, "TranslatedLabel")
	status.Parent = gui

	local rows = {}
	for i = 1, Config.Leaderboard.size do
		local row = Instance.new("TextLabel")
		row.Position = UDim2.fromOffset(16, 64 + (i - 1) * 41)
		row.Size = UDim2.new(1, -32, 0, 38)
		row.BackgroundTransparency = 1
		row.Font = Enum.Font.FredokaOne
		row.TextScaled = true
		row.TextXAlignment = Enum.TextXAlignment.Left
		row.TextColor3 = i <= 3 and board.color or Color3.new(1, 1, 1)
		row.Text = ""
		row.Parent = gui
		rows[i] = row
	end
	return rows, status
end

function LeaderboardService.init(store)
	local stores = {}
	for _, board in BOARDS do
		local ok, s = pcall(function()
			return DataStoreService:GetOrderedDataStore(board.key)
		end)
		if ok then
			stores[board.key] = s
		end
		board.rows, board.status = buildBoard(board)
		board.status:SetAttribute("TextKey", "world_loading")
	end

	task.spawn(function()
		while true do
			-- Envoie les scores des joueurs présents
			for _, player in Players:GetPlayers() do
				local data = store:get(player)
				if data then
					for _, board in BOARDS do
						local s = stores[board.key]
						if s then
							pcall(function()
								s:SetAsync(tostring(player.UserId), board.value(data))
							end)
						end
					end
				end
			end
			-- Relit le top
			for _, board in BOARDS do
				local s = stores[board.key]
				if s then
					local ok, pages = pcall(function()
						return s:GetSortedAsync(false, Config.Leaderboard.size)
					end)
					if ok and pages then
						local entries = pages:GetCurrentPage()
						board.status:SetAttribute("TextKey", "")
						for i, row in board.rows do
							local entry = entries[i]
							if entry then
								row.Text = string.format("%d. %s  ·  %s", i, nameFor(tonumber(entry.key) or 0), board.display(entry.value))
							else
								row.Text = ""
							end
						end
					else
						board.status:SetAttribute("TextKey", "world_unavailable")
					end
				end
			end
			task.wait(Config.Leaderboard.refreshSeconds)
		end
	end)
end

return LeaderboardService
