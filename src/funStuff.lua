local env = require("../.env")

local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local utils = require("utils")

local module = {
    message = {
        url = function(channel_id)
            return `channels/{channel_id}/messages`
        end,

        -- default
        rateLimit = 5,
        rateLimitRemaining = 5,
        rateLimitResetAfter = 0,
        lastMessageSentAt = 0,
    },
    interaction = {
        url = function(interaction_id, interaction_token)
            return `interactions/{interaction_id}/{interaction_token}/callback`
        end,

        -- default
        rateLimit = 5,
        rateLimitRemaining = 5,
        rateLimitResetAfter = 0,
        lastMessageSentAt = 0,
    },
}

function module.botOnline()
    local cTable = {
        content = "Welcome! I have become aware :D",
        description = "cool",
    }

    module.sendMessage(cTable, "1133334702799986730")

    cTable = {
        content = "https://tenor.com/view/baby-yoda-welcome-gif-22416975",
        description = "cool",
    }

    module.sendMessage(cTable, "1133334702799986730")
end

function module.sendPostRequest(cTable, ids, _type, important, dontprint)
    local _settings = module[_type]

    if _settings.rateLimitRemaining <= 0 and os.clock() - _settings.lastMessageSentAt < _settings.rateLimitResetAfter then
        if not important then return end
        task.wait(_settings.lastMessageSentAt - os.clock() + _settings.rateLimitResetAfter +.05)
    end

    local encodedTable = serde.encode("json", cTable)

    local infoTable = net.request({
        url = `https://discord.com/api/v6/{_settings.url(unpack(ids))}`,
        method = "POST",
        headers = {
            ["authorization"] = `Bot {env.DISCORD_BOT_TOKEN}`,
            ["content-type"] = "application/json"
        },
        body = encodedTable
    })

    if not dontprint then
        print(infoTable)
    end

    _settings.rateLimit = tonumber(infoTable.headers["x-ratelimit-limit"])
    _settings.rateLimitRemaining = tonumber(infoTable.headers["x-ratelimit-remaining"])
    _settings.rateLimitResetAfter = tonumber(infoTable.headers["x-ratelimit-reset-after"])

    _settings.lastMessageSentAt = os.clock()
end

local commandsTable = {
    flipcoin = {
        name = "flipcoin",
        type = 1,
        description = "flip a coin, get heads or tails"
    },

    rock_paper_scissors = {
        name = "rock_paper_scissors",
        type = 1,
        description = "play rock paper scissors, choose one",
        options = {
            {
                name = "choice",
                description = "choose a move",
                type = 3,
                required = true,
                choices = {
                    {
                        name = "Rock",
                        value = "Rock"
                    },
                    {
                        name = "Paper",
                        value = "Paper"
                    },
                    {
                        name = "Scissors",
                        value = "Scissors"
                    }
                }
            }
        }
    },

    minesweeper = {
        name = "minesweeper",
        type = 1,
        description = "play minesweeper on discord!",
        options = {
            {
                name = "difficulty",
                description = "choose difficulty",
                type = 3,
                required = true,
                choices = {
                    {
                        name = "Easy",
                        value = "Easy"
                    },
                    {
                        name = "Medium",
                        value = "Medium"
                    },
                    {
                        name = "Hard",
                        value = "Hard"
                    }
                }
            },
            {
                name = "gridsize_presets",
                description = "choose gridsize (default = medium)",
                type = 3,
                required = false,
                choices = {
                    {
                        name = "Small (7x7)",
                        value = "Small"
                    },
                    {
                        name = "Medium (15x15)",
                        value = "Medium"
                    },
                    {
                        name = "Big (25x25)",
                        value = "Big"
                    }
                }
            },
            {
                name = "custom_gridsize",
                description = "choose custom gridsize size (just a number), max is 30",
                type = 4,
                required = false,
            }
        }
    }
}

function module.createCommand()
    print(1)

    local cTable = commandsTable.minesweeper

    local infoTable = net.request({
        url = `https://discord.com/api/v6/applications/{utils.settings.application_id}/commands`,
        method = "POST",
        headers = {
            ["authorization"] = `Bot {env.DISCORD_BOT_TOKEN}`,
            ["content-type"] = "application/json"
        },
        body = serde.encode("json", cTable);
    })

    print(infoTable)
end

local gamesTable = {
    rock_paper_scissors = {
        choices = {
            "Rock", "Paper", "Scissors",
        },
        choicesBack = {
            Rock = 1,
            Paper = 2,
            Scissors = 3,
        },
        outcomes = {
            "you won", "draw", "you lost",
        },
    },
    minesweeper = {
        gridsizePresets = {
            Small = 7,
            Medium = 15,
            Big = 25,
            Default = 15, -- (medium)
        },
        maxGridsize = 30,
        difficultySizeRatio = {
            Easy = .08,
            Medium = .15,
            Hard = .3,
        },
        maxInMessage = 90,
        nrEmojiName = {
            [0] = "0️⃣",
            "1️⃣",
            "2️⃣",
            "3️⃣",
            "4️⃣",
            "5️⃣",
            "6️⃣",
            "7️⃣",
            "8️⃣",
        }
    }
}

module.games = {
    flipcoin = function()
        return  {
            content = math.random()<.5 and "Heads" or "Tails",
        }
    end,

    rock_paper_scissors = function(data)
        local nrChoice = math.random(1, 3)
        local userNrChoice = gamesTable.rock_paper_scissors.choicesBack[data.options[1].value]

        local outcome = gamesTable.rock_paper_scissors.outcomes[(nrChoice-userNrChoice+1)%3+1]

        return  {
            content = `{data.options[1].value} vs {gamesTable.rock_paper_scissors.choices[nrChoice]}, {outcome}`
        }
    end,

    minesweeper = function(data, message)
        print(data)
        local _s = {
            diff = data.options[1].value,
        }

        if data.options[2] then
            _s.size = data.options[2].name == "gridsize_presets" and gamesTable.minesweeper.gridsizePresets[data.options[2].value] or data.options[2].value
            if _s.size >  gamesTable.minesweeper.maxGridsize then
                _s.size = gamesTable.minesweeper.maxGridsize
            end
        else
            _s.size = gamesTable.minesweeper.gridsizePresets.Default
        end
        print(_s.size)

        _s.bombNr = math.ceil(_s.size * _s.size * gamesTable.minesweeper.difficultySizeRatio[_s.diff])
        _s.splitEveryNRows = math.floor(gamesTable.minesweeper.maxInMessage / _s.size)
        

        local grid = {}
        for i = 1, _s.size+2 do
            grid[i] = {}
            for j = 1, _s.size+2 do
                if i==1 or i==_s.size+2 or j==1 or j==_s.size+2 then
                    grid[i][j] = nil
                else
                    grid[i][j] = false
                end
            end
        end

        for _ = 1, _s.bombNr do
            local i, j = math.random(2, _s.size+1), math.random(2, _s.size+1)

            while grid[i][j] do
                i, j = math.random(2, _s.size+1), math.random(2, _s.size+1)
            end

            grid[i][j]=true
        end

        for i = 2, _s.size+1 do
            for j = 2, _s.size+1 do
                if grid[i][j] == false then
                    local nr=0
                    for x = -1, 1 do
                        for y = -1, 1 do
                            if grid[i+x][j+y]==true then
                                nr+=1
                            end
                        end
                    end
                    grid[i][j] = nr
                end
            end
        end

        --local nrOfStrings = _s.size/_s.splitEveryNRows
        local strings = {""}
        local strNr = 1
        for i = 2, _s.size+1 do
            for j = 2, _s.size+1 do
                if grid[i][j] == true then
                    strings[strNr] ..= "||💣||"
                else
                    strings[strNr] ..= `||{gamesTable.minesweeper.nrEmojiName[grid[i][j]]}||`
                end
            end

            if (i-1) - _s.splitEveryNRows*(strNr-1) >= _s.splitEveryNRows then
                strNr+=1
                strings[strNr] = ""
            else
                strings[strNr] ..= "\n"
            end
        end

        if strNr>1 then
            task.spawn(function()
                task.wait(.1)
                for i=2, strNr do
                    module.sendPostRequest({
                        content = strings[i],
                    }, {message.d.channel.id}, "message", true, true)
                end
            end)
        end

        return  {
            content = strings[1]
        }
    end,

    purge = function(_, message)
        
    end
}

--[[
    local cTable = {
        name = "blep",
        type = 1,
        description = "Send a random adorable animal photo",
        options = {
            {
                name = "animal",
                description = "The type of animal",
                type = 3,
                required = true,
                choices = {
                    {
                        name = "Dog",
                        value = "animal_dog"
                    },
                    {
                        name = "Cat",
                        value = "animal_cat"
                    },
                    {
                        name = "Penguin",
                        value = "animal_penguin"
                    }
                }
            },
            {
                name = "only_smol",
                description = "Whether to show only baby animals",
                type = 5,
                required = false
            }
        }
    }
]]




return module