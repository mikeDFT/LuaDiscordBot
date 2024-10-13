local module = {}
local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local env = require("../.env")
local utils = require("utils")

module.connected = false
module.heartbeatACKed = false

function module.instantHeartbeat()
    local encodedMessage = serde.encode("json", {
        op = utils.WebsocketCodes.Heartbeat,
        d = false,
    })

    --print("sent!")
    utils.settings.socket.send(encodedMessage)
end

function module.startHeartbeat(timeInterval)
    local connectionTime = os.clock()
    module.connected = connectionTime

    task.spawn(function()
        while module.connected == connectionTime do
            module.instantHeartbeat()
            
            task.wait(timeInterval * math.random())
            --print(`heartbeatACK status: {module.heartbeatACKed}`)
            if not module.heartbeatACKed then
                module.resumeConnection()
            else
                module.heartbeatACKed = false
            end
        end
    end)
end

function module.resumeConnection()
    module.terminateHeartbeat()
    local Table = {
        op = 6,
        d = {
          token = env.DISCORD_BOT_TOKEN,
          session_id = utils.settings.session_id,
          seq = utils.settings.lastS
        }
    }
    local encodedMessage = serde.encode("json", Table)

    print("attempted resume!")
    print(Table, encodedMessage)
    utils.settings.socket = net.socket(utils.settings.resume_gateway_url)
    utils.functions.spawnNextThread()
    utils.settings.socket.send(encodedMessage)
    print("attempted resume ended")
end

function module.terminateHeartbeat()
    module.connected = false

    if utils.settings.socket then
        utils.settings.socket.close(1005)
        print("socket closed")
    end
end

function module.disconnectSession()
    print("disconnecting session (not implemented)")
end

return module