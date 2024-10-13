local module = {
    WebsocketCodes1 = {
        [0] = "Dispatch",
        "Heartbeat",
        "Identify",
        "PresenseUpdate",
        "VoiceStateUpdate",
        "",
        "Resume",
        "Reconnect",
        "RequestGuildMembers",
        "InvalidSession",
        "Hello",
        "HeartbeatACK",
    },

    WebsocketCodes = {
        ["Dispatch"] = 0,
        ["Heartbeat"] = 1,
        ["Identify"] = 2,
        ["PresenseUpdate"] = 3,
        ["VoiceStateUpdate"] = 4,
        ["Resume"] = 6,
        ["Reconnect"] = 7,
        ["RequestGuildMembers"] = 8,
        ["InvalidSession"] = 9,
        ["Hello"] = 10,
        ["HeartbeatACK"] = 11,
    },

    --[[
        more codes at  https://discord.com/developers/docs/topics/opcodes-and-status-codes#gateway-gateway-close-event-codes
        0	Dispatch	            Receive	        An event was dispatched.
        1	Heartbeat	            Send/Receive	Fired periodically by the client to keep the connection alive.
        2	Identify	            Send	        Starts a new session during the initial handshake.
        3	Presence Update	        Send	        Update the client's presence.
        4	Voice State Update	    Send	        Used to join/leave or move between voice channels.
        6	Resume	                Send	        Resume a previous session that was disconnected.
        7	Reconnect	            Receive	        You should attempt to reconnect and resume immediately.
        8	Request Guild Members	Send	        Request information about offline guild members in a large guild.
        9	Invalid Session	        Receive	        The session has been invalidated. You should reconnect and identify/resume accordingly.
        10	Hello	                Receive	        Sent immediately after connecting, contains the heartbeat_interval to use.
        11	Heartbeat ACK	        Receive	        Sent in response to receiving a heartbeat to acknowledge that it has been received.
    ]]

    settings = {},
    functions = {},
}

return module