-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Version command

local changed = ...

if changed == true then
    print("NanoControl is now version: "..NC.VER)
else
    print("NanoControl version: "..NC.VER)
end
