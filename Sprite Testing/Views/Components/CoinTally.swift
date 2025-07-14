//
//  CoinTally.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 11/07/25.
//

import SwiftUI

struct CoinTally: View {
    let coinCount: Int
    
    var body: some View {
        HStack{
            Image("coin")
                .resizable()
                .frame(width: 20, height: 20)
            Text("\(coinCount)")
                .font(.title2)
                .bold()
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .clipShape(Capsule())
    }
}

#Preview {
    CoinTally(coinCount: 0)
}
