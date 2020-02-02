local garbo = require("garbochess")

SQ_SIZE = 64

globals = {
    difficulty = 1,
    players = 1,
    pieceImg = {},
    pieceQuads = {},
    pieces = {
        -- WHITE
        {quad = 1, name = "king", team = "white", x = 5, y = 8},
        {quad = 3, name = "queen", team = "white", x = 4, y = 8},
        {quad = 5, name = "rook", team = "white", x = 1, y = 8},
        {quad = 5, name = "rook", team = "white", x = 8, y = 8},
        {quad = 7, name = "knight", team = "white", x = 2, y = 8},
        {quad = 7, name = "knight", team = "white", x = 7, y = 8},
        {quad = 9, name = "bishop", team = "white", x = 3, y = 8},
        {quad = 9, name = "bishop", team = "white", x = 6, y = 8},
        {quad = 11, name = "pawn", team = "white", x = 1, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 2, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 3, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 4, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 5, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 6, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 7, y = 7},
        {quad = 11, name = "pawn", team = "white", x = 8, y = 7},
        -- BLACK
        {quad = 2, name = "king", team = "black", x = 5, y = 1},
        {quad = 4, name = "queen", team = "black", x = 4, y = 1},
        {quad = 6, name = "rook", team = "black", x = 1, y = 1},
        {quad = 6, name = "rook", team = "black", x = 8, y = 1},
        {quad = 8, name = "knight", team = "black", x = 2, y = 1},
        {quad = 8, name = "knight", team = "black", x = 7, y = 1},
        {quad = 10, name = "bishop", team = "black", x = 3, y = 1},
        {quad = 10, name = "bishop", team = "black", x = 6, y = 1},
        {quad = 12, name = "pawn", team = "black", x = 1, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 2, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 3, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 4, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 5, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 6, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 7, y = 2},
        {quad = 12, name = "pawn", team = "black", x = 8, y = 2}
    },
    board = {},
    turn = "white",
    halfmoves = 0,
    moves = 0,
    selectedPiece = -1,
    check = false,
    checkmate = false,
    checkLastTurn = false,
    castleAllowed = {
        whiteKing = true,
        whiteQueen = true,
        blackKing = true,
        blackQueen = true
    },
    aicounter = 0
}

function board_get(x, y)
    if globals.board[x] and globals.board[x][y] then
        return globals.board[x][y]
    end
end

function board_set(x, y, value)
    if globals.board[x] and globals.board[x][y] then
        for k, v in pairs(value) do
            if tonumber(v) ~= nil and tonumber(globals.board[x][y][k]) ~= nil then
                globals.board[x][y][k] = globals.board[x][y][k] + v
            else
                globals.board[x][y][k] = v
            end
        end
    end
end

function board_to_fen()
    local fen = ""
    local empties = 0
    for y = 1, 8 do
        empties = 0
        for x = 1, 8 do
            local p = piece_here(x, y)
            if p then
                if empties > 0 then
                    fen = fen..tostring(empties)
                    empties = 0
                end
                local piece = globals.pieces[p] 
                local n = piece.name:sub(1, 1)
                if n == "k" and piece.name == "knight" then
                    n = "n"
                end
                if piece.team == "white" then
                    n = n:upper()
                end
                fen = fen..n
            else
                empties = empties + 1
            end
        end
        if empties > 0 then
            fen = fen..tostring(empties)
            empties = 0
        end
        if y < 8 then fen = fen.."/" end
    end
    fen = fen.." "..globals.turn:sub(1, 1)
    local castlestr = ""
    if globals.castleAllowed.whiteKing then castlestr = castlestr.."K" end
    if globals.castleAllowed.whiteQueen then castlestr = castlestr.."Q" end
    if globals.castleAllowed.blackKing then castlestr = castlestr.."k" end
    if globals.castleAllowed.blackQueen then castlestr = castlestr.."q" end
    if #castlestr == 0 then castlestr = "-" end
    fen = fen.." "..castlestr
    fen = fen.." -"
    fen = fen.." "..tostring(globals.halfmoves)
    fen = fen.." "..tostring(globals.moves)
    print(fen)
    return fen
end

function piece_here(x, y)
    local bd = board_get(x, y)
    if bd and bd.piece then
        return bd.piece
    end
end

function piece_move(p, x, y)
    local piece = globals.pieces[p]
    -- If we are moving a for the first time, disable castling on that side
    if piece.x == 1 and piece.y == 1 then
        globals.castleAllowed.blackQueen = false
    elseif piece.x == 1 and piece.y == 8 then
        globals.castleAllowed.blackKing = false
    elseif piece.x == 8 and piece.y == 1 then
        globals.castleAllowed.whiteQueen = false
    elseif piece.x == 8 and piece.y == 8 then
        globals.castleAllowed.whiteKing = false
    end
    -- If we are moving a king, disable all castling
    if piece.name == "king" and piece.team == "white" then
        globals.castleAllowed.whiteKing = false
        globals.castleAllowed.whiteQueen = false
    elseif piece.name == "king" and piece.team == "black" then
        globals.castleAllowed.blackKing = false
        globals.castleAllowed.blackQueen = false
    end
    -- Move piece
    globals.board[piece.x][piece.y].piece = nil
    globals.board[x][y].piece = p
    piece.x = x
    piece.y = y
end

function tally_move()
    globals.halfmoves = globals.halfmoves + 1
    if globals.halfmoves % 2 == 0 then
        globals.moves = globals.moves + 1
    end
end

function move_set(x, y, piece, threat)
    local b = board_get(x, y)
    if not b then return 0 end
    local p = globals.pieces[b.piece]
    local place = {moveok = true}
    if threat == "threat" then
        local threatlevel = 1
        if piece.team == "black" then
            threatlevel = -threatlevel
        end
        place = {threat = threatlevel}
        if p and p.name == "king" and p.team ~= piece.team then
            globals.check = true
            print("CHECK given by "..piece.name.." at "..piece.x..", "..piece.y)
        end
    elseif threat == "castle" then
        place.castle = true
    elseif threat == "none" then
        place = {}
    end
    if not p or (not globals.checkLastTurn and b.piece == globals.selectedPiece) then
        board_set(x, y, place)
        return 2
    elseif p.team ~= piece.team then
        board_set(x, y, place)
        return 1
    elseif place.threat then
        board_set(x, y, place)
        return 1
    end
    return 0
end

function move_line(x, y, piece, threat)
    for i = 1, 8 do
        local ok = move_set(piece.x + (i * x), piece.y + (i * y), piece, threat)
        if ok < 2 then
            return i
        end
    end
    return 8
end

function pawn_move(clicked, dir, threat)
    local p = piece_here(clicked.x, clicked.y + dir)
    local moveThreat = "none"
    if threat == "move" then moveThreat = "move" end
    if not p then
        move_set(clicked.x, clicked.y + dir, clicked, moveThreat)
        if not clicked.moved then
            move_set(clicked.x, clicked.y + (dir * 2), clicked, moveThreat)
        end
    end
    local t1 = piece_here(clicked.x - 1, clicked.y + dir)
    if t1 or threat == "threat" then
        move_set(clicked.x - 1, clicked.y + dir, clicked, threat)
    end
    local t2 = piece_here(clicked.x + 1, clicked.y + dir)
    if t2 or threat == "threat" then
        move_set(clicked.x + 1, clicked.y + dir, clicked, threat)
    end
end

function knight_move(clicked, threat)
    move_set(clicked.x + 2, clicked.y + 1, clicked, threat)
    move_set(clicked.x + 2, clicked.y - 1, clicked, threat)
    move_set(clicked.x - 2, clicked.y + 1, clicked, threat)
    move_set(clicked.x - 2, clicked.y - 1, clicked, threat)
    move_set(clicked.x + 1, clicked.y + 2, clicked, threat)
    move_set(clicked.x - 1, clicked.y + 2, clicked, threat)
    move_set(clicked.x + 1, clicked.y - 2, clicked, threat)
    move_set(clicked.x - 1, clicked.y - 2, clicked, threat)
end

function bishop_move(clicked, threat)
    move_line(1, 1, clicked, threat)
    move_line(1, -1, clicked, threat)
    move_line(-1, 1, clicked, threat)
    move_line(-1, -1, clicked, threat)
end

function rook_move(clicked, threat)
    move_line(0, 1, clicked, threat)
    move_line(1, 0, clicked, threat)
    move_line(0, -1, clicked, threat)
    move_line(-1, 0, clicked, threat)
end

function queen_move(clicked, threat)
    bishop_move(clicked, threat)
    rook_move(clicked, threat)
end

function king_move(clicked, threat)
    -- Castling
    if not clicked.moved and threat == "move" then
        for k, v in pairs(globals.pieces) do
            if v.name == "rook" and v.team == clicked.team and not v.moved then
                local dist = 0
                if v.x == 8 then
                    dist = move_line(1, 0, clicked, "none")
                    if dist == 3 then
                        move_line(1, 0, clicked, "castle")
                    end
                else
                    dist = move_line(-1, 0, clicked, "none")
                    if dist == 4 then
                        for i = clicked.x - 2, clicked.x - 1 do
                            print(i)
                            move_set(i, clicked.y, clicked, "castle")
                        end
                    end
                end
            end
        end
    end
    for x = -1, 1 do
        for y = -1, 1 do
            move_set(clicked.x + x, clicked.y + y, clicked, threat)
        end
    end
end

function piece_potential_move(piece, threat)
    if piece.name == "pawn" then
        if piece.team == "white" then
            pawn_move(piece, -1, threat)
        else
            pawn_move(piece, 1, threat)
        end
    elseif piece.name == "knight" then
        knight_move(piece, threat)
    elseif piece.name == "bishop" then
        bishop_move(piece, threat)
    elseif piece.name == "rook" then
        rook_move(piece, threat)
    elseif piece.name == "queen" then
        queen_move(piece, threat)
    elseif piece.name == "king" then
        king_move(piece, threat)
    end
end

function castle_rook_jump(side)
    for k, v in pairs(globals.pieces) do
        if v.x == 1 and v.team == globals.turn and v.name == "rook" and side == "queen" then
            piece_move(k, 4, 8)
        elseif v.x == 8 and v.team == globals.turn and v.name == "rook" and side == "king" then
            piece_move(k, 6, 8)
        end
    end
end

function threat_clear()
    globals.check = false
    for x = 1, 8 do
        for y = 1, 8 do
            globals.board[x][y].threat = 0
        end
    end
end

function threat_debug()
    local dbg = ""
    for y = 1, 8 do
        for x = 1, 8 do
            if globals.board[x][y].threat >= 0 then
                dbg = dbg.." "..globals.board[x][y].threat
            else
                dbg = dbg..globals.board[x][y].threat
            end
        end
        dbg = dbg.."\n"
    end
    print(dbg)
end

function threat_recalculate()
    threat_clear()
    for k, v in pairs(globals.pieces) do
        if k ~= globals.selectedPiece and piece_here(v.x, v.y) == k then
            piece_potential_move(v, "threat")
        end
    end
end

function square_protected(sq)
    return sq.threat and ((sq.threat <= 0 and globals.turn == "black") or (sq.threat >= 0 and globals.turn == "white"))
end

function square_threatened(sq)
    return sq.threat and ((sq.threat < 0 and globals.turn == "white") or (sq.threat > 0 and globals.turn == "black"))
end

function game_select_piece(tx, ty)
    if globals.players == 0 or (globals.players == 1 and globals.halfmoves % 2 == 1) then
        return
    end
    local clicked = piece_here(tx, ty)
    if clicked and globals.pieces[clicked].team == globals.turn then
        for x = 1, 8 do
            for y = 1, 8 do
                globals.board[x][y].highlight = nil
                globals.board[x][y].moveok = nil
            end
        end
        if clicked == globals.selectedPiece then 
            globals.selectedPiece = -1
            threat_recalculate()
        else
            globals.selectedPiece = clicked
            globals.board[globals.pieces[clicked].x][globals.pieces[clicked].y].highlight = true
            threat_recalculate()
            piece_potential_move(globals.pieces[clicked], "move")
        end
        return true 
    end
    return false
end

function game_move_piece(tx, ty)
    local square = board_get(tx, ty)
    local ox = globals.pieces[globals.selectedPiece].x
    local oy = globals.pieces[globals.selectedPiece].y
    local op = globals.board[tx][ty].piece
    globals.checkLastTurn = globals.check
    if square and square.moveok then
        piece_move(globals.selectedPiece, tx, ty)
        threat_recalculate()
        if globals.check and globals.checkLastTurn then
            -- move is disallowed; roll it back
            piece_move(globals.selectedPiece, ox, oy)
            if op then globals.board[tx][ty].piece = op end
            threat_recalculate()
        else
            -- If the selected move was a castling move, also move the rook next to it.
            if square.castle == true then
                if tx < 4 then castle_rook_jump("queen") else castle_rook_jump("king") end
                square.castle = nil
            end
            for x = 1, 8 do
                for y = 1, 8 do
                    globals.board[x][y].highlight = nil
                    globals.board[x][y].moveok = nil
                end
            end
            globals.pieces[globals.selectedPiece].moved = true
            globals.selectedPiece = -1
            if globals.turn == "white" then globals.turn = "black" else globals.turn = "white" end
            threat_recalculate()
            tally_move()
        end
    end
end

function engine_turn()
    garbo.InitializeFromFen(board_to_fen())
    local move = garbo.Move(globals.difficulty)
    if garbo.GameOver() then
        globals.checkmate = true
        return
    end
    threat_recalculate()
    if move == "e8g8" then
        piece_move(globals.board[5][1].piece, 7, 1)
        castle_rook_jump("king")
    elseif move == "e8c8" then
        piece_move(globals.board[5][1].piece, piece, 3, 1)
        castle_rook_jump("queen")
    else
        local x = move:sub(1, 1):byte() - 96
        local y = 9 - move:sub(2, 2)
        local xto = move:sub(3, 3):byte() - 96
        local yto = 9 - move:sub(4, 4)
        local pieceToMove = globals.board[x][y].piece
        if not pieceToMove then
            error("Engine tried to move a piece which we think does not exist at "..x..", "..y..". FEN .."..board_to_fen())
        end
        piece_move(pieceToMove, xto, yto)
    end
    
    if globals.turn == "white" then globals.turn = "black" else globals.turn = "white" end
    threat_recalculate()
    tally_move()
end

function love.load()
    globals.pieceImg = love.graphics.newImage("set.png")
    for x = 0, 5 do
        for y = 0, 1 do
            table.insert(globals.pieceQuads, love.graphics.newQuad(x * SQ_SIZE, y * SQ_SIZE, SQ_SIZE, SQ_SIZE, globals.pieceImg:getWidth(), globals.pieceImg:getHeight()))
        end
    end
    for x = 1, 8 do
        globals.board[x] = {}
        for y = 1, 8 do
            globals.board[x][y] = {}
        end
    end
    for k, v in pairs(globals.pieces) do
        globals.board[v.x][v.y].piece = k
    end
    threat_recalculate()
end

function love.mousepressed(x, y, button, istouch, presses)
    if globals.checkmate == true then 
        love.event.quit()
    end
    local tx = math.floor(x / SQ_SIZE)
    local ty = math.floor(y / SQ_SIZE)
    if tx > 8 or tx < 1 or ty > 8 or ty < 1 then
        return
    end
    if not game_select_piece(tx, ty) and globals.selectedPiece > -1 then
        game_move_piece(tx, ty)
    end
end

function love.update()
    if globals.players == 0 or (globals.players == 1 and globals.halfmoves % 2 == 1) then
        globals.aicounter = globals.aicounter + 1
        if globals.aicounter >= 20 then
            engine_turn()
            globals.aicounter = 0
        end
    end
end

function love.draw()
    if globals.check then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Check!", 0, 0)
    end
    if globals.checkmate then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Checkmate!", 0, 0)
    end
    local whiteSquare = true
    for x = 1, 8 do
        for y = 1, 8 do
            if whiteSquare then
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(0, 0, 0)
            end
            love.graphics.rectangle("fill", x * SQ_SIZE, y * SQ_SIZE, SQ_SIZE, SQ_SIZE)
            if y ~= 8 then    
                whiteSquare = not whiteSquare
            end
            love.graphics.setColor(1, 1, 1)
            local sq = globals.board[x][y]
            if sq.moveok or sq.highlight or sq.piece then --(sq.piece and globals.pieces[sq.piece].team == globals.turn) then
                if square_protected(sq) then
                    love.graphics.setColor(0, 1, 0, 0.1 * math.abs(sq.threat))
                    love.graphics.rectangle("fill", x * SQ_SIZE, y * SQ_SIZE, SQ_SIZE, SQ_SIZE)
                    love.graphics.setColor(0, 0, 0, 1)
                    love.graphics.print(math.abs(sq.threat), x * SQ_SIZE + 1, y * SQ_SIZE + 1)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(math.abs(sq.threat), x * SQ_SIZE, y * SQ_SIZE)
                end
                if square_threatened(sq) then
                    love.graphics.setColor(1, 0, 0, 0.15 * math.abs(sq.threat))
                    love.graphics.rectangle("fill", x * SQ_SIZE, y * SQ_SIZE, SQ_SIZE, SQ_SIZE)
                    love.graphics.setColor(0, 0, 0, 1)
                    love.graphics.print(math.abs(sq.threat), x * SQ_SIZE + 1, y * SQ_SIZE + 1)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.print(math.abs(sq.threat), x * SQ_SIZE, y * SQ_SIZE)
                end
                if sq.moveok or sq.highlight then
                    love.graphics.setColor(0, 0.8, 0)
                    love.graphics.rectangle("line", x * SQ_SIZE + 1, y * SQ_SIZE + 1, SQ_SIZE - 1, SQ_SIZE - 1)
                    love.graphics.rectangle("line", x * SQ_SIZE, y * SQ_SIZE, SQ_SIZE, SQ_SIZE)
                end
            end
            if sq.piece then 
                love.graphics.draw(globals.pieceImg, globals.pieceQuads[globals.pieces[sq.piece].quad], x * SQ_SIZE, y * SQ_SIZE)
            end
        end
    end
end