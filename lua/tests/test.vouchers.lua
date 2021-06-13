local lu = require 'lib/luaunit'
local driver = require 'luasql.sqlite3'
local resDir = "resources/"

TestVouchers = {}

    function TestVouchers:setUp()
        self.dbname = "testvouchers.db"
        self.env = driver.sqlite3()
        self.db = self.env:connect( self.dbname )
    
        self.initSQLFileName = resDir .. "vouchers.sql"
        local vouchersSQLFile = assert( io.open( self.initSQLFileName, "r" ) )
        lu.assertEvalToTrue( vouchersSQLFile, "SQL file used to init the DB is missing " .. self.initSQLFileName )

        local vouchersSQL = vouchersSQLFile:read( "*a" )
        lu.assertNotNil( vouchersSQL )

        io.close( vouchersSQLFile )

        local initDBResult = assert( self.db:execute( vouchersSQL ) )
        lu.assertNotNil( initDBResult )
    end

    function TestVouchers:tearDown()
        os.remove( self.dbname )
    end

    function TestVouchers:testAuthClient()
        local testTokenName = "SALTES"
        local testTokenBudget = 1000
        local dbResult = assert( self.db:execute( string.format( "INSERT INTO tokens VALUES (NULL, 0, '%s', 0, %d);", testTokenName, testTokenBudget ) ) )

        local file = io.popen( "lua vouchers.lua --db " .. self.dbname .. " auth_client 00 zaki " .. testTokenName )
        local output = file:read( "*a" )
        local rc = {file:close()}

        -- printing 
        output = output:match("^%s*(.-)%s*$")

        lu.assertEquals( output, string.format( "%d 0 0", testTokenBudget ), "Expected format of output not found" )
        lu.assertEquals( rc[3], 0, "Exit code is not right, token was not found or was already used up" )

        -- should not be possible to reuse a token
        local file = io.popen( "lua vouchers.lua --db " .. self.dbname .. " auth_client 00 zaki " .. testTokenName )
        local output = file:read( "*a" )
        local rc = {file:close()}

        lu.assertEquals( rc[3], 1, "Already used token was allowed to be used again " .. output )
    end


os.exit( lu.LuaUnit.run() )