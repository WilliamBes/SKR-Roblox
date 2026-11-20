-- Formatage des nombres pour l'affichage : 1234 -> "1.23K", 5600000 -> "5.6M"
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Format.number(n: number): string
	if n ~= n then
		return "0"
	end
	local negative = n < 0
	n = math.abs(n)
	local index = 1
	while n >= 1000 and index < #SUFFIXES do
		n /= 1000
		index += 1
	end
	local text
	if index == 1 then
		text = tostring(math.floor(n))
	elseif n >= 100 then
		text = string.format("%d", math.floor(n))
	elseif n >= 10 then
		text = (string.format("%.1f", math.floor(n * 10) / 10):gsub("%.0$", ""))
	else
		text = (string.format("%.2f", math.floor(n * 100) / 100):gsub("%.?0+$", ""))
	end
	text ..= SUFFIXES[index]
	return (negative and "-" or "") .. text
end

function Format.time(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

return Format
