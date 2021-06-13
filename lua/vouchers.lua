#!/usr/bin/lua
local log = require 'lib.log'
log.outfile = 'voucher.log'
log.noconsole = true

local argparse = require 'lib.argparse'

-- tokens are initialized further down in the callback of the --db option parser
-- if we got the option from command line to use another db
local Tokens = require 'lib.tokens'
local dbName = "vouchers.db"

-- return value from execution of the program
local retValue = 1

-- callbacks to commands

local authorize_action = function( args )
    log.debug( "Authorize user with token "..args.password )

    local tokenres = Tokens:find(args.password)
    local tokenUsed = tonumber( tokenres.USED )
    if( tokenres and tokenUsed ~= 1 ) then
        print( tokenres.BUDGET .. " 0 0" )
        assert( Tokens:use( tokenres.TOKEN_ID ) )
        retValue = 0
    else
        retValue = 1
    end
end

local add_tokens = function( args )
    local addedTokens = Tokens:add( args.number, args.budget, args.length )
    print( addedTokens )
end

local remove_batch = function( args )
    local removedTokens = Tokens:removeBatch( args.batch )
    print( "Removed tokens: ", removedTokens )
end

local print_available = function( args )
    Tokens:printAvailable( args.batch )
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

-- this will be called by NDS to query if the user has credentials, response should be
-- a string of this kind 3600 0 0
-- first number is number of seconds this session has
-- second and third are respectively upload and download limits in bytes

local authorize_command = parser:command("auth_client", "Authenticate client, called only by NDS")
authorize_command:argument( "mac" )
authorize_command:argument( "user" )
authorize_command:argument( "password" )
authorize_command:action( authorize_action )

-- the following commands will be notifications from NDS to this script for specific events
-- argument list is mac, incoming bytes, outgoing bytes, session start, session end

local c_auth = parser:command "client_auth"
        :description "Client authentication, called only by NDS"
c_auth:argument( "aux", "additional arguments"):args("5+")

local c_deauth = parser:command "client_deauth"
        :description "Client deauthentication, called only by NDS"
c_deauth:argument( "aux", "additional arguments"):args("5+")

local i_deauth = parser:command "idle_deauth"
        :description "Idle deauthentication, called only by NDS"
i_deauth:argument( "aux", "additional arguments"):args("5+")

local t_deauth = parser:command "timeout_deauth"
        :description "Timeout deauthentication, called only by NDS"
t_deauth:argument( "aux", "additional arguments"):args("5+")

local ndsctl_auth = parser:command "ndsctl_auth"
        :description "Client was authenticated by the ndsctl tool, called only by NDS"
ndsctl_auth:argument( "aux", "additional arguments"):args("5+")

local ndsctl_deauth = parser:command "ndsctl_deauth"
        :description "Client was deauthenticated by the ndsctl tool, called only by NDS"
ndsctl_deauth:argument( "aux", "additional arguments"):args("5+")

local shutdown_deauth = parser:command "shutdown_deauth"
        :description "Client was deauthenticated by Nodogsplash terminating, called only by NDS"
shutdown_deauth:argument( "aux", "additional arguments" ):args("5+")

-- End of NDS specific calls

local add_tokens_command = parser:command( "add_tokens", "Add new tokens within a new batch" )
add_tokens_command:argument( "number", "number of tokens to be added", 1, tonumber )
add_tokens_command:argument( "budget", "budget in seconds per new token", 1200, tonumber )
add_tokens_command:argument( "length", "length in charactes of a token", 5, tonumber )
add_tokens_command:action( add_tokens )

local print_available_command = parser:command( "print_available", "Print all available tokens within a batch" )
print_available_command:argument( "batch", "print available only in this batch", 1, tonumber, "?" )
print_available_command:action( print_available )

local args = parser:parse()

Tokens:close()

os.exit( retValue )