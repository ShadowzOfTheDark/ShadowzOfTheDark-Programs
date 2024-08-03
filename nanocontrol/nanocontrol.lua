-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Main program entry point

local NC = {}
setmetatable(NC, {__index = _G})

NC.VER = "v1.1.0"
NC.LIB_DIR = "/lib/nanocontrol/"

-- This is the default server config values for the nanomachines.
-- If your server has configs changed modify these to reflect that.
NC.SV = {}
NC.SV.commandDelay = 1
NC.SV.commandRange = 2
NC.SV.maxInputs = 2
NC.SV.maxInputsActive = 4
NC.SV.maxOutputs = 2
NC.SV.safeInputsActive = 2
NC.SV.triggerQuota = 0.4

NC.CFG = {}
NC.CFG.tryTime = NC.SV.commandDelay*3.75 -- This is how long the program will wait to get a response.
NC.CFG.waitTime = NC.SV.commandDelay*1.25 -- This is how long the program will wait for a single response.
NC.CFG.port = 17061

-- This just adds a shorthand 'nc' command with setup at boot.
if require("rc").loaded.nanocontrol_alias == nil then
    print("Welcome to NanoControl "..NC.VER.."!")
    print("Adding 'nc' shorthand alias for 'nanocontrol'.")
    local shell = require("shell")
    shell.execute("rc nanocontrol_alias enable")
    shell.execute("rc nanocontrol_alias start")
    os.sleep(3)
else
    print("Loading NanoControl ("..NC.VER..")...")
end

-- Setting up hardware.
local component = require("component")

-- Setting up networking hardware.
local modem = component.modem
if modem == nil then
    io.stderr:write("NanoControl requires a wireless network card!\n")
    return false
elseif not modem.isWireless() then
    io.stderr:write("Detected a network card but isn't wireless. Trying anyway...\n")
end
modem.open(NC.CFG.port)
NC.modem = modem

-- Function to link to nanomachines.
local net_retry = require("net_retry")
net_retry.time = NC.CFG.tryTime
net_retry.wait = NC.CFG.waitTime
net_retry.port = NC.CFG.port
net_retry.modem = NC.modem

--localAdr,remoteAdr,port,dist,...

local function verify(port,dist,title)
    return port == NC.CFG.port and dist < NC.SV.commandRange and title == "nanomachines"
end

local function verifyAdr(adr,port,dist,title)
    return adr == NC.address and port == NC.CFG.port and dist < NC.SV.commandRange and title == "nanomachines"
end

NC.linkNanomachines = function()
    net_retry.broadcastTry(function(localAdr,remoteAdr,port,dist,title,cmd,response)
        if verify(port,dist,title) and cmd == "port" and response == NC.CFG.port then
            NC.address = remoteAdr
            return true
        end
    end,"nanomachines","setResponsePort",NC.CFG.port)
    if NC.address ~= nil then
        return net_retry.sendTry(NC.address,function(localAdr,remoteAdr,port,dist,title,cmd,response)
            if verifyAdr(remoteAdr,port,dist,title) and cmd == "totalInputCount" then
                NC.inputs = response
                return true
            end
        end,"nanomachines","getTotalInputCount")
    end
end

-- Handler for shell commands.
local commandArgs = {...}
local command = commandArgs[1]

if command then
    command = string.lower(command)
    table.remove(commandArgs,1)

    local func = loadfile(NC.LIB_DIR.."commands/"..command..".lua",nil,NC)
    if func then
        func(table.unpack(commandArgs))
    else
        io.stderr:write("Invalid command.\n")
    end
    return false
end

print("Establishing connection to nanomachines...")
if NC.linkNanomachines() then
    print("Found nanomachines: "..NC.address)
    print("Port set to "..NC.CFG.port..".")
    print("Detected "..NC.inputs.." inputs.")
else
    io.stderr:write("Failed to connect to nanomachines. Are you sure you're close enough?")
end

local nanoGUI = require("nanocontrol/nanoGUI")

NC.status = {}

NC.status.adr = "98476297EFEFErawr-40274"
NC.status.name = "Shadman"
NC.status.power = 109
NC.status.powerMax = 1000

nanoGUI.init(NC)

