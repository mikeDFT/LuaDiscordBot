local module = {}
--local utils = require("../utils/utils")
local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local env = require("../.env")

local utils = require("utils")
local websocketModule = require("websocket")
local funStuffModule = require("funStuff")

utils.settings = {
    shards = 1,
    max_concurrency = 1,
    identified = false,
    chances = {
        forStopTyping = 35, -- out of 100
        forMocking = 69,
        forReaction = 40,
    }
}

local insultsTable = {
    "square", "peanut", "idot"
}

module.dispatchTypes = {
    ["INTERACTION_CREATE"] = function(message)
        print(message)
        -- net.request({
        --     url = `https://discord.com/api/v6//applications/{utils.settings.application_id}/commands/{message.d.data.id}`,
        --     method = "GET",
        --     headers = {
        --         ["authorization"] = `Bot {env.DISCORD_BOT_TOKEN}`,
        --         ["content-type"] = "application/json"
        --     },
        --     body = {
        --         command_id = message.id
        --     }
        -- })
        
        if not message.d.data.name or not funStuffModule.games[message.d.data.name] then return end

        local cTable = {
            type = 4,
            data = funStuffModule.games[message.d.data.name](message.d.data, message),
        }

        funStuffModule.sendPostRequest(cTable, {message.d.id, message.d.token}, "interaction")
    end,

    ["MESSAGE_CREATE"] = function(message)
        --print(message)
        if not message.d.author.bot and math.random(1, 100) <= utils.settings.chances.forMocking then
            print("mocking")
            local cTable = {
                content = `"{message.d.content}" :eyes:`
            }

            funStuffModule.sendPostRequest(cTable, {message.d.channel_id}, "message")
        end
    end,

    ["TYPING_START"] = function(message)
        if math.random(1, 100) <= utils.settings.chances.forStopTyping then
            print("stop typing")
            local cTable = {
                content = `<@{message.d.member.user.id}> stop typing, {insultsTable[math.random(1, #insultsTable)]}`
            }

            funStuffModule.sendPostRequest(cTable, {message.d.channel_id}, "message")
        end
    end,

    ["READY"] = function(message)
        print(message)
        utils.settings.resume_gateway_url = message.d.resume_gateway_url
        utils.settings.session_id = message.d.session_id
        utils.settings.application_id = message.d.application.id
        print("ready message received " .. utils.settings.resume_gateway_url)

        module.afterReady()
    end,

    ["PRESENCE_UPDATE"] = function(message)
        if message.d.user and message.d.user.id == "[insert userid to ignore]" then
            print("this is [], ignoring")
        else
            print(message)
        end
    end,
}

module.cases = {
    [utils.WebsocketCodes.Hello] = function(message) -- 10
        print(message)
        websocketModule.startHeartbeat(message.d.heartbeat_interval/1000)
    end,

    [utils.WebsocketCodes.Heartbeat] = function(_) -- 1
        websocketModule.instantHeartbeat(utils.settings.socket)
    end,

    [utils.WebsocketCodes.HeartbeatACK] = function(_) -- 11
        websocketModule.heartbeatACKed = true

        if not module.identified then
            module.identified = true

            local identifyString = serde.encode("json", {
                op = 2,
                d = {
                    token = env.DISCORD_BOT_TOKEN,
                    intents = 3276798,
                    properties = {
                        os = "windows",
                        browser = "teehee",
                        device = "teehee"
                    }
                }
            })

            utils.settings.socket.send(identifyString)
        end
    end,

    [utils.WebsocketCodes.Dispatch] = function(message) -- 0
        print(message.t)
        utils.settings.lastS = message.s

        if module.dispatchTypes[message.t] then
            module.dispatchTypes[message.t](message)
        end
    end,

    [utils.WebsocketCodes.Reconnect] = function(_) -- 7
        module.resumeConnection()
    end,

    [utils.WebsocketCodes.InvalidSession] = function(message) -- 9
        if message.d then
            module.resumeConnection()
        else
            websocketModule.disconnectSession()
        end
    end,
}


function module.startConnection()
    local response = net.request({
        url = "https://discord.com/api/gateway/bot",
        method = "GET",
        headers = {
            ["authorization"] = `Bot {env.DISCORD_BOT_TOKEN}`,
			["content-type"] = "application/json"
        },
    })

    if response.statusMessage == "OK" then
        local decodedBody = serde.decode("json", response.body)

        utils.settings.shards = decodedBody.shards
        utils.settings.max_concurrency = decodedBody.session_start_limit.max_concurrency
        utils.settings.url = decodedBody.url

        utils.settings.socket = net.socket(utils.settings.url)

        function utils.functions.spawnNextThread()
            if utils.settings.thread then
                task.cancel(utils.settings.thread)
            end

            utils.settings.thread = task.spawn(function()
                while true do
                    local encoded = utils.settings.socket.next()
                    if not encoded then break end
                    local message = serde.decode("json", encoded)
    
                    print("op: " .. message.op)
                    local func = module.cases[message.op]
                    if func then
                        func(message)
                    else
                        print(`no function with op {message.op}:`)
                        print(message)
                    end
                end
            end)
        end

        utils.functions.spawnNextThread()
    end
end

function module.afterReady()
    --funStuffModule.botOnline()
    --funStuffModule.createCommand()

    --[[ -- get all commands ids
        print(
            net.request({
                url = `https://discord.com/api/v6/applications/1133333306612662402/commands`,
                method = "GET",
                headers = {
                    ["authorization"] = `Bot {env.DISCORD_BOT_TOKEN}`,
                    ["content-type"] = "application/json"
                },
            })
        )]]

        --[[ -- delete command with the command id
        print(
            net.request({
                url = `https://discord.com/api/v6/applications/1133333306612662402/commands/1133725999276752998`,
                method = "DELETE",
                headers = {
                    ["authorization"] = `Bot {env.DISCORD_BOT_TOKEN}`,
                    ["content-type"] = "application/json"
                },
            })
        )]]
end

return module