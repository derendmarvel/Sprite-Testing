//
//  SpawnFactory.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 13/07/25.
//

import Foundation
import SpriteKit

class SpawnFactory {
    static func createGroundObject(scene: SKScene, obstacleCategory: UInt32, characterCategory: UInt32) -> SKSpriteNode {
        let imageNames = ["barrier", "gerobak-1", "gerobak-2"]
        let randomImageName = imageNames.randomElement() ?? "barrier"
        let object = SKSpriteNode(imageNamed: randomImageName)

        var scale: CGFloat = 0.5
        var yPos: CGFloat = scene.size.height / 3
        switch randomImageName {
        case "barrier": scale = 0.3; yPos = scene.size.height / 3.5
        case "gerobak-1": scale = 0.45; yPos = scene.size.height / 3
        case "gerobak-2": scale = 0.4; yPos = scene.size.height / 3.5
        default: break
        }

        object.setScale(scale)
        object.position = CGPoint(x: scene.size.width + object.size.width / 2, y: yPos)
        object.zPosition = 1

        let scaledSize = CGSize(width: object.size.width * object.xScale, height: object.size.height * object.yScale)
        object.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
        object.physicsBody?.isDynamic = false
        object.physicsBody?.categoryBitMask = obstacleCategory
        object.physicsBody?.contactTestBitMask = characterCategory
        object.physicsBody?.collisionBitMask = characterCategory

        let moveDistance = scene.size.width + 60 + object.size.width
        let moveDuration = moveDistance / 240
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDuration))
        let remove = SKAction.removeFromParent()
        object.run(SKAction.sequence([move, remove]))

        return object
    }

    static func createCoin(at position: CGPoint, characterCategory: UInt32, coinCategory: UInt32) -> SKSpriteNode {
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.setScale(0.07)
        coin.position = position
        coin.zPosition = 1

        coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2)
        coin.physicsBody?.isDynamic = false
        coin.physicsBody?.categoryBitMask = coinCategory
        coin.physicsBody?.contactTestBitMask = characterCategory
        coin.physicsBody?.collisionBitMask = 0
        
        let moveDistance = UIScreen.main.bounds.width + 100
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDistance / 240))
        let remove = SKAction.removeFromParent()
        coin.run(SKAction.sequence([move, remove]))

        return coin
    }

    static func createPowerUp(at position: CGPoint, characterCategory: UInt32, powerUpCategory: UInt32) -> SKSpriteNode {
        let powerUp = SKSpriteNode(imageNamed: "cat food")
        powerUp.setScale(0.025)
        powerUp.position = position
        powerUp.zPosition = 1

        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width / 2)
        powerUp.physicsBody?.isDynamic = false
        powerUp.physicsBody?.categoryBitMask = powerUpCategory
        powerUp.physicsBody?.contactTestBitMask = characterCategory
        powerUp.physicsBody?.collisionBitMask = 0
        
        let moveDistance = UIScreen.main.bounds.width + 100
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDistance / 240))
        let remove = SKAction.removeFromParent()
        powerUp.run(SKAction.sequence([move, remove]))

        return powerUp
    }
}
