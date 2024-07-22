local component = require("component")
local event = require("event")
local telescope = component.telescope
local counter = 0
local right = true
local down = true
local vertical = false
local verticalCounter = 0
local tracking = false

print("Be sure telescope is set to speed 10.")
print("CTRL+C to Exit.")

telescope.rotateTelescope(-2000,-2000)

local function track()
    local observation = telescope.getObservationStatus()
    if observation.object ~= "" then
        if not tracking then
            tracking = observation.object
            print("Tracking: "..tracking)
        end
        telescope.rotateTelescope(observation.relative_x, observation.relative_y)
        os.sleep(3)
        return true
    end
    if tracking then
        local success = false
        for k,object in ipairs(telescope.getResearchedBodies()) do
            if object == tracking then
                success = true
                print("Successfully researched object: "..tracking)
                break
            end
        end
        if not success then
            print("Failed to research object: "..tracking)
        end
        tracking = false
        counter = 0
        telescope.rotateTelescope(-2000,-2000)
        right = true
        down = true
        vertical = false
        verticalCounter = 0
    end
    return false
end

local function scan()
    if vertical then
        counter = 47
        if down then
            telescope.rotateTelescope(0,50)
        else
            telescope.rotateTelescope(0,-50)
        end
        verticalCounter = verticalCounter + 1
        if verticalCounter >= 20 then
            verticalCounter = 0
            down = not down
        end
    else
        counter = 0
        if right then
            telescope.rotateTelescope(2000,0)
        else
            telescope.rotateTelescope(-2000,0)
        end
        right = not right
    end
    vertical = not vertical
end

while not event.pull(0.1, "interrupted") do
    track()
    if not tracking then
        counter = counter + 1
        if counter >= 51 then
            scan()
        end
    end
end