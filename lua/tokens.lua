-- Tokens module 

local driver = require 'luasql.sqlite3'

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

-- Generator for new tokens

local Tokens = { 
    dbname = "vouchers.db",
    allCapsGen = allCapsGenerator,
    alpahnumGen = alphanumGenerator,
    generator = nil
}

function Tokens:init( dbname )
    if ( dbname == nil ) then
        dbname = self.dbname
    end
    local dbf = assert( io.open( dbname, "r" ) )
    if ( dbf ~= nil ) then
        io.close( dbf ) 
        self.dbname = dbname
    end
    self.env = driver.sqlite3()
    self.db = self.env:connect( self.dbname )
    self.generator = self.allCapsGen
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
    local token = self:findById( token_id )
    if( token ~= nil ) then
        local useSQL = string.format( [[UPDATE tokens SET used=1 WHERE token_id=%d]], token_id )
        local res = assert( self.db:execute( useSQL ) )
        return math.floor( res )
    else
        return nil
    end
end

function Tokens:add( token_num )
    local insertSQL = "INSERT INTO tokens VALUES "
    local newTokensList = ""

    for tkn in self.generator( 5, token_num ) do
        insertSQL = insertSQL .. string.format( [[(NULL, "%s", 0, %d),]], tkn, 900 )
        newTokensList = newTokensList .. "\n" .. tkn
    end

    insertSQL = insertSQL:sub(1,-2) .. ";"

    self.db:execute( insertSQL )
    return newTokensList
end

return Tokens