-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- GUI

local component = require("component")
local event = require("event")

local nanoGUI = {}
local NC
local gpu, nativeW, nativeH
local oldScreen
local buffer
local running = false

local events = {}

events.interrupted = function()
    running = false
end

events.touch = function(adr,x,y,button)
    if adr == gpu.getScreen() then
        if x == 49 and y == 1 then
            running = false
        end
    end
end

local function pushBuffer()
    gpu.bitblt(0,nil,nil,nil,nil,buffer)
end

local function drawTitle()
    gpu.setActiveBuffer(buffer)
    gpu.setBackground(0x404040)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,1,50,1," ")
    local str = "NanoControl "..NC.VER
    gpu.set(25-(#str/2),1,str)
    gpu.setBackground(0xFF0000)
    gpu.fill(48,1,3,1," ")
    gpu.fill(49,1,1,1,"X")
    gpu.set(1,1,"STOP NANOS")
    gpu.setActiveBuffer(0)
end

local function setup()
    buffer = gpu.allocateBuffer(50,16)
    assert(buffer,"Invalid buffer. Out of VRAM? (2) ("..gpu.freeMemory()/gpu.totalMemory().."% Left)")
    drawTitle()
    gpu.setResolution(50,16)
    pushBuffer()
end

local function reset()
    if buffer then gpu.freeBuffer(buffer) end
    gpu.setActiveBuffer(0)
    gpu.setResolution(nativeW,nativeH)
    gpu.bitblt(0,nil,nil,nil,nil,oldScreen)
    gpu.freeBuffer(oldScreen)
end

local function main()
    setup()
    while true do
        local eventData = {event.pull(1)}
        if eventData then
            local func = events[eventData[1]]
            if func then
                table.remove(eventData,1)
                func(table.unpack(eventData))
            end
        end
        if not running then break end
    end
end

nanoGUI.init = function(nanocontrol)
    NC = nanocontrol
    gpu = component.gpu
    if gpu == nil then
        io.stderr:write("NanoControl requires a GPU for GUI usage!\n")
        return false
    end
    nativeW, nativeH = gpu.getResolution()
    print("Starting GUI...")
    running = true
    oldScreen = gpu.allocateBuffer(nativeW,nativeH)
    assert(oldScreen,"Invalid buffer. Out of VRAM? (1) ("..gpu.freeMemory()/gpu.totalMemory().."% Left)")
    gpu.bitblt(oldScreen,nil,nil,nil,nil,0)
    local succeed, err = pcall(main)
    reset()
    if not succeed then
        error(err)
    end
end

return nanoGUI