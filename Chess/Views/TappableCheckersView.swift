//
//  TappableCheckersView.swift
//  Chess
//
//  Created by David Crooks on 28/09/2019.
//  Copyright © 2019 david crooks. All rights reserved.
//

import SwiftUI
struct TappableCheckersView: View {
    
    @ObservedObject var store: Store<AppState,AppAction>
    
    let width:CGFloat
    
    var squareWidth:CGFloat {
        return width/8.0
    }
    
    func selectOrMove(to square:ChessboardSquare) {
        store.send(.selection(.select(square)))
        
        if let selectedSquare = store.value.selectedSquare, selectedSquare != square {
            let move =  ChessMove(from: selectedSquare,to:square)
            store.send(.chess(.move(move)))
            
        }
    }

    var body: some View {
        HStack(alignment: .center,spacing:0)
                       {
                        ForEach(ChessFile.allCases)
                           { file in
                               
                               VStack(alignment: .center, spacing:0)
                               {
                                ForEach(ChessRank.allCases.reversed()) { rank in
                                       
                                                   Button(action:{
                                                    self.selectOrMove(to:ChessboardSquare(rank:rank, file:file))
                                                   } ){
                                                    Spacer().frame(width:self.squareWidth,height: self.squareWidth)
                                                       }
                                                   .frame(width:self.squareWidth, height: self.squareWidth, alignment: .center)
                                       
                                                   }
                                      
                               }
                           }
        }.animation(.easeInOut(duration: 0.2))
    }
}


   
/*
struct TappableCheckersView_Previews: PreviewProvider {
    static var previews: some View {
        TappableCheckersView()
    }
}
*/
