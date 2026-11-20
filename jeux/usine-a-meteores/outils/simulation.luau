-- Simulation de l'économie (lancée par simulation.sh, qui fournit la variable Config).
-- Un joueur parfait ramasse une part des météores, achète l'amélioration la plus rentable et fait rebirth dès que possible.
-- Un vrai joueur est 2 à 3 fois plus lent (pauses, hésitations, jeu en arrière-plan).

-- Joueur qui ramasse tout, achète l'amélioration la moins chère (rapport) et fait rebirth dès que possible
local function simulate(rebirthsTarget, collectRatio)
	local rebirths, t = 0, 0
	local log = {}
	local upgrades = {SpawnRate=0, MeteorValue=0, Refinery=0, Magnet=0}
	local cash, dt = 0, 1
	local start = 0
	while rebirths < rebirthsTarget and t < 3600*20 do
		local mult = Config.rebirthMultiplier(rebirths)
		local income = Config.estimatedIncome(upgrades) * mult
		-- ramassage partiel sans aimant
		local rate = income - Config.refineryIncome(upgrades.Refinery) * mult
		income = Config.refineryIncome(upgrades.Refinery) * mult + rate * (collectRatio + (1-collectRatio) * math.min(1, upgrades.Magnet/6))
		cash += income * dt
		t += dt
		-- achète tant qu'il y a un gain rentable
		local bought = true
		while bought do
			bought = false
			local bestKey, bestScore
			for key, u in Config.Upgrades do
				local lvl = upgrades[key]
				if lvl < u.max then
					local cost = Config.upgradeCost(key, lvl)
					if cost <= cash then
						local before = Config.estimatedIncome(upgrades)
						upgrades[key] += 1
						local after = Config.estimatedIncome(upgrades)
						upgrades[key] -= 1
						local score = (after - before) / cost + (key == "Magnet" and 0.0005 or 0)
						if not bestScore or score > bestScore then bestKey, bestScore = key, score end
					end
				end
			end
			if bestKey then
				cash -= Config.upgradeCost(bestKey, upgrades[bestKey]); upgrades[bestKey] += 1; bought = true
			end
		end
		if cash >= Config.rebirthCost(rebirths) then
			rebirths += 1
			table.insert(log, string.format("rebirth %d à %.1f min (revenu avant: %.0f $/s, niveaux V%d F%d R%d A%d)", rebirths, (t - start)/60, income, upgrades.MeteorValue, upgrades.SpawnRate, upgrades.Refinery, upgrades.Magnet))
			start = t
			cash = 0
			for k in upgrades do upgrades[k] = 0 end
		end
	end
	return log
end
local ratio = tonumber(RATIO) or 0.7
local count = tonumber(COUNT) or 10
print(string.format("Joueur parfait, ramasse %d%% des météores sans aimant, %d rebirths :", ratio * 100, count))
for _, line in simulate(count, ratio) do
	print(line)
end
