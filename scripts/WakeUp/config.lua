-- How many manual save slots should be allowed.
-- (Saves are evicted in order of creation)
-- default: 1
SAVE_SLOTS = 1

-- Save automatically when first visiting certain cells
-- (See "AUTOSAVE_CELLS" to customise)
-- default: true
ENABLE_AUTOSAVE_CELLS = true

-- Save in a different slot during quests with a point of no return
-- (See "SOFTLOCKABLE_QUESTS" to customise)
-- default: true
ENABLE_SOFTLOCK_PREVENTION = true

-- Automatically save the first time the player enters these cells
-- (List of ID of the cells)
-- Default: Dagoth Ur entrance
AUTOSAVE_CELLS = {
	"dagoth ur, outer facility",
}

-- To prevent potential softlocks, the mod saves into a special slot named "Recall" if the player is in the middle of these quests
-- (The numbers represent the quest stage interval where saving is considered "unsafe")
-- Default: The Tribunal and Bloodmoon main quests at their respective "points of no return"
SOFTLOCKABLE_QUESTS = {
	tr_sothasil = { ["start"]=20, ["stop"]=100 },
	bm_wildhunt = { ["start"]=20, ["stop"]=100 },
}

-- Seconds to wait once the game has loaded before clearing out saves
-- (Safety precaution to help avoid losing your quicksave if the game crashes on load)
-- Default: 5
ONLOAD_SAVE_CLEAR_TIMER = 5
