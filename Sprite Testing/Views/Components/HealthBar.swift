//
//  HealthBar.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 15/07/25.
//

import SwiftUI

struct HealthBar: View {
    var health: Int
    
    var body: some View {
        VStack {
            HStack {
                ZStack(alignment: .topLeading) { // align content to top-leading
                    Image("HealthBarBackground")
                        .resizable()
                        .frame(width: 240, height: 83)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<health) { _ in
                            Image("HealthBar")
                                .resizable()
                                .frame(width: 15, height: 28)
                        }
                    }
                    .padding(.top, 39) // only top padding, no leading
                    .padding(.leading, 68) // optional fine adjustment
                }
                Spacer()
            }
            Spacer()
        }
        .padding(.top, 32)
    }
}

#Preview {
    HealthBar(health: 9)
}
