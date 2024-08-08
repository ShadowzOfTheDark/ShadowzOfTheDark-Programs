-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Main program entry point

local NC = {}

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
NC.CFG.port = 17061
NC.CFG.timeout = 3 -- Time in seconds for nano connection to timeout.

NC.Latency = NC.SV.commandDelay + 0.1

local nanoGUI

-- This just adds a shorthand 'nc' command with setup at boot.
if require("rc").loaded.nanocontrol_alias == nil then
    print("Welcome to NanoControl!")
    print("Adding 'nc' shorthand alias for 'nanocontrol'.")
    local shell = require("shell")
    shell.execute("rc nanocontrol_alias enable")
    shell.execute("rc nanocontrol_alias start")
    os.sleep(3)
end

-- Setting up hardware.
local component = require("component")
local computer = require("computer")

-- Setting up networking hardware.
local modem = component.modem
if modem == nil then
    io.stderr:write("NanoControl requires a wireless network card!\n")
    return false
elseif not modem.isWireless() then
    io.stderr:write("Detected a network card but isn't wireless. Trying anyway...\n")
end
modem.open(NC.CFG.port)
modem.setStrength(NC.SV.commandRange)
NC.modem = modem

-- Communication handling

local function verify(port,dist,delimiter)
    return port == NC.CFG.port and dist < NC.SV.commandRange and delimiter == "nanomachines"
end

local function verifyAdr(adr,port,dist,delimiter)
    return adr == NC.address and port == NC.CFG.port and dist < NC.SV.commandRange and delimiter == "nanomachines"
end

NC.dat = {}

local queries = {"getTotalInputCount","getPowerState","getName","getAge","getHealth","getHunger","getExperience"}
local numQueries = #queries
local queryIndex = 0

local timeoutTime = computer.uptime()
local timedOut = true

local function updateResponse(set)
    if set then
        timeoutTime = computer.uptime() + NC.CFG.timeout
        timedOut = false
    else
        if computer.uptime() > timeoutTime and not timedOut then
            timedOut = true
            NC.dat = {}
            NC.address = nil
            queryIndex = 0
            if nanoGUI then
                nanoGUI.drawStatusIndicator("Searching",0xFF3333,0xFFFFFF)
                nanoGUI.updateScreen = true
            end
            computer.beep(500,0.25)
        end
    end
end

function NC.modem_message(_,adr,port,dist,delimiter,title,...)
    local verified = false
    local args = table.pack(...)
    if NC.address and verifyAdr(adr,port,dist,delimiter) then
        verified = true
    elseif verify(port,dist,delimiter) then
        verified = true
        if title == "port" and args[1] == NC.CFG.port then
            NC.address = adr
            computer.beep(1000,0.25)
            if nanoGUI then
                nanoGUI.drawStatusIndicator("Connected",0x33CC33,0xFFFFFF)
            end
        end
    end
    if not verified then return end
    if #args > 1 then
        NC.dat[title] = args
    else
        NC.dat[title] = args[1]
    end
    if nanoGUI then
        nanoGUI.updateScreen = true
    end
    updateResponse(true)
end

NC.sendTime = computer.uptime()

function NC.update()
    if computer.uptime() > NC.sendTime then
        NC.sendTime = computer.uptime() + NC.Latency + (timedOut and 2)
        if NC.address == nil or NC.dat.port == nil then
            modem.broadcast(NC.CFG.port,"nanomachines","setResponsePort",NC.CFG.port)
            return
        end
        modem.send(NC.address,NC.CFG.port,"nanomachines",queries[queryIndex+1])
        queryIndex = (queryIndex + 1) % numQueries
    end
    updateResponse()
end

-- Handler for shell commands.
local commandArgs = {...}
local command = commandArgs[1]

if command then
    command = string.lower(command)
    table.remove(commandArgs,1)

    local aliases = {ver="version",v="version",s="stop",u="update"}
    local alias = aliases[command]
    if alias then command = alias end

    local env = setmetatable({},{__index = _G})

    env.NC = NC

    local func = loadfile(NC.LIB_DIR.."commands/"..command..".lua",nil,env)
    if func then
        func(table.unpack(commandArgs))
    else
        io.stderr:write("Invalid command.\n")
    end
    return false
end

nanoGUI = require("nanocontrol/nanoGUI")

local succeed, err = nanoGUI.init(NC)

if not succeed then error(err,1) end

