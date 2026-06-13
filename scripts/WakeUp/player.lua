local self = require('openmw.self')
local iUI = require('openmw.interfaces').UI
local ui = require('openmw.ui')
local core = require('openmw.core')
local input = require('openmw.input')
local async = require('openmw.async')
local types = require('openmw.types')

require('scripts.WakeUp.config')

local restStart = core.getGameTime()
local L = core.l10n('WakeUp')
local dynamicHealth = types.Player.stats.dynamic.health(self)
local startHealthCurrent = dynamicHealth.current
local cannotRestGMST = 'sRestMenu4'

local newGame = false
local inBed = false
local pendingMenuOpen = false
local pendingMenuClose = false
local visitedCells = {}

-- Player flags
local charGenFinished = false
local hasSavedInBed = false
local inDanger = false

local function UiModeChanged(data)
	if data.newMode == 'MainMenu' then
		if not pendingMenuOpen and types.Player.isCharGenFinished(self) then
			pendingMenuOpen = true
			core.sendGlobalEvent('wu_setCharGen', { value = -2 })
		elseif pendingMenuOpen then
			pendingMenuOpen = false
			pendingMenuClose = true
		end

	elseif data.oldMode == 'MainMenu' and pendingMenuClose then
		pendingMenuClose = false
		core.sendGlobalEvent('wu_setCharGen', { value = -1 })
		types.Player.sendMenuEvent(self, 'wu_cleanSaves')

	elseif data.newMode == 'Rest' and not data.oldMode then
		if data.arg then
			inBed = true
			restStart = core.getGameTime()
			startHealthCurrent = dynamicHealth.current
		else
			ui.showMessage(core.getGMST(cannotRestGMST), { showInDialogue = false})
		end

	elseif inBed and not data.newMode and data.oldMode == 'Rest' then
		local newHealth = dynamicHealth.current
		local newHealthMax = dynamicHealth.base + dynamicHealth.modifier

		if charGenFinished and (restStart < core.getGameTime()) then
			if (newHealth == newHealthMax or newHealth >= startHealthCurrent) then
				hasSavedInBed = true
				types.Player.sendMenuEvent(self, 'wu_doSave', { inDanger = inDanger })
			else
				ui.showMessage(L('save_failed'), { showInDialogue = false})
			end
		end

		inBed = false
	end
end

local function wu_showMessage(message)
	ui.showMessage(message, { showInDialogue = false })
end

local function quickSaveHandler()
	types.Player.sendMenuEvent(self, 'wu_cleanQuickSaves')

	if not pendingMenuOpen and charGenFinished then
		pendingMenuOpen = true
		core.sendGlobalEvent('wu_setCharGen', { value = -2 })
	end
end

local function onQuestUpdate(questId, stage)
	if not ENABLE_SOFTLOCK_PREVENTION then return end

	local softlockableQuest = SOFTLOCKABLE_QUESTS[questId]

	if softlockableQuest then
		if not inDanger and stage >= softlockableQuest.start then
			inDanger = true

			types.Player.sendMenuEvent(self, 'wu_doSafetySave')
		elseif inDanger and stage >= softlockableQuest.stop then
			inDanger = false
		end
	end
end

local function onFrame()
	if not inBed then
		iUI.removeMode('Rest')
	end

	if types.Player.isCharGenFinished(self) then
		iUI.removeMode('MainMenu')
	elseif pendingMenuOpen then
		iUI.addMode('MainMenu')
	end
end

input.registerTriggerHandler('QuickSave', async:callback(quickSaveHandler))

local function charGenCheck()
	charGenFinished = types.Player.isCharGenFinished(self)

	if not charGenFinished then
		async:newUnsavableSimulationTimer(1, charGenCheck)
	elseif newGame then
		newGame = false
		hasSavedInBed = true
		types.Player.sendMenuEvent(self, 'wu_doSave', { inDanger = inDanger })
	end
end

local function onSave()
	return {
		charGenFinished = charGenFinished,
		hasSavedInBed = hasSavedInBed,
		visitedCells = visitedCells
	}
end

local function onLoadSaveClear()
	if hasSavedInBed then
		types.Player.sendMenuEvent(self, 'wu_cleanSaves')
	end
end

local function changeCell(newCell)
	if not ENABLE_AUTOSAVE_CELLS then return end

	local autosaveCell = false

	for _, cell in ipairs(AUTOSAVE_CELLS) do
		if cell == newCell then
			autosaveCell = true
			break
		end
	end

	if autosaveCell then
		if visitedCells then
			for _, cell in ipairs(visitedCells) do
				if cell == newCell then
					return
				end
			end
		end

		table.insert(visitedCells, newCell)
		types.Player.sendMenuEvent(self, 'wu_doSave', { inDanger = inDanger })
	end
end

local function onLoad(data)
	if not data then
		charGenCheck()
		return
	end

	charGenFinished = data.charGenFinished
	hasSavedInBed = data.hasSavedInBed

	if ENABLE_SOFTLOCK_PREVENTION then
		print('softlock prevention active')
		for quest, stage in pairs(SOFTLOCKABLE_QUESTS) do
			local playerQuest = types.Player.quests(self)[quest]

			print('checking for ', quest)
			print(playerQuest)

			if (playerQuest) then
				print(playerQuest.stage, stage.start, stage.stop)
			end

			if playerQuest and playerQuest.stage >= stage.start and playerQuest.stage < stage.stop then
				inDanger = true
			end
		end
	end

	if data.visitedCells == nil then
		data.visitedCells = {}
	end

	visitedCells = data.visitedCells

	if not charGenFinished then
		charGenCheck()
	else
		core.sendGlobalEvent('wu_setCharGen', { value = -1 })
	end

	if not hasSavedInBed then
		iUI.showInteractiveMessage(L('startup_message'))
	end

	async:newUnsavableSimulationTimer(ONLOAD_SAVE_CLEAR_TIMER, onLoadSaveClear)
end

return {
	engineHandlers = {
		onFrame = onFrame,
		onSave = onSave,
		onLoad = onLoad,
		onQuestUpdate = onQuestUpdate
	},
	eventHandlers = {
		UiModeChanged = UiModeChanged,
		wu_changeCell = changeCell,
		wu_showMessage = wu_showMessage,
		wu_initCharGenCheck = charGenCheck,
		wu_newGame = function()
			newGame = true
		end,
		Died = function()
			types.Player.sendMenuEvent(self, 'wu_cleanSaves')
			iUI.showInteractiveMessage(L('wake_up'))
		end
	}
}
