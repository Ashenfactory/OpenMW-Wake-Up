local core = require('openmw.core')
local menu = require('openmw.menu')

local L = core.l10n('WakeUp')

require('scripts.WakeUp.config')

local function orderByRecency(a, b)
	return a.info.creationTime < b.info.creationTime
end

local function clearSaveType(label, allowed_slots)
	local saveDir = menu.getCurrentSaveDir()

	if not saveDir then return end

	local saves = menu.getSaves(saveDir)
	local matchingSaves = {}

	for name, info in pairs(saves) do
		if name == label .. '.omwsave' or string.find(name, '^' .. label .. ' %- %d*%.omwsave$') then
			table.insert(matchingSaves, { name = name, info = info })
		end
	end

	if allowed_slots > 0 then
		table.sort(matchingSaves, orderByRecency)

		for i = 1, allowed_slots do
			table.remove(matchingSaves)
		end
	end

	for _, save in ipairs(matchingSaves) do
		menu.deleteGame(saveDir, save.name)
	end
end

local function cleanSaves()
	clearSaveType('Quicksave', 0)
	clearSaveType('Autosave', 1)
end

local function cleanQuickSaves()
	clearSaveType('Quicksave', 1)
end

local function doSave(data)
	cleanSaves()

	local safetySlots = 0

	if (data.inDanger) then
		safetySlots = SAVE_SLOTS

		menu.saveGame(L('safety_save_name'), 0)
	else
		menu.saveGame(L('save_name'), 0)

		local saveName = L('save_name'):gsub('[ %[%]]', '_')
		clearSaveType(saveName, SAVE_SLOTS)
	end

	local safetySaveName = L('safety_save_name'):gsub('[ %[%]]', '_')
	clearSaveType(safetySaveName, safetySlots)
end

local function safetySave()
	cleanSaves()

	menu.saveGame(L('safety_save_name'), 0)

	local safetySaveName = L('safety_save_name'):gsub('[ %[%]]', '_')

	clearSaveType(safetySaveName, 1)
end

return {
	eventHandlers = {
		wu_cleanSaves = cleanSaves,
		wu_cleanQuickSaves = cleanQuickSaves,
		wu_doSave = doSave,
		wu_doSafetySave = safetySave,
	}
}
