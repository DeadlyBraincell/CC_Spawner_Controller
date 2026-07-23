peripheral.find("modem", rednet.open)

local spawnerId

local spawnerSide = "back"

local masterId = 12

local args = {...}

-- Create startup.lua
if not fs.exists("startup.lua") then
	local file = fs.open("startup.lua", "w")
	file.write("os.run({}, \"Slave.lua\")")
	file.close()
end


-- Ask for spawnerId
if not fs.exists("spawnerId") or args[1] == "rename" then
	local file = fs.open("spawnerId", "w")
	print("Input spawner id:")
	local input = read()
	file.write(input)
	file.close()
	os.reboot()
else
	local file = fs.open("spawnerId", "r")
	spawnerId = file.readAll()
	file.close()
end

while true do
	local id, message = rednet.receive(spawnerId)
	if id == masterId then
		if message and not redstone.getOutput(spawnerSide) then
			print("Activating")
		elseif not message and redstone.getOutput(spawnerSide) then
			print("Deactivating")
		end
		redstone.setOutput(spawnerSide, message)
	end
end
