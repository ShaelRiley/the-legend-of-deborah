-- Server-local SQLite transactions. No profile reset on decoding/storage failure.
LOD.CryptoStore = {}
local Store=LOD.CryptoStore
local function query(statement)
    local result=sql.Query(statement)
    if result==false then error(sql.LastError() or 'wallet database error') end
    return result
end
local function encode(value)
    local encoded=util.TableToJSON(value)
    assert(encoded, 'wallet JSON encoding failed')
    -- assert returns every argument: forwarding it to SQLStr also passed its
    -- message as bNoQuotes, leaving JSON unquoted on the real engine binding.
    return encoded
end
local function number(n) return type(n)=='number' and n==n and n>=0 and n<9007199254740991 end
function Store:ValidAccount(id)
    return type(id)=='string' and #id==17 and id:match('^%d+$')~=nil
end
function Store:Validate(a,account)
    assert(type(a)=='table' and a.version==1 and number(a.balance) and a.balance%1==0 and number(a.score) and a.score%1==0, 'corrupt wallet balance/version')
    assert(type(a.tokens)=='table' and type(a.milestones)=='table' and type(a.pending)=='table', 'corrupt wallet collection')
    local n=0
    local function token(t)
        assert(type(t)=='table' and type(t.id)=='string' and #t.id<=220
            and (not account or t.id:sub(1,#account+1)==account..':')
            and type(t.reason)=='string' and type(t.run)=='string' and type(t.source)=='string'
            and number(t.depth) and t.depth>=1 and t.depth%1==0
            and (t.lastRun==nil or type(t.lastRun)=='string')
            and LOD.Equipment:ValidateWearable(t.item), 'corrupt DFT snapshot/provenance')
    end
    for id,t in pairs(a.tokens) do
        n=n+1
        token(t);assert(t.id==id,'corrupt DFT identity')
    end
    assert(n<=8, 'corrupt DFT capacity')
    for level,t in pairs(a.pending) do
        assert((level=='1' or level=='5' or level=='10' or level=='20') and a.milestones[level]==true, 'corrupt pending DFT')
        token(t)
    end
    for level,claimed in pairs(a.milestones) do
        assert((level=='1' or level=='5' or level=='10' or level=='20') and claimed==true,'corrupt milestone claim')
    end
    return a
end
function Store:Load(id)
    assert(self:ValidAccount(id), 'invalid wallet account')
    local rows=query('SELECT body FROM lod_crypto_accounts WHERE account='..sql.SQLStr(id))
    if not rows then return {version=1,balance=0,score=0,tokens={},milestones={},pending={}} end
    return self:Validate(util.JSONToTable(rows[1].body, false, true),id)
end
function Store:Read(id)
    local ok,result=pcall(self.Load,self,id)
    if ok then return result end
    ErrorNoHalt('[LOD:WALLET] '..tostring(result)..'\n')
    return nil,'Wallet storage unavailable; existing account preserved.'
end
function Store:Transaction(eventId,kind,ids,mutate)
    local begun=false
    local ok,result,detail=pcall(function()
        query('BEGIN IMMEDIATE');begun=true
        if query('SELECT event FROM lod_crypto_ledger WHERE event='..sql.SQLStr(eventId)) then
            query('ROLLBACK');begun=false;return false,'already'
        end
        local accounts={}
        for _,id in ipairs(ids) do accounts[id]=self:Load(id) end
        local accepted,receipt=mutate(accounts)
        if not accepted then query('ROLLBACK');begun=false;return false,receipt end
        for id,a in pairs(accounts) do
            self:Validate(a,id)
            query('INSERT OR REPLACE INTO lod_crypto_accounts(account,body) VALUES('..sql.SQLStr(id)..','..sql.SQLStr(encode(a))..')')
        end
        query('INSERT INTO lod_crypto_ledger(event,kind,body) VALUES('..sql.SQLStr(eventId)..','..sql.SQLStr(kind)..','..sql.SQLStr(encode(receipt or {}))..')')
        query('COMMIT');begun=false
        return true,receipt
    end)
    if begun then sql.Query('ROLLBACK') end
    if not ok then
        ErrorNoHalt('[LOD:WALLET] transaction failed: '..tostring(result)..'\n')
        return false,'storage'
    end
    return result,detail
end
function Store:NextRunID()
    query('INSERT INTO lod_crypto_runs DEFAULT VALUES')
    local rows=query('SELECT last_insert_rowid() AS id')
    return 'campaign:'..assert(rows and rows[1].id)
end
function Store:Recent(id)
    -- Separate small account index avoids reading the whole immutable ledger.
    return query('SELECT event,kind,body FROM lod_crypto_history WHERE account='..sql.SQLStr(id)..' ORDER BY rowid DESC LIMIT 8') or {}
end
local ok,err=pcall(function()
    query('CREATE TABLE IF NOT EXISTS lod_crypto_accounts(account TEXT PRIMARY KEY,body TEXT NOT NULL)')
    query('CREATE TABLE IF NOT EXISTS lod_crypto_ledger(event TEXT PRIMARY KEY,kind TEXT NOT NULL,body TEXT NOT NULL)')
    query('CREATE TABLE IF NOT EXISTS lod_crypto_runs(id INTEGER PRIMARY KEY AUTOINCREMENT)')
    query('CREATE TABLE IF NOT EXISTS lod_crypto_history(account TEXT NOT NULL,event TEXT NOT NULL,kind TEXT NOT NULL,body TEXT NOT NULL, UNIQUE(account,event))')
    query('CREATE INDEX IF NOT EXISTS lod_crypto_history_account ON lod_crypto_history(account)')
end)
Store.Ready=ok
if not ok then ErrorNoHalt('[LOD:WALLET] database initialization failed: '..tostring(err)..'\n') end
-- Written inside the account/ledger transaction, never a separate payout path.
function Store:History(id,event,kind,body)
    query('INSERT INTO lod_crypto_history(account,event,kind,body) VALUES('..sql.SQLStr(id)..','..sql.SQLStr(event)..','..sql.SQLStr(kind)..','..sql.SQLStr(encode(body))..')')
end
