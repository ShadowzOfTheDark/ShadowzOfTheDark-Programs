-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- Update command

print("Updating NanoControl...")

local shell = require("shell")

shell.execute("oppm update nanocontrol")

require("computer").shutdown(true)
