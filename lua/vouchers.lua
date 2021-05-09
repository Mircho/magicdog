local inspect = require('inspect')
local argparse = require 'argparse'

local driver = require 'luasql.sqlite3'
-- local env = driver.sqlite3()
-- local db = env:connect('Tokens.db')

-- Generator for new tokens

local tokensGen

function allCapsGenerator(...)
    local size = (select(1,...)) or 6
    local count = (select(2,...)) or 1
    local state = { tokenChars = size, tokensCount = count, chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" }
    return tokensGen, state
end

function alphanumGenerator(...)
    local size = (select(1,...)) or 6
    local count = (select(2,...)) or 1
    local state = { tokenChars = size, tokensCount = count, chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" }
    return tokensGen, state
end

function tokensGen( state )
    if ( state.tokensCount > 0 ) then
        local result = "", j
        for j = 1,state.tokenChars,1 do
            local pos = math.random(1,state.chars:len())
            result = result .. state.chars:sub(pos,pos)
        end
        state.tokensCount = state.tokensCount - 1
        return result    
    else
        return nil
    end
end

-- for tkn in alphanumGenerator(5,2) do
--     print("Token(tm) :", tkn)
-- end

-- Generator for new tokens


local Tokens = { 
    dbname = "vouchers.db"
}

function Tokens:init( dbname )
    if ( dbname == nil ) then
        dbname = self.dbname
    end
    local dbf = io.open( dbname, "r" )
    if ( dbf ~= nil ) then
        io.close( dbf ) 
        self.dbname = dbname
    else
        print( "Database does not exist" )
        return nil
    end
    self.env = driver.sqlite3()
    self.db = self.env:connect( self.dbname )
end

function Tokens:close()
    self.db:close()
    self.env:close()
end

function Tokens:find( token_name )
    local _token = self.db:execute(string.format( [[SELECT * FROM tokens WHERE token="%s" LIMIT 1]], token_name ))
    local tokenRecord = _token:fetch( {}, "a" )
    _token:close()
    if( tokenRecord == nil ) then
        return nil
    else
        return tokenRecord
    end
end

function Tokens:findById( token_id )
    local _token = self.db:execute(string.format( [[SELECT * FROM tokens WHERE token_id="%s" LIMIT 1]], token_id ))
    local tokenRecord = _token:fetch( {}, "a" )
    _token:close()
    if( tokenRecord == nil ) then
        return nil
    else
        return tokenRecord
    end
end

function Tokens:use( token_id )
    local tokensAff = self.db:execute( string.format( [[UPDATE tokens SET used=1 WHERE token_id=%d]],token_id) )
    return math.floor(tokensAff)
end

function Tokens:add( token_num )
    local insertSQL = "INSERT INTO tokens VALUES "
    local newTokensList = ""

    for tkn in allCapsGenerator( 5, token_num ) do
        insertSQL = insertSQL .. string.format( [[(NULL, "%s", 0, %d),]], tkn, 900 )
        newTokensList = newTokensList .. "\n" .. tkn
    end

    insertSQL = insertSQL:sub(1,-2) .. ";"

    print(insertSQL)
    self.db:execute( insertSQL )
    return newTokensList
end


Tokens:init()
print( "Found token: ", Tokens:find( "TOK000" ).TOKEN )
-- print( "Adding tokens... ")
-- Tokens:add(4)

local parser = argparse("Tokens", "Tokens script")
                :command_target("command")
                :require_command(false)

local install_command = parser:command("auth_client")
install_command:argument( "mac" )
install_command:argument( "user" )
install_command:argument( "password" )

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
ndsctl_auth:argument( "aux", "additional arguments"):args("5+")

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
    newTokens = Tokens:add(tokenstoadd)
    print("Added new tokens: ", tokenstoadd)
    print(newTokens)
end

Tokens:close()

os.exit( retValue )