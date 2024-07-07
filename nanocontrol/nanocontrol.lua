-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

local VER = {1,0,5}
local DIR = "/nanomachines/"
local port = 17061

local DEFAULT_INPUTS = 18
local CONNECT_ATTEMPTS = 3
local CONNECT_TIME = 2

local component = require("component")
local term = require("term")
local event = require("event")

local gpu = component.gpu
if gpu == nil then error("NanoControl requires a GPU to function!") end
local w, h = gpu.getResolution()
local buffer

local modem = component.modem
if modem == nil then error("NanoControl requires a wireless network card!") end
if not modem.isWireless() then
    gpu.setForeground(0xFF0000)
    print("Detected a network card but isn't wireless. Trying anyway...")
    gpu.setForeground(0xFFFFFF)
    os.sleep(2)
end
modem.open(port)

local running = true

local function pushBuffer()
    gpu.bitblt(0,1,1,w,h,buffer,1,1)
end

local function resetScreen()
    gpu.freeBuffer(buffer)
    gpu.setActiveBuffer(0)
    gpu.setResolution(w,h)
    term.clear()
    term.setCursorBlink(true)
end

local function drawText(str,x,y)
    x = x - 1
    for i = 1, #str do
        local char = str:sub(i,i)
        gpu.fill(x+i,y,1,1,char)
    end
end

local function drawTitle()
    gpu.setBackground(0x404040)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1,1,50,1," ")
    local str = string.format("NanoControl v%i.%i.%i",table.unpack(VER))
    drawText(str,25-(#str/2),1)
    gpu.setBackground(0xFF0000)
    gpu.fill(48,1,3,1," ")
    gpu.fill(49,1,1,1,"X")
    term.setCursor(1,1)
    term.write("STOP NANOS",false)
end

local events = {}

events.interrupted = function()
    running = false
end

local function init()
    buffer = gpu.allocateBuffer(50,16)
    gpu.setResolution(50,16)
    gpu.setActiveBuffer(buffer)
    pushBuffer()
end

local function main()
    term.clear()
    term.setCursorBlink(false)
    drawTitle()
    pushBuffer()
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

local function broadcastTry(func,...)
    for i=1, CONNECT_ATTEMPTS do
        modem.broadcast(port,...)
        data = {event.pull(CONNECT_TIME,"modem_message")}
        if data[1] == "modem_message" then
            table.remove(data,1)
            if func(table.unpack(data)) then
                return true
            end
        end
    end
    return false
end

local function sendTry(adr,func,...)
    for i=1, CONNECT_ATTEMPTS do
        modem.send(adr,port,...)
        data = {event.pull(CONNECT_TIME,"modem_message")}
        if data[1] == "modem_message" then
            table.remove(data,1)
            if func(table.unpack(data)) then
                return true
            end
        end
    end
    return false
end

local function stopNanos()
    print("Turning off all nanomachine inputs...")
    print(string.format("Setting response port to %i.",port))
    modem.open(port)
    local test = true
    local adr
    local inputs = DEFAULT_INPUTS

    local connected = broadcastTry(function(_, a,p,d,name)
        if name == "nanomachines" and type(d) == "number" and d <= 2 and p==port then
            print(string.format("Nanomachines %s... set to port %i.",a:sub(1,15),p))
            adr = a
            return true
        end
    end,"nanomachines","setResponsePort",port)

    if connected then
        term.write("Getting inputs...")
        local succeed = sendTry(adr,function(_, _, _, _, _, id, count)
            if id == "totalInputCount" then
                inputs = count
                print(" Detected "..count.." inputs.")
                return true
            end
        end,"nanomachines","getTotalInputCount")
        if not succeed then
            gpu.setForeground(0xFF0000)
            print(" Failed. Using default of "..DEFAULT_INPUTS..".")
            gpu.setForeground(0xFFFFFF)
        end
        for i=1,inputs do
            term.write("Shutting off #"..i)
            local succeed = sendTry(adr,function(_, _, _, _, _, id, x, status)
                if id == "input" and x==i and status==false then
                    print(" Success.")
                    return true
                end
            end,"nanomachines","setInput",i,false)
            if not succeed then
                gpu.setForeground(0xFF0000)
                print(" Failed.")
                gpu.setForeground(0xFFFFFF)
            end
        end
    else
        gpu.setForeground(0xFF0000)
        print("Failed to connect to nanomachines. Are you too far?")
        gpu.setForeground(0xFFFFFF)
        print("Throwing blind shutdown calls...")
    end

end

local commands = {
    stop=stopNanos,
    off=stopNanos,
    s=stopNanos,
    o=stopNanos
}

local args = {...}
local command
local func
if args[1] then
    command = string.lower(args[1])
    table.remove(args,1)

    func = commands[command]
end

if func then
    func(args)
else
    init()
    local succeed, err = pcall(main)
    resetScreen()
    if not succeed then
        error(err,2)
    end
end