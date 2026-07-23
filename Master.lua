------Peripherals and externals------

peripheral.find("modem", rednet.open)

local bridge = peripheral.find("me_bridge") or peripheral.find("rs_bridge") or error("No Bridge found")

local args = {...}

------Config------

local configPath = "/config/"

local function getConfig(name)
	if not fs.exists(configPath .. name .. ".txt") then
		fs.open(configPath .. name .. ".txt", "w")
	end
	local file, err = fs.open(configPath .. name .. ".txt", "r")
	if not file then
		print(err)
	end
	local list = file.readAll()
	file.close()
	if list == "" then
		list = "{}"
	end

	return textutils.unserialise(list)
end

local function saveConfig(config, name)
	if not fs.exists(configPath .. name .. ".txt") then
		fs.open(configPath .. name .. ".txt", "w")
	end
	local data = textutils.serialise(config)
	local file = fs.open(configPath .. name .. ".txt", "w")
	file.write(data)
	file.close()
end

local mobIndex = getConfig("config")

local debug = args[1] == "debug"

------Util------

-- Create startup.lua
if not fs.exists("startup.lua") then
	local file = fs.open("startup.lua", "w")
	file.write("os.run({}, \"Master.lua\")")
	file.close()
	os.reboot()
end

local function printDebug(text)
	if debug then
		print("Debug: " .. text)
	end
end

local function getAllMobdrops()
	local tempList = {}
	for _, mob in pairs(mobIndex) do
		for _, item in pairs(mob.drops) do
			tempList[item.item] = {spawner = mob.spawnerid, limit = item.limit, active = mob.active}
		end
	end
	return tempList
end

--- Sets the state of the spawner
---@param spawner string
---@param active boolean
local function setSpawner(spawner, active, item)
	rednet.broadcast(active, spawner)
	print("Activating " .. spawner .. " for " .. item)
end

--- returns the amount of the given item in the attached system
---@param item string
local function getItemAmountByName(item)
	printDebug("getting itemcount for " .. item)
	local itemStack, err = bridge.getItem({name = item})
	local toReturn = 0
	if itemStack then
		toReturn = itemStack.count
	else
		printDebug("Defaulting to 0")
		if err and err == "ITEM_NOT_FOUND" then
			printError("Itemname was not recognised.\nLook for typos in the config for Item:\n" .. item)
			error("See log for details")
		end
	end
	return toReturn
end

local function refresh()
	for item, data in pairs(getAllMobdrops()) do
		local amount = getItemAmountByName(item)
		if amount < data.limit and not data.active then
			setSpawner(data.spawner, true, item)
		elseif amount > data.limit and data.active then
			setSpawner(data.spawner, false, item)
		end
	end
end


------Main------

--- Check the storage network once every minute and activate spawner if item is under threshold
local function main()
	while true do
		refresh()
		os.sleep(60)
	end
end

local function autosave()
	os.sleep(120)
	saveConfig(mobIndex, "config")
end

while true do
	parallel.waitForAny(main, autosave)
end