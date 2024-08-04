-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- GUI

local component = require("component")
local event = require("event")
local colors = require("colors")

local nanoGUI = {}
local NC
local gpu, nativeW, nativeH
local oldScreen
local buffer
local running = false
local page = "status"
local updateButtons = false
local updateScreen = false

local events = {}
local defaultButtons = {}
local buttons = {}
local currentButtons
local pages = {}

local function tableCopy(t)
    local r = {}
    for k,v in pairs(t) do
        if type(v) == "table" then
            r[k] = tableCopy(v)
        else
            r[k] = v
        end
    end
    return r
end

local function pushBuffer()
    gpu.bitblt(0,nil,nil,nil,nil,buffer)
end

local function drawTitle()
    gpu.setBackground(colors.gray,true)
    gpu.setForeground(colors.white,true)
    gpu.fill(1,1,50,1," ")
    local str = "NanoControl "..NC.VER
    gpu.set(25-(#str/2),1,str)
end

local function drawButtons()
    for k,v in pairs(currentButtons) do
        v.render()
    end
end

local function drawStatusIndicator(text,back,fore)
    gpu.setBackground(back,true)
    gpu.setForeground(fore,true)
    gpu.fill(38,16,13,1," ")
    gpu.set(49-#text,16,text)
end

local function drawPage()
    gpu.setBackground(colors.black,true)
    gpu.setForeground(colors.white,true)
    gpu.fill(1,2,50,13," ")
    pages[page].render()
end

local function setup()
    buffer = gpu.allocateBuffer(50,16)
    assert(buffer,"Invalid buffer. Out of VRAM? (2) ("..gpu.freeMemory()/gpu.totalMemory().."% Left)")
    gpu.setActiveBuffer(buffer)
    drawTitle()
    drawButtons()
    drawPage()
    drawStatusIndicator("Searching",colors.red,colors.white)
    gpu.setActiveBuffer(0)
    gpu.setResolution(50,16)
    gpu.setActiveBuffer(buffer)
    pushBuffer()
end

local function reset()
    if buffer then gpu.freeBuffer(buffer) end
    gpu.setActiveBuffer(0)
    gpu.setResolution(nativeW,nativeH)
    gpu.bitblt(0,nil,nil,nil,nil,oldScreen)
    gpu.freeBuffer(oldScreen)
end

events.interrupted = function()
    running = false
end

events.modem_message = function(...)
    if NC.modem_message(...) then updateScreen = true end
end

defaultButtons.exit = {
    xMin=48,xMax=50,yMin=1,yMax=1,
    render=function()
        gpu.setBackground(colors.red,true)
        gpu.setForeground(colors.white,true)
        gpu.fill(48,1,3,1," ")
        gpu.fill(49,1,1,1,"X")
    end,
    callback=function()
        running = false
    end
}

defaultButtons.stop = {
    xMin=1,xMax=10,yMin=1,yMax=1,
    render=function()
        gpu.setBackground(colors.red,true)
        gpu.setForeground(colors.white,true)
        gpu.set(1,1,"STOP NANOS")
    end,
    callback = function()
    end
}

defaultButtons.status = {
    xMin=2,xMax=9,yMin=16,yMax=16,
    render = function()
        if page == "status" then
            gpu.setBackground(colors.cyan,true)
            gpu.setForeground(colors.white,true)
        else
            gpu.setBackground(colors.gray,true)
            gpu.setForeground(colors.silver,true)
        end
        gpu.fill(2,16,8,1," ")
        gpu.set(3,16,"Status")
    end,
    callback = function()
        page = "status"
        updateButtons = true
    end
}

defaultButtons.profiles = {
    xMin=11,xMax=20,yMin=16,yMax=16,
    render = function()
        if page == "profiles" then
            gpu.setBackground(colors.cyan,true)
            gpu.setForeground(colors.white,true)
        else
            gpu.setBackground(colors.gray,true)
            gpu.setForeground(colors.silver,true)
        end
        gpu.fill(11,16,10,1," ")
        gpu.set(12,16,"Profiles")
    end,
    callback = function()
        page = "profiles"
        updateButtons = true
    end
}

defaultButtons.inputs = {
    xMin=22,xMax=29,yMin=16,yMax=16,
    render = function()
        if page == "inputs" then
            gpu.setBackground(colors.cyan,true)
            gpu.setForeground(colors.white,true)
        else
            gpu.setBackground(colors.gray,true)
            gpu.setForeground(colors.silver,true)
        end
        gpu.fill(22,16,8,1," ")
        gpu.set(23,16,"Inputs")
    end,
    callback = function()
        page = "inputs"
        updateButtons = true
    end
}

defaultButtons.test = {
    xMin=31,xMax=36,yMin=16,yMax=16,
    render = function()
        if page == "test" then
            gpu.setBackground(colors.cyan,true)
            gpu.setForeground(colors.white,true)
        else
            gpu.setBackground(colors.gray,true)
            gpu.setForeground(colors.silver,true)
        end
        gpu.fill(31,16,6,1," ")
        gpu.set(32,16,"Test")
    end,
    callback = function()
        page = "test"
        updateButtons = true
    end
}

pages.status = {
    render = function()
        local toggle = true
        local function setText(x,y,txt,value)
            if value then
                if toggle then
                    gpu.setForeground(colors.white,true)
                else
                    gpu.setForeground(colors.silver,true)
                end
                gpu.set(x,y,txt..value)
            else
                gpu.setForeground(colors.gray,true)
                gpu.set(x,y,txt)
            end
            toggle = not toggle
        end
        setText(3,3,"Address: ",NC.address)
        setText(3,4,"Total Inputs: ",NC.dat.totalInputCount)
        setText(3,5,"Power: ",NC.dat.power and string.format("%%%.1f (%.0f/%.0f)",NC.dat.power[1]/NC.dat.power[2],NC.dat.power[1],NC.dat.power[2]))
    end
}

pages.profiles = {
    render = function() end
}

pages.inputs = {
    render = function() end
}

pages.test = {
    render = function() end
}


events.touch = function(adr,x,y,button)
    if adr == gpu.getScreen() then
        for button, info in pairs(currentButtons) do
            if x >= info.xMin and x <= info.xMax and y >= info.yMin and y <= info.yMax then
                info.callback(button)
            end
        end
    end
end

local function main()
    setup()
    while true do
        local eventData = {event.pull(NC.Latency)}
        if eventData then
            local func = events[eventData[1]]
            if func then
                table.remove(eventData,1)
                func(table.unpack(eventData))
            end
        end
        if not running then break end
        NC.update()
        if updateButtons then drawButtons() end
        if updateScreen then drawPage() end
        pushBuffer()
    end
end

function nanoGUI.init(nanocontrol)
    NC = nanocontrol
    gpu = component.gpu
    if gpu == nil then
        io.stderr:write("NanoControl requires a GPU for GUI usage!\n")
        return false
    end
    nativeW, nativeH = gpu.getResolution()
    print("Starting GUI...")
    running = true
    page = "status"
    currentButtons = tableCopy(defaultButtons)
    oldScreen = gpu.allocateBuffer(nativeW,nativeH)
    assert(oldScreen,"Invalid buffer. Out of VRAM? (1) ("..gpu.freeMemory()/gpu.totalMemory().."% Left)")
    gpu.bitblt(oldScreen,nil,nil,nil,nil,0)
    local succeed, err = pcall(main)
    reset()
    if not succeed then
        error(err)
    end
end

nanoGUI.drawStatusIndicator = drawStatusIndicator

return nanoGUI