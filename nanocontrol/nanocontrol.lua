-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Main program entry point

local VER = {1,1,0}
local BIN_DIR = "/nanocontrolbin/"

-- This is the default server config values for the nanomachines.
-- If your server has configs changed modify these to reflect that.
local SERVER = {}
SERVER.commandDelay = 1
SERVER.commandRange = 2
SERVER.maxInputs = 2
SERVER.maxInputsActive = 4
SERVER.maxOutputs = 2
SERVER.safeInputsActive = 2
SERVER.triggerQuota = 0.4

-- This just adds a shorthand 'nc' command with setup at boot.
if require("rc").loaded.nanocontrol_alias == nil then
    print("Welcome to NanoControl!")
    print("Adding 'nc' shorthand alias for 'nanocontrol'.")
    local shell = require("shell")
    shell.execute("rc nanocontrol_alias enable")
    shell.execute("rc nanocontrol_alias start")
    os.sleep(3)
end

-- Handler for shell commands.
local commandArgs = {...}
local command = commandArgs[1]

if command then
    command = string.lower(command)
    table.remove(commandArgs,1)

    local func = loadfile(BIN_DIR..command..".lua")
    if func then
        func(table.unpack(commandArgs))
    else
        io.stderr:write("Invalid command.")
    end
    return
end
