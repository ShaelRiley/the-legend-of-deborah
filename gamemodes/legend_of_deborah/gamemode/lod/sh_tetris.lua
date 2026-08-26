LOD = LOD or {}
LOD.Tetris = LOD.Tetris or {}

local Tetris = LOD.Tetris

Tetris.Width = 10
Tetris.Height = 20
Tetris.FallInterval = 0.58
Tetris.Rewards = {
    [1] = 10,
    [2] = 30,
    [3] = 50,
    [4] = 80
}

Tetris.Pieces = {
    [1] = { -- I
        {{0,1},{1,1},{2,1},{3,1}},
        {{2,0},{2,1},{2,2},{2,3}},
        {{0,2},{1,2},{2,2},{3,2}},
        {{1,0},{1,1},{1,2},{1,3}}
    },
    [2] = { -- O
        {{1,0},{2,0},{1,1},{2,1}},
        {{1,0},{2,0},{1,1},{2,1}},
        {{1,0},{2,0},{1,1},{2,1}},
        {{1,0},{2,0},{1,1},{2,1}}
    },
    [3] = { -- T
        {{1,0},{0,1},{1,1},{2,1}},
        {{1,0},{1,1},{2,1},{1,2}},
        {{0,1},{1,1},{2,1},{1,2}},
        {{1,0},{0,1},{1,1},{1,2}}
    },
    [4] = { -- S
        {{1,0},{2,0},{0,1},{1,1}},
        {{1,0},{1,1},{2,1},{2,2}},
        {{1,1},{2,1},{0,2},{1,2}},
        {{0,0},{0,1},{1,1},{1,2}}
    },
    [5] = { -- Z
        {{0,0},{1,0},{1,1},{2,1}},
        {{2,0},{1,1},{2,1},{1,2}},
        {{0,1},{1,1},{1,2},{2,2}},
        {{1,0},{0,1},{1,1},{0,2}}
    },
    [6] = { -- J
        {{0,0},{0,1},{1,1},{2,1}},
        {{1,0},{2,0},{1,1},{1,2}},
        {{0,1},{1,1},{2,1},{2,2}},
        {{1,0},{1,1},{0,2},{1,2}}
    },
    [7] = { -- L
        {{2,0},{0,1},{1,1},{2,1}},
        {{1,0},{1,1},{1,2},{2,2}},
        {{0,1},{1,1},{2,1},{0,2}},
        {{0,0},{1,0},{1,1},{1,2}}
    }
}

local function newRow()
    local row = {}
    for x = 1, Tetris.Width do row[x] = 0 end
    return row
end

local function newBoard()
    local board = {}
    for y = 1, Tetris.Height do board[y] = newRow() end
    return board
end

local function refillBag(game)
    game.bag = {1, 2, 3, 4, 5, 6, 7}
    game.rng:Shuffle(game.bag)
end

local function drawPiece(game)
    if not game.bag or #game.bag == 0 then refillBag(game) end
    return table.remove(game.bag)
end

function Tetris.CellsFor(pieceId, rotation, originX, originY)
    local piece = Tetris.Pieces[pieceId]
    if not piece then return {} end
    local shape = piece[((rotation or 1) - 1) % 4 + 1]
    local cells = {}
    for i = 1, 4 do
        cells[i] = {
            x = (originX or 0) + shape[i][1],
            y = (originY or 0) + shape[i][2]
        }
    end
    return cells
end

function Tetris.CanPlace(game, pieceId, rotation, x, y)
    for _, cell in ipairs(Tetris.CellsFor(pieceId, rotation, x, y)) do
        if cell.x < 1 or cell.x > Tetris.Width or cell.y > Tetris.Height then return false end
        if cell.y >= 1 and (game.board[cell.y][cell.x] or 0) ~= 0 then return false end
    end
    return true
end

local function spawnCurrent(game)
    game.current = {
        id = game.nextPiece or drawPiece(game),
        rotation = 1,
        x = 4,
        y = 0
    }
    game.nextPiece = drawPiece(game)

    if not Tetris.CanPlace(game, game.current.id, game.current.rotation, game.current.x, game.current.y) then
        game.board = newBoard()
        game.resetCount = (game.resetCount or 0) + 1
    end
end

function Tetris.NewGame(seed)
    local game = {
        board = newBoard(),
        rng = LOD.RNG.New(LOD.Seeds.Normalize(seed)),
        bag = {},
        current = nil,
        nextPiece = nil,
        resetCount = 0,
        piecesLocked = 0
    }
    game.nextPiece = drawPiece(game)
    spawnCurrent(game)
    return game
end

function Tetris.Move(game, dx, dy)
    local current = game.current
    if not current then return false end
    local x = current.x + (dx or 0)
    local y = current.y + (dy or 0)
    if not Tetris.CanPlace(game, current.id, current.rotation, x, y) then return false end
    current.x = x
    current.y = y
    return true
end

function Tetris.Rotate(game, direction)
    local current = game.current
    if not current then return false end
    local rotation = ((current.rotation - 1 + (direction or 1)) % 4) + 1
    local kicks = {0, -1, 1, -2, 2}
    for _, dx in ipairs(kicks) do
        if Tetris.CanPlace(game, current.id, rotation, current.x + dx, current.y) then
            current.rotation = rotation
            current.x = current.x + dx
            return true
        end
    end
    return false
end

local function clearLines(game)
    local cleared = 0
    local y = Tetris.Height
    while y >= 1 do
        local full = true
        for x = 1, Tetris.Width do
            if (game.board[y][x] or 0) == 0 then
                full = false
                break
            end
        end
        if full then
            table.remove(game.board, y)
            table.insert(game.board, 1, newRow())
            cleared = cleared + 1
        else
            y = y - 1
        end
    end
    return math.min(cleared, 4)
end

function Tetris.Lock(game)
    local current = game.current
    if not current then return 0, false end

    local toppedOut = false
    for _, cell in ipairs(Tetris.CellsFor(current.id, current.rotation, current.x, current.y)) do
        if cell.y < 1 then
            toppedOut = true
        else
            game.board[cell.y][cell.x] = current.id
        end
    end

    local cleared = toppedOut and 0 or clearLines(game)
    game.piecesLocked = (game.piecesLocked or 0) + 1

    if toppedOut then
        game.board = newBoard()
        game.resetCount = (game.resetCount or 0) + 1
    end

    spawnCurrent(game)
    return cleared, toppedOut
end

function Tetris.StepDown(game)
    if Tetris.Move(game, 0, 1) then return true, 0, false end
    local cleared, toppedOut = Tetris.Lock(game)
    return false, cleared, toppedOut
end

function Tetris.HardDrop(game)
    local distance = 0
    while Tetris.Move(game, 0, 1) do distance = distance + 1 end
    local cleared, toppedOut = Tetris.Lock(game)
    return distance, cleared, toppedOut
end

function Tetris.RewardForLines(lines)
    return Tetris.Rewards[math.Clamp(math.floor(tonumber(lines) or 0), 0, 4)] or 0
end
