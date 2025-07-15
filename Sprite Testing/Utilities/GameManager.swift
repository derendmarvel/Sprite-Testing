//
//  GameManager.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 13/07/25.
//

import Foundation
import SpriteKit

class GameManager {
    var scoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    var healthUpdateHandler: ((Int) -> Void)?
    
    unowned let scene: SKScene
    var character: Character!
    var runner: Runner!
    var objectUnderCharacter: SKSpriteNode?
    var coinCount = 0
    var internalScore = 0
    var scoreTimer: Timer?
    var health = 9
    var backgrounds: [SKSpriteNode] = []
    
    let characterOriginalX: CGFloat
    
    let characterCategory: UInt32 = 0x1 << 0
    let groundCategory: UInt32 = 0x1 << 1
    let obstacleCategory: UInt32 = 0x1 << 2
    let coinCategory: UInt32 = 0x1 << 3
    let powerUpCategory: UInt32 = 0x1 << 4
    
    init(scene: SKScene, scoreUpdateHandler: ((Int) -> Void)?, coinUpdateHandler: ((Int) -> Void)?, healthUpdateHandler: ((Int) -> Void)?) {
        self.scene = scene
        self.characterOriginalX = scene.size.width / 4
        self.scoreUpdateHandler = scoreUpdateHandler
        self.coinUpdateHandler = coinUpdateHandler
        self.healthUpdateHandler = healthUpdateHandler
    }
    
    func startGame() {
        guard let gameScene = scene as? GameScene else { return }
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: -7)
        scene.physicsWorld.contactDelegate = gameScene
        
        // Setup backgrounds
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "background-2")
            background.name = "background"
            background.zPosition = -1
            background.size = scene.size
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * scene.size.width, y: 0)
            backgrounds.append(background)
            scene.addChild(background)
        }
        
        // Setup ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: scene.size.height / 4 - 75)
        ground.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x:0, y:0), to: CGPoint(x: scene.size.width, y: 0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = groundCategory
        ground.physicsBody?.restitution = 0
        scene.addChild(ground)
        
        // Setup character and runner
        character = Character(position: CGPoint(x: characterOriginalX, y: scene.size.height / 4))
        scene.addChild(character)
        character.playRunAnimation(speed: 0.1)
        
        runner = Runner(position: CGPoint(x: scene.size.width/6 - 50, y: scene.size.height / 4 - 10))
        scene.addChild(runner)
        
        // Setup gestures
        let swipeUp = UISwipeGestureRecognizer(target: gameScene, action: #selector(GameScene.handleSwipeUp(_:)))
        swipeUp.direction = .up
        scene.view?.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: gameScene, action: #selector(GameScene.handleSwipeDown(_:)))
        swipeDown.direction = .down
        scene.view?.addGestureRecognizer(swipeDown)
        
        startSpawning()
        
        // Start score timer
        startScoreTimer()
    }
    
    func update(_ currentTime: TimeInterval) {
        // Scroll background
        for bg in backgrounds {
            bg.position.x -= 4
            if bg.position.x <= -bg.size.width {
                bg.position.x += bg.size.width * 2
            }
        }

        // Move character with object if standing on it
        if let object = objectUnderCharacter {
            let charBottom = character.position.y - character.size.height / 2
            let objTop = object.position.y + object.size.height / 2
            if abs(charBottom - objTop) < 10 {
                character.position.x -= 4
            }
        }

        // Gradually return character to original X
        let diff = characterOriginalX - character.position.x
        if abs(diff) > 1.0 {
            // Only push forward (never backward)
            character.position.x += min(2.0, diff)
        }

        // Restart if falls off screen
        if character.position.y < -character.size.height || character.position.x <= runner.position.x {
            restartGame()
        }
    }
    
    func restartGame() {
        scoreTimer?.invalidate()
        internalScore = 0
        coinCount = 0
        health = 9
        scoreUpdateHandler?(internalScore)
        coinUpdateHandler?(coinCount)
        healthUpdateHandler?(health)
        
        if let view = scene.view {
            let newScene = GameScene(size: scene.size)
            newScene.scaleMode = .aspectFill
            newScene.scoreUpdateHandler = self.scoreUpdateHandler
            newScene.coinUpdateHandler = self.coinUpdateHandler
            newScene.healthUpdateHandler = self.healthUpdateHandler
            let transition = SKTransition.fade(withDuration: 0.5)
            view.presentScene(newScene, transition: transition)
        }
    }
    
    func handleSwipeUp() {
        if abs(character.physicsBody?.velocity.dy ?? 0) < 1.0 {
            character.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 350))
        }
    }
    
    func handleSwipeDown() {
        if abs(character.physicsBody?.velocity.dy ?? 0) < 1.0 {
            character.performCrouch()
        }
    }
    
    func startScoreTimer() {
        scoreTimer?.invalidate()
        internalScore = 0
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.internalScore += 1
            self.scoreUpdateHandler?(self.internalScore)
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        // Handle contact logic
        
        // MARK: - Character and Obstacle Contact
        if (a.categoryBitMask == characterCategory && b.categoryBitMask == obstacleCategory) ||
            (a.categoryBitMask == obstacleCategory && b.categoryBitMask == characterCategory) {

            let characterNode = a.categoryBitMask == characterCategory ? a.node as! SKSpriteNode : b.node as! SKSpriteNode
            let obstacleNode = a.categoryBitMask == obstacleCategory ? a.node as! SKSpriteNode : b.node as! SKSpriteNode
            
            let characterFrame = characterNode.frame
            let obstacleFrame = obstacleNode.frame
            
            let charBottom = characterFrame.minY
            let obsTop = obstacleFrame.maxY
            let isAboveObstacle = charBottom > obsTop - 5

            let isSideCollision =
                (characterFrame.maxX > obstacleFrame.minX && characterFrame.minX < obstacleFrame.minX) ||
                (characterFrame.minX < obstacleFrame.maxX && characterFrame.maxX > obstacleFrame.maxX)

            if isAboveObstacle {
                objectUnderCharacter = obstacleNode
            } else if !isAboveObstacle && isSideCollision {
                print("Side collision detected!")
                applySideCollisionEffect()
            }
            
            // Ensure character lands on object correctly too
            let objectBody = a.categoryBitMask == obstacleCategory ? a : b
            if character.physicsBody!.velocity.dy <= 0 {
                if let node = objectBody.node as? SKSpriteNode {
                    objectUnderCharacter = node
                }
            }
        }
        
        // MARK: - Character and Coin Contact
        if (a.categoryBitMask == characterCategory && b.categoryBitMask == coinCategory) ||
            (a.categoryBitMask == coinCategory && b.categoryBitMask == characterCategory) {
            
            let coinBody = a.categoryBitMask == coinCategory ? a : b
            coinBody.node?.removeFromParent()
            
            coinCount += 1
            coinUpdateHandler?(coinCount)
        }
        
        // MARK: - Character and Power-Up Contact
        if (a.categoryBitMask == characterCategory && b.categoryBitMask == powerUpCategory) ||
            (a.categoryBitMask == powerUpCategory && b.categoryBitMask == characterCategory) {
            
            let powerUpNode = a.categoryBitMask == powerUpCategory ? a.node : b.node
            powerUpNode?.removeFromParent()
            
            applyPowerUp()
        }
    }
    
    func applyPowerUp() {
        character.removeAction(forKey: "characterRun")
        character.playRunAnimation(speed: 0.01)
        
        let moveBack = SKAction.moveBy(x: -80, y: 0, duration: 0.2)
        runner.run(moveBack)
        
        let wait = SKAction.wait(forDuration: 5.0)
        let reset = SKAction.run {
            self.character.removeAction(forKey: "characterRun")
            self.character.playRunAnimation(speed: 0.1)
        }
        
        scene.run(SKAction.sequence([wait, reset]))
    }
    
    func startSpawning() {
        let spawnObstacle = SKAction.run { [weak self] in
            guard let self = self else { return }

            let obstacle = SpawnFactory.createGroundObject(
                scene: self.scene,
                obstacleCategory: self.obstacleCategory,
                characterCategory: self.characterCategory
            )
            self.scene.addChild(obstacle)
        }

        let spawnCoinAndPowerUp = SKAction.run { [weak self] in
            guard let self = self else { return }

            let obstacleNodes = self.scene.children.compactMap {
                $0.physicsBody?.categoryBitMask == self.obstacleCategory ? $0 as? SKSpriteNode : nil
            }

            let obstacleRects = obstacleNodes.map { $0.calculateAccumulatedFrame() }

            let coinSpacing: CGFloat = 40.0
            let coinChunkSize = Int.random(in: 1...3)

            var attempts = 0
            while attempts < 10 {
                attempts += 1
                let coinY = CGFloat.random(in: self.scene.size.height / 3.2 ... self.scene.size.height / 1.5)

                var coinChunkRects: [CGRect] = []
                var allValid = true

                for i in 0..<coinChunkSize {
                    let coinX = self.scene.size.width + 30 + CGFloat(i) * coinSpacing
                    let coinRect = CGRect(x: coinX - 15, y: coinY - 15, width: 30, height: 30)
                    coinChunkRects.append(coinRect)

                    if obstacleRects.contains(where: { $0.intersects(coinRect.insetBy(dx: -10, dy: -10)) }) {
                        allValid = false
                        break
                    }
                }

                if allValid {
                    for rect in coinChunkRects {
                        let coin = SpawnFactory.createCoin(
                            at: CGPoint(x: rect.midX, y: rect.midY),
                            characterCategory: self.characterCategory,
                            coinCategory: self.coinCategory
                        )
                        self.scene.addChild(coin)
                    }
                    break
                }
            }

            // Spawn Power-Up
            if Int.random(in: 0..<4) == 0 {
                attempts = 0
                while attempts < 10 {
                    attempts += 1
                    let powerUpY = CGFloat.random(in: self.scene.size.height / 3.2 ... self.scene.size.height / 1.5)
                    let powerUpX = self.scene.size.width + CGFloat.random(in: 20...60)
                    let powerUpRect = CGRect(x: powerUpX - 20, y: powerUpY - 20, width: 40, height: 40)

                    if !obstacleRects.contains(where: { $0.intersects(powerUpRect.insetBy(dx: -10, dy: -10)) }) {
                        let powerUp = SpawnFactory.createPowerUp(
                            at: CGPoint(x: powerUpX, y: powerUpY),
                            characterCategory: self.characterCategory,
                            powerUpCategory: self.powerUpCategory
                        )
                        self.scene.addChild(powerUp)
                        break
                    }
                }
            }
        }

        let wait = SKAction.wait(forDuration: 2.0, withRange: 1.0)
        let spawnSequence = SKAction.sequence([spawnObstacle, spawnCoinAndPowerUp, wait])
        let repeatSpawn = SKAction.repeatForever(spawnSequence)

        scene.run(repeatSpawn, withKey: "spawnObstacles")
    }
    
    func applySideCollisionEffect() {
        health -= 1
        healthUpdateHandler?(health)
        
        print("Health decreased to \(health)")
        
        // Prevent multiple triggers
        guard character.action(forKey: "blinking") == nil else { return }

        // Blink animation (opacity blink)
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.1)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        let blinkSequence = SKAction.sequence([fadeOut, fadeIn])
        let blinkRepeat = SKAction.repeat(blinkSequence, count: 5)
        character.run(blinkRepeat, withKey: "blinking")

        // Slow animation
        character.removeAction(forKey: "characterRun")
        character.playRunAnimation(speed: 0.4) // slower speed
        
        let moveForward = SKAction.moveBy(x: 80, y: 0, duration: 0.2)
        runner.run(moveForward)

        // Restore after 3 seconds
        let restore = SKAction.run { [weak self] in
            self?.character.removeAction(forKey: "characterRun")
            self?.character.playRunAnimation(speed: 0.1) // normal speed
        }
    
        scene.run(SKAction.sequence([SKAction.wait(forDuration: 3.0), restore]))
    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        objectUnderCharacter = nil
    }
}
