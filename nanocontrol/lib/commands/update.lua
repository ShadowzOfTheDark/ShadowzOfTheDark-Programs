-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Update command

print("Updating NanoControl: "..NC.VER)

package.loaded["nanocontrol/nanoGUI"] = nil

local shell = require("shell")

shell.execute("oppm update nanocontrol")

shell.execute("nanocontrol version update")
