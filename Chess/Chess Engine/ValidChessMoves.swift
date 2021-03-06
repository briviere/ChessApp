//
//  ValidChessMoves.swift
//  Chess
//
//  Created by david crooks on 14/09/2019.
//  Copyright © 2019 david crooks. All rights reserved.
//

import Foundation

func validate(chessboard:Chessboard, move:ChessMove) -> ChessMove? {
    
    guard let thePieceToMove = chessboard[move.from] else {
        //You can't move nothing
        return nil
    }
    
    if !isYourPiece(chessboard: chessboard, move: move) {
        return nil
    }
    
    if let thePieceToCapture = chessboard[move.to] {
        if thePieceToMove.player == thePieceToCapture.player {
            //you can't capture your own piece
            return nil
        }
    }
    
    func primaryMoveIsEqual(lhs:ChessMove,rhs:ChessMove) -> Bool {
        // Equal up to auxillary move (which is ignored)
        // User only indicates the primary move.
        return (lhs.from == rhs.from) && (lhs.to == rhs.to)
    }
    
    //return validMoves(chessboard: chessboard).contains(where: {primaryMoveIsEqual(lhs: $0, rhs: move)})
    return validMoves(chessboard: chessboard).first(where: {primaryMoveIsEqual(lhs: $0, rhs: move)})
}

func isValid(move:ChessMove, on board:Chessboard) -> Bool {
    validMoves(chessboard:board).contains(move)
}

func validMoves(chessboard:Chessboard) -> [ChessMove] {
    var moves =  uncheckedValidMoves(chessboard: chessboard)
            .filter {
                !isInCheck(chessboard:apply(move: $0, to:chessboard ), player: chessboard.whosTurnIsItAnyway)
                    }
    
    moves.append(contentsOf: validCastles(board: chessboard))
    
    return moves
}

/*
    Not checked for check!
*/
func uncheckedValidMoves(chessboard:Chessboard) -> [ChessMove] {
    var moves:[ChessMove] = []
    
    for square in chessboard.squares {
        moves += validMoves(chessboard: chessboard, for: square)
    }
    
    return moves
}


func isInCheck(chessboard:Chessboard, player:PlayerColor) -> Bool {
    
    var board = chessboard

    guard let kingSquare:ChessboardSquare = board.squares(with: ChessPiece(player: player, kind:.king,id:-1)).first else { fatalError() }
    
    if player == board.whosTurnIsItAnyway  {
        //If we are looking to see if the current players king is in check, we need the other players moves
        //So we flip player with a null move
        board = apply(move:ChessMove.nullMove, to: board)
    }
     
    let enemyMoves = uncheckedValidMoves(chessboard:board)
    
    let movesThatAttackTheKing = enemyMoves.filter { $0.to == kingSquare }
        
    return !movesThatAttackTheKing.isEmpty
    
}

func isControlled(square:ChessboardSquare, by player:PlayerColor, on chessboard:Chessboard) -> Bool {
    
    var board = chessboard

    //guard let kingSquare:ChessboardSquare = board.squares(with: ChessPiece(player: player, kind:.king,id:-1)).first else { fatalError() }
    
    if player != board.whosTurnIsItAnyway  {
        //If we are looking to see if the current players square is in check, we need the other players moves
        //So we flip player with a null move
        board = apply(move:ChessMove.nullMove, to: board)
    }
     
    let playerMoves = uncheckedValidMoves(chessboard:board)
    
    let movesThatAttackTheSquare = playerMoves.filter { $0.to == square }
        
    return !movesThatAttackTheSquare.isEmpty
    
}

func validMoves(chessboard:Chessboard, for square:ChessboardSquare) -> [ChessMove] {
    guard let piece = chessboard[square],
        piece.player == chessboard.whosTurnIsItAnyway
            else { return [] }
    
    //TODO : check/pinned to king?? // perhaps best done as a filter at the end
    
    switch piece.kind {
    
    case .pawn:
         return validPawnMoves(board: chessboard, square: square)
    case .knight:
         return validKnightMoves(board: chessboard, square: square)
    case .bishop:
         return validBishopMoves(board: chessboard, square: square)
    case .rook:
         return validRookMoves(board: chessboard, square: square)
    case .queen:
         return validQueenMoves(board: chessboard, square: square)
    case .king:
         return validKingMoves(board: chessboard, square: square)
    
    }
    
}

func getAllMoves(on board:Chessboard, from square:ChessboardSquare, in direction:ChessboardSquare.Direction)->[ChessMove]{
    return getAllMoves(on:board,from:square,currentSquare:square, in:direction)
}

func getAllMoves(on board:Chessboard,
                 from origin:ChessboardSquare ,
                 currentSquare square:ChessboardSquare,
                 in direction:ChessboardSquare.Direction) -> [ChessMove] {
    
    if let toSquare = square.getNeighbour(direction) , let  mv = makeMove(board: board, from:origin , to: toSquare) {
        if let piece = board[toSquare], piece.player != board.whosTurnIsItAnyway {
            //This is an enemy piece, which we can take, but we can't go any further in this direction, so we terminate here.
            return [mv]
        }
        return getAllMoves(on:board,from:origin,currentSquare:toSquare, in:direction) + [mv]
    }
    else {
        // We cannot go any further in this direction, either becuase we have reached the edge of the board,
        // or because one of our own pieces is in the way.
        return []
    }
}

func makeMove(board:Chessboard, from:ChessboardSquare, to:ChessboardSquare) -> ChessMove? {
    
    guard  board.whosTurnIsItAnyway != board[to]?.player else  { return nil }
    
    return ChessMove(from: from, to: to)
}

func makePawnForwardMove(board:Chessboard, from:ChessboardSquare, to:ChessboardSquare) -> ChessMove? {
    //Pawns cannot take moving forward, so "to" square must be empty
    
    guard let player = board[from]?.player,  board[to] == nil
        else  { return nil }
   
    return promotePawnIfValid(move:ChessMove(from: from, to: to), player:player)
}

func promotePawnIfValid(move:ChessMove,player:PlayerColor) -> ChessMove {
    let farRank  = (player == .white ) ? ChessRank._8 : ChessRank._1
    
    if move.to.rank == farRank {
        return ChessMove(from:move.from,to:move.to,aux: .promote( .queen))
    }
    else {
        return move
    }
}

func makePawnTakingdMove(board:Chessboard, from:ChessboardSquare, to:ChessboardSquare?) -> ChessMove? {
    //Pawns can only take diagonaly, so "to" square must contain an enemy piece
    
    guard  let to = to,
        let piece = board[to],
         let player = board[from]?.player,
        board.whosTurnIsItAnyway != piece.player
            else  { return nil }
    
    return promotePawnIfValid(move:ChessMove(from: from, to: to), player:player)
}

func validPawnMoves(board:Chessboard, square:ChessboardSquare) -> [ChessMove] {
    var moves:[ChessMove?] = []

    switch board.whosTurnIsItAnyway {
    
    case .white:
        if let sq1 = square.getNeighbour(.top) {
            let mv1 = makePawnForwardMove(board: board, from: square, to: sq1)
            moves.append(mv1)
            
            if let mv1 = mv1, square.rank == ._2 {
                if let sq2 = mv1.to.getNeighbour(.top) {
                    let mv2 = makePawnForwardMove(board: board, from: square, to: sq2)
                    moves.append(mv2)
                }
            }
        }
        
        //pawns take diagonally
        moves.append(makePawnTakingdMove(board: board, from: square, to:square.getNeighbour(.topRight)))
        moves.append(makePawnTakingdMove(board: board, from: square, to:square.getNeighbour(.topLeft)))
        
        //TODO : aun passnt
        
    case .black:
        
        if let sq1 = square.getNeighbour(.bottom) {
            let mv1 = makePawnForwardMove(board: board, from: square, to: sq1)
            moves.append(mv1)
            
            if let mv1 = mv1, square.rank == ._7 {
                if let sq2 = mv1.to.getNeighbour(.bottom) {
                    let mv2 = makePawnForwardMove(board: board, from: square, to: sq2)
                    moves.append(mv2)
                }
            }
        }
        
        
        
        //pawns take diagonally
        moves.append(makePawnTakingdMove(board: board, from: square, to:square.getNeighbour(.bottomRight)))
        moves.append(makePawnTakingdMove(board: board, from: square, to:square.getNeighbour(.bottomLeft)))
        
        //TODO : aun passnt
    
    }
   
    return moves.compactMap{$0}
}

func validKnightMoves(board:Chessboard, square:ChessboardSquare) -> [ChessMove] {
    
    var destionationSquares:[ChessboardSquare?] = []
    
    destionationSquares.append(square.getNeighbour(.top)?.getNeighbour(.top)?.getNeighbour(.left))
    destionationSquares.append(square.getNeighbour(.top)?.getNeighbour(.top)?.getNeighbour(.right))
    destionationSquares.append(square.getNeighbour(.bottom)?.getNeighbour(.bottom)?.getNeighbour(.left))
    destionationSquares.append(square.getNeighbour(.bottom)?.getNeighbour(.bottom)?.getNeighbour(.right))
    destionationSquares.append(square.getNeighbour(.left)?.getNeighbour(.left)?.getNeighbour(.top))
    destionationSquares.append(square.getNeighbour(.left)?.getNeighbour(.left)?.getNeighbour(.bottom))
    destionationSquares.append(square.getNeighbour(.right)?.getNeighbour(.right)?.getNeighbour(.top))
    destionationSquares.append(square.getNeighbour(.right)?.getNeighbour(.right)?.getNeighbour(.bottom))
    
    return destionationSquares
                .compactMap{$0}
                .compactMap{ makeMove(board: board, from: square, to: $0) }
}

extension Chessboard {
    var currentPlayersCastelState:CastelState {
        switch self.whosTurnIsItAnyway {
        case .white:
            return self.whiteCastelState
        case .black:
            return self.blackCastelState
        }
    }
}

func validKingMoves(board:Chessboard, square:ChessboardSquare) -> [ChessMove] {
    let player = board.whosTurnIsItAnyway
    
    
    guard let kingSquare:ChessboardSquare = board.squares(with: ChessPiece(player: player, kind:.king,id:-1)).first else { fatalError() }
    
    
    let directions = ChessboardSquare.Direction.allCases
    
    var moves = directions
                    .compactMap{square.getNeighbour($0)}
                    .compactMap{ makeMove(board: board, from: square, to: $0) }
    
    
   
   
    return moves
}

func validCastles(board:Chessboard) -> [ChessMove] {
    
    let castleState = board.currentPlayersCastelState
    let player = board.whosTurnIsItAnyway
    let opponent = !player
    
    if isInCheck(chessboard: board, player:player ) {
        return []
    }
       //TODO : rules of casteling - cannot castle if square are controled by enemy!
        guard let kingSquare:ChessboardSquare = board.squares(with: ChessPiece(player: player, kind:.king,id:-1)).first else { fatalError() }
       let rank = kingSquare.rank
    
       var moves:[ChessMove]  = []
    
       if castleState.canCastleKingside {
          
           let castleSquares = [ChessboardSquare(rank:rank , file: .g),
                                   ChessboardSquare(rank:rank , file: .f)
                                   ,ChessboardSquare(rank:rank , file: .h)]
           
           let piecesIntheMiddle = castleSquares
                                           .dropLast()
                                           .compactMap{board[$0]}
           
           
           let notControlled  = castleSquares.allSatisfy{!isControlled(square: $0, by: opponent, on: board)}
           
           let canCastle = piecesIntheMiddle.count == 0 && notControlled
           
           if canCastle  {
             moves.append(ChessMove(player: player, castleingSide: .kingside))
           }
       
       }
       
       if castleState.canCastleQueenside {
          
           let castleSquares = [ChessboardSquare(rank:rank , file: .a),
                                ChessboardSquare(rank:rank , file: .b),
                                 ChessboardSquare(rank:rank , file: .c),
                                 ChessboardSquare(rank:rank , file: .d)]
               
               
               
           let piecesIntheMiddle = castleSquares
                                           .dropFirst()
                                           .compactMap{board[$0]}
           
           let notControlled  = castleSquares.allSatisfy{!isControlled(square: $0, by: opponent, on: board)}
           
           let canCastle = piecesIntheMiddle.count == 0 && notControlled
           
           if canCastle  {
               moves.append(ChessMove(player: player, castleingSide: .queenside))
           }
          
       }
    return moves
}

func validBishopMoves(board:Chessboard, square:ChessboardSquare) -> [ChessMove] {
    let directions:[ChessboardSquare.Direction] = [.topLeft,.topRight,.bottomLeft,.bottomRight]
       
    return directions.flatMap{ getAllMoves(on: board, from: square, in: $0)}
}


func validRookMoves(board:Chessboard, square:ChessboardSquare) -> [ChessMove] {
    let directions:[ChessboardSquare.Direction] = [.bottom,.top,.left,.right]
    
    return directions.flatMap{ getAllMoves(on: board, from: square, in: $0)}
}


func validQueenMoves(board:Chessboard, square:ChessboardSquare) -> [ChessMove] {
    let directions = ChessboardSquare.Direction.allCases
    
    return directions.flatMap{ getAllMoves(on: board, from: square, in: $0)}
}




