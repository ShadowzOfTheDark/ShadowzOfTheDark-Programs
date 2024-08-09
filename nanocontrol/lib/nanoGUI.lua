-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- GUI

local component = require("component")
local event = require("event")
local computer = require("computer")

local nanoGUI = {}
local NC
local gpu, nativeW, nativeH
local oldScreen
local buffer
local running = false
local page = "status"
local updateButtons = true
nanoGUI.updateScreen = false

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
    gpu.setBackground(0x333333)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,1,50,1," ")
    local str = "NanoControl "..NC.VER
    gpu.set(25-(#str/2),1,str)
end

local function drawButtons()
    for k,v in pairs(currentButtons) do
        v.render()
    end
    updateButtons = false
end

local function drawStatusIndicator(text,back,fore)
    gpu.setBackground(back)
    gpu.setForeground(fore)
    gpu.fill(38,16,13,1," ")
    gpu.set(49-#text,16,text)
end

function NC.drawPage()
    gpu.setBackground(0x000000)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,2,50,13," ")
    pages[page].render()
    local pageButtons = pages[page].buttons
    if pageButtons then
        for k,info in pairs(pageButtons) do
            info.render()
        end
    end
end

local function setup()
    buffer = gpu.allocateBuffer(50,16)
    assert(buffer,"Invalid buffer. Out of VRAM? (2) ("..gpu.freeMemory()/gpu.totalMemory().."% Left)")
    gpu.setActiveBuffer(buffer)
    drawTitle()
    drawButtons()
    NC.drawPage()
    drawStatusIndicator("Searching",0xFF3333,0xFFFFFF)
    gpu.setActiveBuffer(0)
    gpu.setResolution(50,16)
    gpu.setActiveBuffer(buffer)
    pushBuffer()
end

local function reset()
    if buffer then gpu.freeBuffer(buffer) end
    gpu.setActiveBuffer(0)
    gpu.setDepth(4)
    gpu.setResolution(nativeW,nativeH)
    gpu.bitblt(0,nil,nil,nil,nil,oldScreen)
    gpu.freeBuffer(oldScreen)
end

events.interrupted = function()
    running = false
end

defaultButtons.exit = {
    xMin=48,xMax=50,yMin=1,yMax=1,
    render=function()
        gpu.setBackground(0xFF3333)
        gpu.setForeground(0xFFFFFF)
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
        gpu.setBackground(0xFF3333)
        gpu.setForeground(0xFFFFFF)
        gpu.set(1,1,"STOP NANOS")
    end,
    callback = function()
    end
}

defaultButtons.disconnect = {
    xMin=38,xMax=50,yMin=16,yMax=16,
    render=function() end,
    callback=function()
        NC.disconnect()
    end
}

defaultButtons.status = {
    xMin=2,xMax=9,yMin=16,yMax=16,
    render = function()
        if page == "status" then
            gpu.setBackground(0x336699)
            gpu.setForeground(0xFFFFFF)
        else
            gpu.setBackground(0x333333)
            gpu.setForeground(0xCCCCCC)
        end
        gpu.fill(2,16,8,1," ")
        gpu.set(3,16,"Status")
    end,
    callback = function()
        page = "status"
        updateButtons = true
        nanoGUI.updateScreen = true
    end
}

defaultButtons.profiles = {
    xMin=11,xMax=20,yMin=16,yMax=16,
    render = function()
        if page == "profiles" then
            gpu.setBackground(0x336699)
            gpu.setForeground(0xFFFFFF)
        else
            gpu.setBackground(0x333333)
            gpu.setForeground(0xCCCCCC)
        end
        gpu.fill(11,16,10,1," ")
        gpu.set(12,16,"Profiles")
    end,
    callback = function()
        page = "profiles"
        updateButtons = true
        nanoGUI.updateScreen = true
    end
}

defaultButtons.inputs = {
    xMin=22,xMax=29,yMin=16,yMax=16,
    render = function()
        if page == "inputs" then
            gpu.setBackground(0x336699)
            gpu.setForeground(0xFFFFFF)
        else
            gpu.setBackground(0x333333)
            gpu.setForeground(0xCCCCCC)
        end
        gpu.fill(22,16,8,1," ")
        gpu.set(23,16,"Inputs")
    end,
    callback = function()
        page = "inputs"
        updateButtons = true
        nanoGUI.updateScreen = true
    end
}

defaultButtons.test = {
    xMin=31,xMax=36,yMin=16,yMax=16,
    render = function()
        if page == "test" then
            gpu.setBackground(0x336699)
            gpu.setForeground(0xFFFFFF)
        else
            gpu.setBackground(0x333333)
            gpu.setForeground(0xCCCCCC)
        end
        gpu.fill(31,16,6,1," ")
        gpu.set(32,16,"Test")
    end,
    callback = function()
        page = "test"
        updateButtons = true
        nanoGUI.updateScreen = true
    end
}

pages.status = {
    effectPage = 0,
    render = function()
        if not NC.connected then
            pages.status.effectPage = 0
        end
        if pages.status.effectPage == 0 then
            pages.status.renderStatus()
        else
            pages.status.renderEffects()
        end
    end,
    renderEffects = function()
    end,
    renderStatus = function()
        local toggle = true
        local y = 3
        local function setText(txt,value)
            if value then
                if toggle then
                    gpu.setForeground(0xFFFFFF)
                else
                    gpu.setForeground(0xCCCCCC)
                end
                gpu.set(3,y,txt..value)
            else
                gpu.setForeground(0x333333)
                gpu.set(3,y,txt)
            end
            y = y + 1
            toggle = not toggle
        end
        local function setDouble(txt,tbl)
            setText(txt,tbl and string.format("%%%.1f (%.0f/%.0f)",tbl[1]/tbl[2]*100,tbl[1],tbl[2]))
        end
        setText("Address: ",NC.address)
        setText("Total Inputs: ",NC.dat.totalInputCount)
        setDouble("Power: ",NC.dat.power)
        setText("Name: ",NC.dat.name)
        setText("Age: ",NC.dat.age)
        setDouble("Health: ",NC.dat.health)
        setText("Hunger: ",NC.dat.hunger and string.format("%.2f",NC.dat.hunger[1]))
        setText("Saturation: ",NC.dat.hunger and string.format("%.2f",NC.dat.hunger[2]))
        setText("Experience: ",NC.dat.experience)
    end,
    buttons = {
        left = {
            xMin=1,xMax=1,yMin=7,yMax=8,
            render=function()
                if pages.status.effectPage > 0 then
                    gpu.setBackground(0x336699)
                    gpu.setForeground(0xFFFFFF)
                else
                    gpu.setBackground(0x333333)
                    gpu.setForeground(0xCCCCCC)
                end
                gpu.fill(1,7,1,1,"/")
                gpu.fill(1,8,1,1,"\\")
            end,
            callback = function()
                if pages.status.effectPage > 0 then
                    pages.status.effectPage = math.max(0,pages.status.effectPage - 1)
                end
                nanoGUI.updateScreen = true
            end
        },
        right = {
            xMin=50,xMax=50,yMin=7,yMax=8,
            render=function()
                if pages.status.effectPage == 0 and NC.connected then
                    gpu.setBackground(0x336699)
                    gpu.setForeground(0xFFFFFF)
                else
                    gpu.setBackground(0x333333)
                    gpu.setForeground(0xCCCCCC)
                end
                gpu.fill(50,7,1,1,"\\")
                gpu.fill(50,8,1,1,"/")
            end,
            callback = function()
                if pages.status.effectPage == 0 then
                    pages.status.effectPage = math.min(1,pages.status.effectPage + 1)
                end
                nanoGUI.updateScreen = true
            end
        }
    }
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
        local pageButtons = pages[page].buttons
        if pageButtons then
            for button, info in pairs(pageButtons) do
                if x >= info.xMin and x <= info.xMax and y >= info.yMin and y <= info.yMax then
                    info.callback(button)
                end
            end
        end
    end
end

local function main()
    setup()
    while true do
        local eventData = {event.pull(NC.sendTime-computer.uptime())}
        if eventData then
            local func = events[eventData[1]]
            if func then
                table.remove(eventData,1)
                func(table.unpack(eventData))
            end
        end
        if not running then break end
        NC.update()
        if nanoGUI.updateScreen then NC.drawPage() end
        if updateButtons then drawButtons() end
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
    events.modem_message = NC.modem_message
    running = true
    page = "status"
    currentButtons = tableCopy(defaultButtons)
    oldScreen = gpu.allocateBuffer(nativeW,nativeH)
    assert(oldScreen,"Invalid buffer. Out of VRAM? (1) ("..gpu.freeMemory()/gpu.totalMemory().."% Left)")
    gpu.bitblt(oldScreen,nil,nil,nil,nil,0)
    gpu.setDepth(gpu.maxDepth())
    local succeed, err = pcall(main)
    reset()
    return succeed, err
end

nanoGUI.drawStatusIndicator = drawStatusIndicator

return nanoGUI