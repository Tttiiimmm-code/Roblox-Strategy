-- Teamwahl, Levelwahl und Ergebnisse der Grasland-Läufe.
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local UnitData = require(Shared.UnitData)
local RunConfig = require(Shared.RunConfig)
local Tutorial = require(Shared.Tutorial)
local Recruit = require(Shared.Recruit)
local UIKit = require(script.Parent.UIKit)
local CollectionUI = require(script.Parent.CollectionUI)
local THEME = UIKit.THEME
local make, label, panel, button = UIKit.make, UIKit.label, UIKit.panel, UIKit.button
local RunUI = {}
local frame, content, confirmation, callbacks
local lastState, lastProfile
local selecting = false
local selected, cards = {}, {}
local counter, beginButton, resultButton
local renderKey
local campSlot, campCandidate = 1, nil
local campBarracks = false

local function maxHp(id, entry)
	return (entry.stats or UnitData.Heroes[id].stats).hp + (entry.merges or 0) * Recruit.MERGE_HP
end

local function resetContent()
	CollectionUI.restoreBarracks()
	if content then content:Destroy() end
	content = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, frame)
	cards, resultButton = {}, nil
end

local function heading(title, subtitle)
	UIKit.chromeTitle({ Position = UDim2.fromOffset(24, 16), Size = UDim2.new(1, -48, 0, 48), Text = title,
		TextSize = 36 }, content)
	label({ Position = UDim2.fromOffset(24, 70), Size = UDim2.new(1, -48, 0, 44), Text = subtitle,
		TextSize = 20, TextWrapped = true, TextScaled = false, TextColor3 = THEME.dim }, content)
end

local function footer(text, style, callback, right)
	local b = button(text, content, style)
	b.AnchorPoint = Vector2.new(right and 1 or 0, 1)
	b.Position = UDim2.new(right and 1 or 0, right and -24 or 24, 1, -24)
	b.Size = UDim2.fromOffset(280, 64)
	b.TextSize = 22
	b.Activated:Connect(callback)
	return b
end

local function refreshSelection()
	counter.Text = ("%d / %d Helden gewählt – Leon ist frei wählbar."):format(#selected, RunConfig.START_TEAM)
	UIKit.setButtonStyle(beginButton, #selected == RunConfig.START_TEAM and "primary" or "disabled")
	for id, card in pairs(cards) do
		local index = table.find(selected, id)
		card.badge.Visible = index ~= nil
		card.badge.Text = index and ("Platz " .. index) or ""
		card.stroke.Color = index and THEME.good or card.rarity.color
	end
end

local function buildTeam(profile)
	resetContent()
	heading("Lauf starten", ("Wähle genau %d Helden aus deiner Sammlung."):format(RunConfig.START_TEAM))
	local scroll = make("ScrollingFrame", {
		Position = UDim2.fromOffset(24, 124), Size = UDim2.new(1, -48, 1, -260),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 10,
		ScrollingDirection = Enum.ScrollingDirection.Y, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, content)
	make("UIGridLayout", { CellSize = UDim2.fromOffset(168, 218), CellPadding = UDim2.fromOffset(16, 16),
		SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, scroll)
	local owned = {}
	for id in pairs(profile.heroes or {}) do if UnitData.Heroes[id] then table.insert(owned, id) end end
	table.sort(owned, function(a, b) return UnitData.Heroes[a].name < UnitData.Heroes[b].name end)
	for i, id in ipairs(owned) do
		local card = UIKit.heroCard(scroll, id, { LayoutOrder = i })
		card.sub.Text = ("%s · Lv %d"):format(UnitData.Classes[UnitData.Heroes[id].class].name, profile.heroes[id].level or 1)
		card.card.Activated:Connect(function()
			local index = table.find(selected, id)
			if index then table.remove(selected, index)
			elseif #selected < RunConfig.START_TEAM then table.insert(selected, id) end
			refreshSelection()
		end)
		cards[id] = card
	end
	counter = label({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.new(1, -48, 0, 30), TextSize = 19 }, content)
	beginButton = footer("Lauf starten", "disabled", function()
		if #selected == RunConfig.START_TEAM and not lastState.busy then callbacks.onStartRun(table.clone(selected)) end
	end, true)
	footer("Zurück", "muted", function()
		selecting = false
		renderKey = nil
		callbacks.onChanged()
	end, false)
	refreshSelection()
end

local function teamStrip(run, profile)
	local team = make("Frame", { Position = UDim2.fromOffset(24, 124), Size = UDim2.new(1, -48, 0, 104),
		BackgroundTransparency = 1 }, content)
	for i, id in ipairs(run.order) do
		local member, entry = run.team[id], profile.heroes[id]
		local card = panel({ Position = UDim2.new((i - 1) / #run.order, 4, 0, 0),
			Size = UDim2.new(1 / #run.order, -8, 1, 0) }, team)
		label({ Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 34),
			Text = UnitData.Heroes[id].name .. (member.alive and (" · Lv " .. (entry.level or 1)) or " · Gefallen"),
			TextSize = 21, TextColor3 = member.alive and THEME.text or THEME.dim }, card)
		local maximum = maxHp(id, entry)
		local bar = UIKit.bar(card, UDim2.fromOffset(14, 54), UDim2.new(1, -28, 0, 30), member.alive and UIKit.hpColor(member.hp / maximum) or THEME.dim)
		UIKit.setBar(bar, member.hp, maximum)
		if not member.alive then
			bar.text.Text = "Gefallen"
			card:FindFirstChild("Background"):FindFirstChildOfClass("UIGradient").Color = ColorSequence.new(Color3.fromRGB(58, 58, 68), Color3.fromRGB(26, 26, 32))
		end
	end
end

function RunUI.confirmAbandon()
	if not lastProfile or not lastProfile.run then return end
	confirmation.Visible = true
end

local function optionText(option)
	if option.kind == "camp" then return "⛺", "Lager", "Heilung & Teamwechsel\nKeine Kampfbelohnung" end
	local theme = RunConfig.THEMES[option.themeId]
	local reward = RunConfig.REWARDS[option.reward.kind]
	local title = option.bossId and ((option.kind == "miniboss" and "Miniboss: " or "Boss: ") .. UnitData.Enemies[option.bossId].name) or theme.name
	local symbol = option.bossId and "⚔" or theme.symbol
	return symbol, title, ("%s  %d %s"):format(reward.symbol, option.reward.amount, reward.name)
end

local function buildChoice(run, profile)
	resetContent()
	local region = RunConfig.REGION_NAMES[run.region] or run.region
	heading(("%s – Level %d / %d"):format(region, run.depth, RunConfig.totalLevels()),
		run.current and "Das abgebrochene Level beginnt von vorne, mit deinen KP vor dem Level."
			or (RunConfig.levelKind(run.depth) ~= "battle" and "Besiege den Anführer – danach fliehen die übrigen Gegner."
				or "Wähle Kampf oder Lager. Ein Wahllager ersetzt den Kampf dieses Levels."))
	teamStrip(run, profile)
	if run.current then
		local option = run.options[run.current]
		local symbol, title, detail = optionText(option)
		UIKit.chromeTitle({ Position = UDim2.fromOffset(24, 270), Size = UDim2.new(1, -48, 0, 60),
			Text = symbol .. "  " .. title .. "     " .. detail,
			TextSize = 30 }, content)
		local resume = button("Level erneut starten", content, "primary")
		resume.AnchorPoint = Vector2.new(0.5, 0)
		resume.Position = UDim2.new(0.5, 0, 0, 358)
		resume.Size = UDim2.fromOffset(440, 80)
		resume.TextSize = 28
		resume.Activated:Connect(function() if not lastState.busy then callbacks.onResumeLevel() end end)
	else
		local options = make("Frame", { Position = UDim2.fromOffset(24, 254), Size = UDim2.new(1, -48, 1, -360),
			BackgroundTransparency = 1 }, content)
		for i, option in ipairs(run.options) do
			local symbol, title, detail = optionText(option)
			local b = button("", options, "default")
			b:SetAttribute("HoverScale", 1) -- Große Karten behalten Farb-/Randfeedback ohne Überlappung.
			b.Position = UDim2.new((i - 1) / #run.options, 6, 0, 0)
			b.Size = UDim2.new(1 / #run.options, -12, 1, 0)
			label({ Position = UDim2.fromScale(0, 0.04), Size = UDim2.fromScale(1, 0.22), Text = symbol, TextSize = 48 }, b)
			label({ Position = UDim2.fromScale(0.03, 0.28), Size = UDim2.fromScale(0.94, 0.26), Text = title,
				Font = THEME.title, TextSize = 28, TextWrapped = true, TextScaled = false }, b)
			label({ Position = UDim2.fromScale(0.03, 0.58), Size = UDim2.fromScale(0.94, 0.34),
				Text = detail, TextWrapped = true, TextScaled = false, TextSize = 23, TextColor3 = THEME.gold }, b)
			b.Activated:Connect(function() if not lastState.busy then callbacks.onChooseLevel(i) end end)
		end
	end
	footer("Aufgeben", "danger", RunUI.confirmAbandon, false)
end

local function buildCamp(run, profile)
	resetContent()
	if campBarracks then
		local outgoing = run.order[campSlot]
		heading("Kaserne im Lager", ("Platz %d: %s – Held ansehen, dann Teamwechsel bestätigen."):format(campSlot,
			outgoing and UnitData.Heroes[outgoing].name or "Leer"))
		local collection = make("Frame", { Position = UDim2.fromOffset(24, 124), Size = UDim2.new(1, -48, 1, -230), BackgroundTransparency = 1 }, content)
		local swapButton
		local function refreshSwap(id)
			campCandidate = id
			if not swapButton then return end
			local valid = id and not table.find(run.order, id)
			UIKit.setButtonStyle(swapButton, valid and "primary" or "disabled")
			swapButton.Text = valid and ("Einsetzen: " .. UnitData.Heroes[id].name) or "Bereits im Team"
		end
		swapButton = footer("Held auswählen", "disabled", function()
			if campCandidate and not table.find(run.order, campCandidate) and not lastState.busy then
				callbacks.onCampSwap(campSlot, campCandidate, outgoing)
				campBarracks, renderKey = false, nil
			end
		end, true)
		CollectionUI.mountCamp(collection, profile, refreshSwap)
		footer("Zurück zum Lager", "muted", function()
			campBarracks, renderKey = false, nil
			callbacks.onChanged()
		end, false)
		return
	end
	heading(run.campExtra and "Extra-Lager vor Garrick" or "Lager", ("Lebende Teammitglieder vollständig geheilt · %d Teamplätze · %s %d Gold · %s %d Edelsteine"):format(run.maxTeam, Config.ICONS.gold, profile.gold or 0, Config.ICONS.gems, profile.gems or 0))
	local scroll = UIKit.textList({ Position = UDim2.fromOffset(24, 124), Size = UDim2.new(1, -48, 1, -230) }, content)
	for slot = 1, run.maxTeam do
		local id = run.order[slot]
		local member = id and run.team[id]
		local row = make("Frame", { Size = UDim2.new(1, -12, 0, 100), BackgroundTransparency = 1, LayoutOrder = slot }, scroll)
		label({ Position = UDim2.fromOffset(8, 6), Size = UDim2.new(0.3, -16, 0, 86), TextSize = 22,
			Text = id and (UnitData.Heroes[id].name .. " · Lv " .. (profile.heroes[id].level or 1) .. "\n"
				.. (member.alive and (member.hp .. " / " .. maxHp(id, profile.heroes[id]) .. " KP") or "Gefallen")) or ("Platz " .. slot .. " · Leer"),
			TextWrapped = true, TextScaled = false }, row)
		if member and not member.alive then
			for i, currency in ipairs({ "gold", "gems" }) do
				local price = RunConfig.revivePrice(profile.heroes[id].level or 1, currency)
				local affordable = (profile[currency] or 0) >= price
				local revive = button(Config.ICONS[currency] .. " " .. price .. (currency == "gold" and " Gold" or " Edelsteine"), row, affordable and "primary" or "disabled")
				revive.Position, revive.Size, revive.TextSize = UDim2.new(0.3 + (i - 1) * 0.22, 4, 0, 18), UDim2.new(0.22, -8, 0, 64), 22
				revive.Activated:Connect(function() if affordable and not lastState.busy then callbacks.onCampRevive(id, currency) end end)
			end
		end
		local change = button("Kaserne · Tausch", row, "default")
		change.Position, change.Size, change.TextSize = UDim2.new(0.74, 4, 0, 18), UDim2.new(0.26, -8, 0, 64), 22
		change.Activated:Connect(function()
			campSlot, campBarracks, renderKey = slot, true, nil
			callbacks.onChanged()
		end)
	end
	UIKit.flowLabel({ Size = UDim2.new(1, -12, 0, 0), LayoutOrder = run.maxTeam + 1, TextSize = 22, TextColor3 = THEME.dim,
		Text = "Gefallene können mit Gold ODER Edelsteinen wiederbelebt werden. Ausgewechselte Gefallene bleiben tot. Neue lebende Helden kommen mit vollen KP. Mindestens ein lebender Held muss im Team bleiben." }, scroll)
	footer("Aufgeben", "danger", RunUI.confirmAbandon, false)
	local living = false
	for _, id in ipairs(run.order) do if run.team[id].alive then living = true end end
	footer(run.campExtra and "Weiter zu Garrick" or "Weiter", living and "primary" or "disabled", function()
		if living and not lastState.busy then callbacks.onLeaveCamp() end
	end, true)
end

local function buildResult(info, profile)
	resetContent()
	local title = info.outcome == "Completed" and "Lauf geschafft"
		or info.outcome == "Abandoned" and "Lauf aufgegeben"
		or info.victory and "Level geschafft" or "Lauf vorbei"
	heading(title, info.ended and "Deine verdienten Belohnungen und Helden-Erfahrung bleiben erhalten."
		or (info.campNext and "Lager erreicht. Überlebende wurden vollständig geheilt." or "Belohnung erhalten. Überlebende wurden teilweise geheilt."))
	local lines = {}
	if info.ended then
		table.insert(lines, ("Geschaffte Level: %d / %d"):format(info.cleared, info.totalLevels))
		table.insert(lines, ("%s %d Gold     %s %d Edelsteine verdient"):format(Config.ICONS.gold, info.earned.gold, Config.ICONS.gems, info.earned.gems))
	else
		table.insert(lines, ("%s +%d Gold     %s +%d Edelsteine"):format(Config.ICONS.gold, info.reward.gold, Config.ICONS.gems, info.reward.gems))
	end
	if (info.teamPlaceGained or 0) > 0 then
		table.insert(lines, ("+%d Teamplatz: jetzt %d Plätze für das nächste Gebiet."):format(info.teamPlaceGained, info.maxTeam))
	end
	local heroIds = {}
	for id in pairs(info.healed) do table.insert(heroIds, id) end
	table.sort(heroIds)
	for _, id in ipairs(heroIds) do
		local hp = info.healed[id]
		table.insert(lines, hp.alive and ("%s: %d → %d / %d KP (+%d)"):format(UnitData.Heroes[id].name, hp.before, hp.after, hp.maxHp, hp.amount)
			or (UnitData.Heroes[id].name .. ": gefallen"))
	end
	table.insert(lines, ("Sammlung: %d Gold · %d Edelsteine"):format(profile.gold or 0, profile.gems or 0))
	local resultDetails = UIKit.textList({ Position = UDim2.fromOffset(40, 150), Size = UDim2.new(1, -80, 1, -270) }, content)
	UIKit.flowLabel({ Size = UDim2.new(1, -12, 0, 0), Text = table.concat(lines, "\n\n"), TextSize = 26 }, resultDetails)
	resultButton = footer(info.ended and "Zum Thronsaal" or "Weiter", "primary", function()
		if not lastState.busy then callbacks.onLobby() end
	end, true)
end

function RunUI.init(root, cbs)
	callbacks = cbs
	frame = panel({ Name = "RunWindow", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -64, 1, -64), Visible = false }, root)
	confirmation = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.backdrop,
		BackgroundTransparency = 0.35, BorderSizePixel = 0, Active = true, Visible = false, ZIndex = 50 }, root)
	local dialog = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(680, 290), ZIndex = 51 }, confirmation)
	label({ Position = UDim2.fromOffset(24, 24), Size = UDim2.new(1, -48, 0, 125), ZIndex = 52,
		Text = "Lauf wirklich aufgeben?\nVerdientes Gold, Edelsteine und Helden-Erfahrung bleiben erhalten.",
		TextWrapped = true, TextScaled = false, TextSize = 25 }, dialog)
	local cancel = button("Weiter spielen", dialog, "muted")
	cancel.Position, cancel.Size, cancel.ZIndex = UDim2.fromOffset(24, 180), UDim2.fromOffset(292, 72), 52
	cancel.TextSize = 22
	cancel.Activated:Connect(function() confirmation.Visible = false end)
	local abandon = button("Lauf aufgeben", dialog, "danger")
	abandon.Position, abandon.Size, abandon.ZIndex = UDim2.fromOffset(344, 180), UDim2.fromOffset(312, 72), 52
	abandon.TextSize = 22
	abandon.Activated:Connect(function()
		confirmation.Visible = false
		callbacks.onAbandonRun()
	end)
end

function RunUI.openTeam()
	if not Tutorial.unlocked(lastProfile) or lastProfile.run or not lastProfile.heroes or not lastState
		or lastState.mode ~= "Lobby" or lastState.busy then return end
	selecting, selected, renderKey = true, {}, nil
	callbacks.onChanged()
end

function RunUI.update(state, profile, loading)
	lastState, lastProfile = state, profile
	local own = state.ownerUserId == Players.LocalPlayer.UserId
	local info = (own and state.result and state.resultInfo and state.resultInfo.run and state.resultInfo) or nil
	local run = profile.run
	if run then selecting = false end
	local activeBattle = own and state.mode == "Battle" and state.run and not state.result
	local active = selecting or run ~= nil or activeBattle or info ~= nil
	local visible = active and not loading and not activeBattle and profile.heroes ~= nil
	frame.Visible = visible
	if not visible then CollectionUI.restoreBarracks(); confirmation.Visible = false; return active end
	local key
	if info then
		key = ("result:%s:%d:%d:%d:%d:%d:%d"):format(info.outcome, info.depth, info.cleared, info.earned.gold, info.earned.gems, profile.gold or 0, profile.gems or 0)
	elseif run then
		local team = {}
		for _, id in ipairs(run.order) do table.insert(team, id .. ":" .. run.team[id].hp .. ":" .. (profile.heroes[id].level or 1)) end
		key = run.phase .. ":" .. tostring(campBarracks) .. ":" .. (profile.gold or 0) .. ":" .. (profile.gems or 0) .. ":" .. run.seed .. ":" .. run.depth .. ":" .. (run.current or 0) .. table.concat(team, ",")
	else
		local owned = {}
		for id in pairs(profile.heroes) do table.insert(owned, id) end
		table.sort(owned)
		key = "team:" .. table.concat(owned, ",")
	end
	if key ~= renderKey then
		renderKey = key
		confirmation.Visible = false
		if info then buildResult(info, profile)
		elseif run then
			if run.phase == "camp" then buildCamp(run, profile)
			else campBarracks = false; buildChoice(run, profile) end
		else buildTeam(profile) end
	end
	if resultButton then UIKit.setButtonStyle(resultButton, state.busy and "disabled" or "primary") end
	return active
end

return RunUI
