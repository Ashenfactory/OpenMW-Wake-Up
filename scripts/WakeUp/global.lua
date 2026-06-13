local types = require("openmw.types")
local Activation = require("openmw.interfaces").Activation
local core = require("openmw.core")
local world = require("openmw.world")
local noSleepGMST = core.getGMST("sNotifyMessage64")
local deadActors = {}
local player = world.players[1]
local gv = world.mwscript.getGlobalVariables(player)
local lastCell = nil

local function isInFaction(factionId, actor)
	if types.NPC.isExpelled(actor, factionId) then
		return -1
	end

	local rank = types.NPC.getFactionRank(actor, factionId)

	if rank > 0 then
		return rank
	else
		return -1
	end
end

local function canUseBed(bed, actor)
	if bed.globalVariable then
		local var = world.mwscript.getGlobalVariables(actor)[bed.globalVariable]
		if var == 1 then
			return true
		end
	end

	if bed.owner.factionId then
		local actorRank = isInFaction(bed.owner.factionId, actor)
		local ownerRank = bed.owner.factionRank

		if ownerRank and actorRank < ownerRank then
			return false
		else
			return true
		end
	elseif bed.owner.recordId then
		local ownerNPCRecord = types.NPC.record(bed.owner.recordId)
		local ownerRef

		for _, activeActor in ipairs(world.activeActors) do
			if activeActor.recordId == ownerNPCRecord.id then
				ownerRef = activeActor
			end
		end

		if ownerRef and types.Actor.stats.dynamic.health(ownerRef).current > 0 then
			return false
		elseif deadActors[ownerNPCRecord.id] or ownerRef and types.Actor.stats.dynamic.health(ownerRef).current <= 0 then
			deadActors[ownerNPCRecord.id] = true
			return true
		end

		return false
	end
end

local function activateBed(object, actor)
	local scrName = (types.Activator.record(object.recordId).mwscript or ''):lower()
	local bedScripts = { bed_standard = true, chargenbed = true }

	if bedScripts[scrName] and canUseBed(object, actor) == false then
		actor:sendEvent("wu_showMessage", noSleepGMST)

		return false
	end
end

Activation.addHandlerForType(types.Activator, activateBed)

local function onUpdate()
	local currentCell = player.cell

	if currentCell == lastCell then return end

	lastCell = currentCell

	player:sendEvent('wu_changeCell', currentCell.id:lower())
end

local function setCharGen(data)
	gv.CharGenState = data.value
end

local function onLoad(data)
	if not data then return end
	deadActors = data.deadActors
end

local function onNewGame()
	player:sendEvent('wu_newGame')
end

local function onPlayerAdded(data)
	player = data
	gv = world.mwscript.getGlobalVariables(player)

	player:sendEvent('wu_initCharGenCheck')
end

local function onSave()
	return {
		deadActors = deadActors
	}
end

return {
	interfaceName = "WakeUp",
	interface = {
		version = 1
	},
	engineHandlers = {
		onUpdate= onUpdate,
		onLoad = onLoad,
		onSave = onSave,
		onPlayerAdded = onPlayerAdded,
		onNewGame = onNewGame
	},
	eventHandlers = {
		wu_setCharGen = setCharGen
	},
}
