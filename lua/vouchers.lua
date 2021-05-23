local inspect = require('inspect')
local argparse = require 'lib/argparse'
local Tokens = require 'tokens'

local dbName = "vouchers.db"
Tokens:init( dbName )

local parser = argparse("Tokens", "Tokens script")
                :command_target("command")
                :require_command(false)

-- this will be called by NDS to query if the user has credentials, response should be
-- a string of this kind 3600 0 0
-- first number is number of seconds this session has
-- second and third are respectively upload and download limits in bytes

local install_command = parser:command("auth_client")
install_command:argument( "mac" )
install_command:argument( "user" )
install_command:argument( "password" )

-- the following commands will be notifications from NDS to this script for specific events
-- argument list is mac, incoming bytes, outgoing bytes, session start, session end

local c_auth = parser:command "client_auth"
        :description "Client authentication"
c_auth:argument( "aux", "additional arguments"):args("5+")

local c_deauth = parser:command "client_deauth"
        :description "Client deauthentication"
c_deauth:argument( "aux", "additional arguments"):args("5+")

local i_deauth = parser:command "idle_deauth"
        :description "Idle deauthentication"
i_deauth:argument( "aux", "additional arguments"):args("5+")

local t_deauth = parser:command "timeout_deauth"
        :description "Timeout deauthentication"
t_deauth:argument( "aux", "additional arguments"):args("5+")

local ndsctl_auth = parser:command "ndsctl_auth"
        :description "Client was authenticated by the ndsctl tool"
ndsctl_auth:argument( "aux", "additional arguments"):args("5+")

local ndsctl_deauth = parser:command "ndsctl_deauth"
        :description "Client was deauthenticated by the ndsctl tool"
ndsctl_deauth:argument( "aux", "additional arguments"):args("5+")

local shutdown_deauth = parser:command "shutdown_deauth"
        :description "Client was deauthenticated by Nodogsplash terminating"
shutdown_deauth:argument( "aux", "additional arguments"):args("5+")

parser:option("-I --id", "Token id to find.", -1, tonumber, "1")
parser:option("-T --token", "Token to find.", -1, nil, "1")
parser:option("-A --add", "Tokens to add.", -1, tonumber, "1")
local args = parser:parse()

print(inspect(args))

local retValue = 0

if ( args["id"] ~= -1 ) then
    local tokenid = args["id"]
    local tokenres = Tokens:findById(tokenid)
    print("Token id we look for is: ", tokenid)
    if( tokenres ) then
        print("Token found is: ", tokenres.TOKEN)
    else
        print("But this is was not found")
    end
end

if ( args["token"] ~= -1 ) then
    local token_name = args["token"]
    local tokenres = Tokens:find(token_name)
    print("Token we look for is: ", token_name)
    if( tokenres ) then
        print("Token found is: ", tokenres.TOKEN .. "," .. tokenres.BUDGET)
    else
        print("But this is was not found")
        retValue = 1
    end
end

if ( args["add"] ~= -1 ) then
    local tokenstoadd = args["add"]
    local newTokens = Tokens:add(tokenstoadd)
    print("Added new tokens: ", tokenstoadd)
    print(newTokens)
end

Tokens:close()

os.exit( retValue )