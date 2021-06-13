-- Tokens module

local driver = require 'luasql.sqlite3'

-- Generator for new tokens

local tokensGen = function() end

local allCapsGenerator = function(...)
    local size = (select(1,...)) or 6
    local count = (select(2,...)) or 1
    local state = { tokenChars = size, tokensCount = count, chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_" }
    return tokensGen, state
end

local alphanumGenerator = function(...)
    local size = (select(1,...)) or 6
    local count = (select(2,...)) or 1
    local state = { tokenChars = size,
                    tokensCount = count,
                    chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
                  }
    return tokensGen, state
end

function tokensGen( state )
    if ( state.tokensCount > 0 ) then
        local result = ""
        for _ = 1,state.tokenChars,1 do
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
    generator = nil,
    tokenlen = 5
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
        local useSQL = string.format( [[UPDATE tokens SET used=1 WHERE token_id="%s"]], token_id )
        local res = assert( self.db:execute( useSQL ) )
        return math.floor( res )
    else
        return nil
    end
end

function Tokens:add( token_num, ... )
    -- second argument would be the budget in seconds
    local seconds_budget = (select(1,...)) or 900
    -- third argument would be the length of the tokens that would be added
    local token_len = (select(2,...)) or 5

    local insertSQL = "INSERT INTO tokens VALUES "
    local newTokensList = ""

    assert( self.generator, "no generator selected" )
    assert( token_num > 0, "we have to add positive number of tokens" )
    assert( seconds_budget > 0, "the budget in seconds should be more than 0" )

    local _maxBatchId = assert( self.db:execute( "SELECT MAX(BATCH_ID) FROM tokens" ) )
    local maxBatch = tonumber( _maxBatchId:fetch() ) or 0
    _maxBatchId:close()
    maxBatch = maxBatch + 1

    for tkn in self.generator( token_len, token_num ) do
        insertSQL = insertSQL .. string.format( [[(NULL, %d, "%s", 0, %d),]], maxBatch, tkn, seconds_budget )
        newTokensList = newTokensList .. tkn  .. "," .. seconds_budget .. "\n"
    end

    insertSQL = insertSQL:sub(1,-2) .. ";"

    self.db:execute( insertSQL )
    return "Batch: " .. maxBatch .. "\n" .. newTokensList
end

function Tokens:removeBatch( batch_id )
    local useSQL = string.format( [[DELETE FROM tokens WHERE batch_id="%s"]], batch_id )
    local res = assert( self.db:execute( useSQL ) )
    return math.floor( res )
end

function Tokens:printAvailable( batch_id )
    local useSQL = "SELECT * FROM tokens WHERE used=0"
    if( batch_id ) then
        useSQL = useSQL .. " AND batch_id=" .. batch_id
    end
    local _token = self.db:execute( useSQL )
    local tokenRecord = _token:fetch( {}, "a" )
    while tokenRecord do
        print( string.format( "%d, %s, %d", tokenRecord.BATCH_ID, tokenRecord.TOKEN, tokenRecord.BUDGET ) )
        tokenRecord = _token:fetch( {}, "a" )
    end
    _token:close()
end


return Tokens