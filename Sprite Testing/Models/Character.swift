//
//  Character.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 11/07/25.
//

import Foundation
import SpriteKit

class Character: SKSpriteNode {
    var textures: [SKTexture] = []

    init(position: CGPoint) {
        let texture = SKTexture(imageNamed: "cat")
        super.init(texture: texture, color: .clear, size: texture.size())
        self.position = position
        self.setScale(0.18)
        setupPhysics()
        loadTextures()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(rectangleOf: self.size)
        self.physicsBody?.allowsRotation = false
        self.physicsBody?.categoryBitMask = 0x1 << 0
        self.physicsBody?.contactTestBitMask = 0x1 << 1 | 0x1 << 2
        self.physicsBody?.collisionBitMask = 0x1 << 1 | 0x1 << 2
        self.physicsBody?.restitution = 0
        self.physicsBody?.friction = 0.2
        self.physicsBody?.linearDamping = 0.1
    }

    private func loadTextures() {
        let spriteSheet = SKTexture(imageNamed: "cat")
        let rows = 3, columns = 3
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)

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
    }

    func playRunAnimation(speed: Double) {
        self.removeAction(forKey: "characterRun")
        let animation = SKAction.animate(with: textures, timePerFrame: speed)
        self.run(SKAction.repeatForever(animation), withKey: "characterRun")
    }

    func performCrouch() {
        let originalYScale = self.yScale
        let newYScale = originalYScale * 0.5
        let scaleAction = SKAction.scaleY(to: newYScale, duration: 0.1)
        let heightDiff = self.size.height * (originalYScale - newYScale) / 2
        let moveUpAction = SKAction.moveBy(x: 0, y: heightDiff, duration: 0.1)
        let resetScale = SKAction.scaleY(to: originalYScale, duration: 0.1)
        let moveDown = SKAction.moveBy(x: 0, y: -heightDiff, duration: 0.1)
        let wait = SKAction.wait(forDuration: 1.0)
        let resetAction = SKAction.sequence([wait, SKAction.group([resetScale, moveDown])])

        self.run(SKAction.group([scaleAction, moveUpAction]))
        self.run(resetAction)
    }
}
