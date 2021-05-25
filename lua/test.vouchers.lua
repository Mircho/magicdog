local lu = require 'lib/luaunit'
local driver = require 'luasql.sqlite3'
local resDir = "resources/"

TestVouchers = {}

    function TestVouchers:setUp()
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
    end

    function TestVouchers:tearDown()
        os.remove( self.dbname )
    end

    function TestVouchers:testAuthClient()
        local testTokenName = "SALTES"
        local testTokenBudget = 1000
        local dbResult = self.db:execute( string.format( "INSERT INTO tokens VALUES (NULL, '%s', 0, %d);", testTokenName, testTokenBudget ) )

        local file = io.popen( "lua vouchers.lua --db " .. self.dbname .. " auth_client 00 zaki " .. testTokenName )
        local output = file:read( "*a" )
        local rc = {file:close()}

        -- printing 
        output = output:match("^%s*(.-)%s*$")

        lu.assertEquals( output, string.format( "%d 0 0", testTokenBudget ), "Expected format of output not found" )
        lu.assertEquals( rc[3], 0, "Exit code is 1, token was not found" )
    end


os.exit( lu.LuaUnit.run() )