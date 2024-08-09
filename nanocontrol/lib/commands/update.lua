-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Update command

local arg = {...}

print("Updating NanoControl: "..NC.VER)

package.loaded["nanocontrol/nanoGUI"] = nil

if arg[1] ~= "local" then

    local shell = require("shell")

    shell.execute("oppm update nanocontrol")

    shell.execute("nanocontrol version update")

end