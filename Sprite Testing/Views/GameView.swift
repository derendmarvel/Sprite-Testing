//
//  GameView.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 10/07/25.
//

import SwiftUI
import SpriteKit

struct GameView: View {
    @State private var score: Int = 0
    @State private var coin: Int = 0
    
    var scene: SKScene {
        let gameScene = GameScene(size: UIScreen.main.bounds.size)
        gameScene.scaleMode = .resizeFill
        gameScene.scoreUpdateHandler = { newScore in
            DispatchQueue.main.async {
                self.score = newScore
            }
        }
        
        gameScene.coinUpdateHandler = { newCoin in
            DispatchQueue.main.async {
                    self.coin = newCoin
            }
        }
        return gameScene
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            HStack{
                Spacer()
                VStack{
                    Text("Score: \(score)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    CoinTally(coinCount: coin)
                }
                .padding(.top, 40)
                .padding(.trailing, 20)
            }
            
        }
    }
}

#Preview {
    GameView()
}
