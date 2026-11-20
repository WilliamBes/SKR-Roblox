-- Tutoriel (objectifs), cadeaux de temps de jeu, récompense quotidienne et codes promo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Commun.Format)
local EconomyService = require(script.Parent.EconomyService)

local RewardService = {}

local sessionStart: { [Player]: number } = {}
local claimedGifts: { [Player]: { [number]: boolean } } = {}

local function today(): number
	return os.time() // 86400
end

------------------------------------------------------------------------------
-- Objectifs
------------------------------------------------------------------------------
local function questProgress(quest, data): number
	if quest.type == "collect" then
		return data.meteorsCollected
	elseif quest.type == "upgrade" then
		return data.upgrades[quest.key] or 0
	elseif quest.type == "earned" then
		return data.totalEarned
	elseif quest.type == "rebirth" then
		return data.rebirths
	end
	return 0
end

local function checkQuest(player: Player, data)
	local quest = Config.Quests[data.questIndex]
	if not quest then
		return
	end
	-- Un rebirth remet les améliorations à zéro : on considère l'objectif réussi s'il y a déjà eu un rebirth
	local done = questProgress(quest, data) >= quest.target or (data.rebirths > 0 and quest.type ~= "rebirth")
	if done then
		data.questIndex += 1
		EconomyService.grant(player, quest.reward)
		EconomyService.notify(player, "Objectif réussi ! +" .. Format.number(quest.reward) .. " $", "reward")
	end
end

------------------------------------------------------------------------------
-- Cadeaux de temps de jeu
------------------------------------------------------------------------------
local function claimGift(player: Player, index: any)
	local data = EconomyService.data(player)
	local gift = typeof(index) == "number" and Config.Gifts[index]
	local claimed = claimedGifts[player]
	if not data or not gift or not claimed or claimed[index] then
		return
	end
	local elapsed = os.time() - (sessionStart[player] or os.time())
	if elapsed < gift.minutes * 60 then
		return
	end
	claimed[index] = true
	local cash = Config.incomeReward(data, gift.incomeMinutes, Config.GiftMinimum)
	EconomyService.grant(player, cash)
	local message = "Cadeau ouvert : +" .. Format.number(cash) .. " $"
	if gift.boostSeconds then
		EconomyService.addBoost(player, gift.boostSeconds)
		message ..= " et un boost x" .. Config.Boost.multiplier .. " !"
	end
	EconomyService.notify(player, message, "reward")
end

------------------------------------------------------------------------------
-- Récompense quotidienne
------------------------------------------------------------------------------
local function nextStreak(data): number
	if data.lastDaily == today() - 1 then
		return math.min(data.dailyStreak + 1, Config.Daily.maxStreak)
	end
	return 1
end

local function dailyReward(data, streak: number): number
	return Config.incomeReward(data, Config.Daily.incomeMinutesPerDay * streak, Config.Daily.minimum * streak)
end

local function claimDaily(player: Player)
	local data = EconomyService.data(player)
	if not data or data.lastDaily >= today() then
		return
	end
	local streak = nextStreak(data)
	local cash = dailyReward(data, streak)
	data.dailyStreak = streak
	data.lastDaily = today()
	EconomyService.grant(player, cash)
	EconomyService.notify(player, string.format("Jour %d : +%s $ ! Reviens demain pour plus.", streak, Format.number(cash)), "reward")
end

------------------------------------------------------------------------------
-- Codes promo
------------------------------------------------------------------------------
local function redeemCode(player: Player, text: any)
	local data = EconomyService.data(player)
	if not data or typeof(text) ~= "string" or #text > 30 then
		return
	end
	local code = string.upper((text:gsub("%s", "")))
	local reward = Config.Codes[code]
	if not reward then
		EconomyService.notify(player, "Ce code n'existe pas.", "error")
		return
	end
	if data.codesUsed[code] then
		EconomyService.notify(player, "Tu as déjà utilisé ce code.", "error")
		return
	end
	data.codesUsed[code] = true
	local parts = {}
	local cash = (reward.cash or 0)
	if reward.incomeMinutes then
		cash += Config.incomeReward(data, reward.incomeMinutes, 0)
	end
	if cash > 0 then
		EconomyService.grant(player, cash)
		table.insert(parts, "+" .. Format.number(cash) .. " $")
	end
	if reward.boostSeconds then
		EconomyService.addBoost(player, reward.boostSeconds)
		table.insert(parts, "boost x" .. Config.Boost.multiplier .. " " .. Format.time(reward.boostSeconds))
	end
	EconomyService.notify(player, "Code activé : " .. table.concat(parts, " et "), "reward")
end

------------------------------------------------------------------------------
function RewardService.setupPlayer(player: Player)
	sessionStart[player] = os.time()
	claimedGifts[player] = {}
end

function RewardService.init()
	EconomyService.registerAction("claimGift", claimGift)
	EconomyService.registerAction("claimDaily", claimDaily)
	EconomyService.registerAction("code", redeemCode)

	EconomyService.registerStateExtra(function(player, data, state)
		checkQuest(player, data)
		local quest = Config.Quests[data.questIndex]
		if quest then
			state.quest = {
				number = data.questIndex,
				total = #Config.Quests,
				text = quest.text,
				progress = math.min(questProgress(quest, data), quest.target),
				target = quest.target,
				reward = quest.reward,
				type = quest.type,
				key = quest.key,
			}
		end

		local gifts = {}
		for i in Config.Gifts do
			gifts[i] = claimedGifts[player] and claimedGifts[player][i] == true
		end
		state.giftsClaimed = gifts
		state.sessionElapsed = os.time() - (sessionStart[player] or os.time())

		local claimable = data.lastDaily < today()
		state.daily = {
			claimable = claimable,
			streak = claimable and nextStreak(data) or data.dailyStreak,
			reward = claimable and dailyReward(data, nextStreak(data)) or 0,
		}
	end)

	Players.PlayerRemoving:Connect(function(player)
		sessionStart[player] = nil
		claimedGifts[player] = nil
	end)
end

return RewardService
