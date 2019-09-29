//
//  ChessGameReducer.swift
//  Chess
//
//  Created by david crooks on 08/09/2019.
//  Copyright © 2019 david crooks. All rights reserved.
//

import Foundation

enum AppAction {
    case chess(ChessAction)
    case selection(SelectionAction)
}

func appReducer(_ value:inout AppState,_ action:AppAction)  {
    switch action {
    case .chess(let chessAction):
        chessReducer(board: &value.chessboard, action: chessAction)
    
    case .selection(let selectionAction):
        selectedSquareReducer(state: &value, action: selectionAction)
        
    }
}





