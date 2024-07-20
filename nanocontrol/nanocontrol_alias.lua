-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- This script runs at boot to enable the "nc" alias shortcut.

local shell = require("shell")

local function setAlias()
    if _G.runlevel == 1 then
        shell.setAlias("nc","nanocontrol")
        return true
    end
    return false
end

function start()
    local event = require("event")
    if not setAlias() then
        ID = event.timer(1,function()
            if setAlias() then
                event.cancel(ID)
            end
        end,math.huge)
    end
end

function stop()
    shell.setAlias("nc")
end