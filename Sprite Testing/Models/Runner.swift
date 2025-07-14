//
//  Runner.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 13/07/25.
//

import Foundation
import SpriteKit

class Runner: SKSpriteNode {
    init(position: CGPoint) {
        let texture = SKTexture(imageNamed: "running")
        super.init(texture: texture, color: .clear, size: texture.size())
        self.position = position
        self.xScale = 0.15
        self.yScale = 0.3
        self.zPosition = -1
        setupAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupAnimation() {
        let spriteSheet = SKTexture(imageNamed: "running")
        let rows = 2, columns = 5
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)
        var textures: [SKTexture] = []

        for row in 0..<rows {
            for column in 0..<columns {
                let rect = CGRect(
                    x: CGFloat(column) * frameWidth,
                    y: CGFloat(rows - 1 - row) * frameHeight,
                    width: frameWidth,
                    height: frameHeight
                )
                let frameTexture = SKTexture(rect: rect, in: spriteSheet)
                textures.append(frameTexture)
            }
        }

        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        self.run(SKAction.repeatForever(animation))
    }
}
