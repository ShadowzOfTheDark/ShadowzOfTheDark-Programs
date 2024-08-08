-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Version command

local arg = {...}

if arg[1] == "update" then
    print("NanoControl is now version: "..NC.VER)
else
    print("NanoControl version: "..NC.VER)
end
