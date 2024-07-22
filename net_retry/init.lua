-- NanoControl
-- A program with GUI and commands to better control your nanomachines.
-- https://github.com/ShadowzOfTheDark/ShadowzOfTheDark-Programs/nanomachines

-- This library is designed to send a modem message out until a response.

local math = require("math")
local computer = require("computer")

local net_retry = {
    time=5,
    wait=2,
    port=1,
}

net_retry.broadcastTry = function(callback,...)
    local stop = computer.uptime() + net_retry.time
    while computer.uptime() < stop do
        net_retry.modem.broadcast(net_retry.port,...)
        local time = math.min(stop-computer.uptime(),net_retry.wait)
        data = {event.pull(time,"modem_message")}
        if data[1] == "modem_message" then
            table.remove(data,1)
            if callback(table.unpack(data)) then
                return true
            end
        end
    end
    return false
end

net_retry.sendTry = function(adr,callback,...)
    local stop = computer.uptime() + net_retry.time
    while computer.uptime() < stop do
        net_retry.modem.broadcast(adr,net_retry.port,...)
        local time = math.min(stop-computer.uptime(),net_retry.wait)
        data = {event.pull(time,"modem_message")}
        if data[1] == "modem_message" then
            table.remove(data,1)
            if callback(table.unpack(data)) then
                return true
            end
        end
    end
    return false
end

return net_retry