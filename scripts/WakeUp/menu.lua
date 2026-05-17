local core = require('openmw.core')
local menu = require('openmw.menu')

local L = core.l10n('WakeUp')

local function cleanSaves(allowQuicksave)
	local saveDir = menu.getCurrentSaveDir()

	if not saveDir then return end

	for save, _ in pairs(menu.getSaves(saveDir)) do
		if save == 'Autosave.omwsave' or (not allowQuicksave and (save == 'Quicksave.omwsave' or string.find(save, '^Quicksave %- %d*%.omwsave$'))) then
			menu.deleteGame(saveDir, save)
		end
	end
end

local function doSave()
	cleanSaves()

	local saveDir = menu.getCurrentSaveDir()

	local status, result = pcall(function()
		menu.deleteGame(saveDir, L('save_name'):gsub('[ %[%]]', '_') .. '.omwsave')
	end)

	menu.saveGame(L('save_name'), 0)
end

local function loadLatestSave()
	local saveDir = menu.getCurrentSaveDir()
	local latestSave
	local saveName

	for key, data in pairs(menu.getSaves(saveDir)) do
		if not latestSave or save.creationTime > latestSave.creationTime then
			latestSave = save
			saveName = key
		end
	end	

	if latestSave then
		menu.loadGame(saveDir, saveName)
	end
end

return {
	eventHandlers = {
		wu_cleanSaves = cleanSaves,
		wu_doSave = doSave,
		wu_loadLatestSave = loadLatestSave
	}
}
