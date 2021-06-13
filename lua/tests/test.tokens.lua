local lu = require 'lib/luaunit'
local driver = require 'luasql.sqlite3'
local Tokens = require 'lib/tokens'
local resDir = "resources/"

TestMisc = {}

    function TestMisc:testGenerateItems()
        local sizeOfToken = 5
        local numberOfTokens = 25
        local tknCount = 0
        for tkn in Tokens.allCapsGen( sizeOfToken, numberOfTokens ) do
            lu.assertEquals( string.len(tkn), sizeOfToken, "Incorrect size of tokens" )
            tknCount = tknCount + 1
        end
        lu.assertEquals( tknCount, numberOfTokens, "Numbers of tokens generated does not match requested" )
    end

TestTokens = {}

    function TestTokens:setUp()
        self.dbname = "testvouchers.db"
        self.env = driver.sqlite3()
        self.db = self.env:connect( self.dbname )
    
        self.initSQLFileName = resDir .. "vouchers.sql"
        local vouchersSQLFile = io.open( self.initSQLFileName, "r" )
        lu.assertEvalToTrue( vouchersSQLFile, "SQL to init the DB is missing" )

        local vouchersSQL = vouchersSQLFile:read( "*a" )
        lu.assertNotNil( vouchersSQL )

        io.close( vouchersSQLFile )

        local initDBResult = self.db:execute( vouchersSQL )
        lu.assertNotNil( initDBResult )

        Tokens:init( self.dbname )
    end

    function TestTokens:tearDown()
        Tokens:close()
        os.remove( self.dbname )
    end

    function TestTokens:testAddTokens()
        local numberOfTokens = 10
        Tokens:add( numberOfTokens )
        local dbResult = self.db:execute( "SELECT COUNT(*) as tokencount FROM tokens" )
        local tokensCount = dbResult:fetch()
        lu.assertEquals( tonumber( tokensCount ), numberOfTokens, "Number of tokens created not matching requested" )
    end

    function TestTokens:testRemoveTokensBatch()
        local numberOfTokens = 10
        Tokens:add( numberOfTokens )
        local _maxBatch = self.db:execute( "SELECT MAX(BATCH_ID) FROM tokens" )
        local maxBatch = tonumber( _maxBatch:fetch() )
        _maxBatch:close()
        lu.assertNotNil( maxBatch, "There is no batch added" )
        local removed_items = Tokens:removeBatch( maxBatch )
        lu.assertNotNil( removed_items, "There are no items removed" )
    end

    function TestTokens:testUseToken()
        Tokens:add( 1 )
        local dbResult = self.db:execute( "SELECT * FROM tokens WHERE USED=0 LIMIT 1" )
        local tokenRecord = dbResult:fetch( {}, "a" )
        dbResult:close()
        lu.assertEquals( tokenRecord.USED, 0, "Token is already used" )
        Tokens:use( tokenRecord.TOKEN_ID )
        local updatedTokenRecord = Tokens:findById( tokenRecord.TOKEN_ID )
        lu.assertEquals( updatedTokenRecord.USED, 1, "Token was not used properly" )
    end

os.exit( lu.LuaUnit.run() )