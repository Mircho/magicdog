local argparse = require 'lib/argparse'

-- tokens are initialized further down in the callback of the --db option parser
-- if we got the option from command line to use another db
local Tokens = require 'lib/tokens'
local dbName = "vouchers.db"

-- return value from exxecution of the program
local retValue = 1

-- callbacks to commands

local authorize_action = function( args )
    local tokenres = Tokens:find(args.password)
    -- print("Token we look for is: ", args.password)
    if( tokenres ) then
        print( tokenres.BUDGET .. " 0 0" )
        retValue = 0
    else
        retValue = 1
    end
end

local parser = argparse("Tokens", "Tokens script")
                :command_target("command")
                :require_command(false)

-- parser options

-- here we initialize the tokens 
parser:option("-D --db", "Database to be used.", dbName, nil, "1"):action(function(args,_,dbName)
    args[_] = dbName
    Tokens:init( dbName )
end)

parser:option("-I --id", "Token id to find.", -1, tonumber, "1")
parser:option("-T --token", "Token to find.", -1, nil, "1")
parser:option("-A --add", "Tokens to add.", -1, tonumber, "1")


-- this will be called by NDS to query if the user has credentials, response should be
-- a string of this kind 3600 0 0
-- first number is number of seconds this session has
-- second and third are respectively upload and download limits in bytes

local authorize_command = parser:command("auth_client")
authorize_command:argument( "mac" )
authorize_command:argument( "user" )
authorize_command:argument( "password" )
authorize_command:action( authorize_action )

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

local args = parser:parse()

Tokens:close()

os.exit( retValue )