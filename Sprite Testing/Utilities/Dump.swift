//
//  Dump.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 13/07/25.
//

import Foundation
import SpriteKit

class Dump: SKScene, SKPhysicsContactDelegate{
    var character: SKSpriteNode!
    var backgrounds: [SKSpriteNode] = []
    var runnerNode: SKSpriteNode?
    var objectUnderCharacter: SKSpriteNode?
    var scoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    
    private var coinCount = 0
    private var internalScore = 0
    private var scoreTimer: Timer?
    
    let characterCategory: UInt32 = 0x1 << 0
    let groundCategory: UInt32 = 0x1 << 1
    let obstacleCategory: UInt32 = 0x1 << 2
    let coinCategory: UInt32 = 0x1 << 3
    let powerUpCategory: UInt32 = 0x1 << 4
    
    var characterAnimationSpeed: Double = 0.1
    var characterTextures: [SKTexture] = []
   
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = CGVector(dx: 0, dy: -5)
        physicsWorld.contactDelegate = self
        
        for i in 0..<2 {
            let background = SKSpriteNode(imageNamed: "background-2")
            background.name = "background"
            background.zPosition = -1
            background.size = self.size
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: CGFloat(i) * self.size.width, y: 0) // Center it
            backgrounds.append(background)
            addChild(background)
        }
        
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: self.size.height / 4 - 75)
        ground.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x:0, y:0), to: CGPoint(x: self.size.width, y: 0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 0x1 << 1
        addChild(ground)
        ground.physicsBody?.restitution = 0
        
        
        let spawnAction = SKAction.sequence([
            SKAction.run { self.spawnGroundObject() },
            SKAction.wait(forDuration: 2.0)
        ])
        run(SKAction.repeatForever(spawnAction))
        
        let coinSpawnAction = SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run { self.spawnCoinChunk() },
            SKAction.wait(forDuration: 3.0)
        ])
        run(SKAction.repeatForever(coinSpawnAction))
        
        let powerUpAction = SKAction.sequence([
            SKAction.wait(forDuration: 10.0),
            SKAction.run { self.spawnPowerUp() }
        ])
        run(SKAction.repeatForever(powerUpAction))

        
        animateCharacter()
        animateRunner()
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(_ :)))
        swipeUp.direction = .up
        self.view?.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_ :)))
        swipeDown.direction = .down
        self.view?.addGestureRecognizer(swipeDown)
        
        startScoreTimer()
    }
    
    func animateCharacter() {
        let spriteSheet = SKTexture(imageNamed: "cat") // 3x3 grid
        let rows = 3
        let columns = 3
        let frameCount = rows * columns
        let frameWidth = 1.0 / CGFloat(columns)
        let frameHeight = 1.0 / CGFloat(rows)
        var textures: [SKTexture] = []
        
        for row in 0..<rows {
            for column in 0..<columns {
                let rect = CGRect(
                    x: CGFloat(column) * frameWidth,
                    y: CGFloat(rows - 1 - row) * frameHeight, // SpriteKit uses bottom-left origin
                    width: frameWidth,
                    height: frameHeight
                )
                let frameTexture = SKTexture(rect: rect, in: spriteSheet)
                textures.append(frameTexture)
            }
        }
        
        character = SKSpriteNode(texture: textures.first)
        character.setScale(0.6)
        
        character.position = CGPoint(x: self.size.width / 4, y: self.size.height  / 4)
        
        character.physicsBody = SKPhysicsBody(rectangleOf: character.size)
        character.physicsBody?.allowsRotation = false
        character.physicsBody?.categoryBitMask = 0x1 << 0
        character.physicsBody?.contactTestBitMask = 0x1 << 1  | (0x1 << 2)
        character.physicsBody?.collisionBitMask = 0x1 << 1  | (0x1 << 2)
        character.physicsBody?.restitution = 0
        character.physicsBody?.friction = 0.2
        character.physicsBody?.linearDamping = 0.1
        
        self.addChild(character)
        
        self.characterTextures = textures  // Add this
        let animation = SKAction.animate(with: characterTextures, timePerFrame: characterAnimationSpeed)
        character.run(SKAction.repeatForever(animation), withKey: "characterRun")
    }
    
    func animateRunner(){
        let spriteSheet = SKTexture(imageNamed: "running")
        let rows = 2
        let columns = 5
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
        
        let runner = SKSpriteNode(texture: textures.first)
        runner.setScale(0.6)
        runner.position = CGPoint(x: self.size.width/6 - 50 , y: self.size.height / 4)
        runner.zPosition = character.zPosition - 1
        
        self.runnerNode = runner  // Save runner reference
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        runner.run(SKAction.repeatForever(animation))
        
        addChild(runner)
    }
    
    @objc func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        // Supaya cuma bisa lompat kalau ada di ground
        if let physicsBody = character.physicsBody, abs(physicsBody.velocity.dy) < 1.0 {
            character.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 350))
            character.physicsBody?.linearDamping = 0.1        }
    }
    
    @objc func handleSwipeDown(_ sender: UISwipeGestureRecognizer) {
        if let physicsBody = character.physicsBody, abs(physicsBody.velocity.dy) < 1.0 {
            // Optional downward impulse
            character.physicsBody?.applyImpulse(CGVector(dx: 0, dy: -350))
            
            // Shrink Y scale
            let originalYScale = character.yScale
            let newYScale: CGFloat = originalYScale * 0.5
            let scaleAction = SKAction.scaleY(to: newYScale, duration: 0.1)
            
            // Move up so feet stay grounded
            let heightDiff = character.size.height * (originalYScale - newYScale) / 2
            let moveUpAction = SKAction.moveBy(x: 0, y: heightDiff, duration: 0.1)
            
            // Run crouch action
            character.run(SKAction.group([scaleAction, moveUpAction]))
            
            // ⏱ Reset scale and position after delay
            let resetScale = SKAction.scaleY(to: originalYScale, duration: 0.1)
            let moveDown = SKAction.moveBy(x: 0, y: -heightDiff, duration: 0.1)
            let wait = SKAction.wait(forDuration: 1.0)
            
            let resetAction = SKAction.sequence([wait, SKAction.group([resetScale, moveDown])])
            character.run(resetAction)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Scroll background
        for bg in backgrounds {
            bg.position.x -= 4
            if bg.position.x <= -bg.size.width {
                bg.position.x += bg.size.width * 2
            }
        }
        
        // Move character with object if standing on it
        if let object = objectUnderCharacter {
            // Check if still vertically close (for safety)
            let charBottom = character.position.y - character.size.height / 2
            let objTop = object.position.y + object.size.height / 2
            if abs(charBottom - objTop) < 10 {
                character.position.x -= 4
            }
        }
        
        if character.position.y < -character.size.height {
            restartGame()
        }
    }
    
    func startScoreTimer() {
        scoreTimer?.invalidate()
        internalScore = 0
        scoreUpdateHandler?(internalScore)
        
        scoreTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.internalScore += 1
            self.scoreUpdateHandler?(self.internalScore)
        }
    }
    
    func restartGame() {
        scoreTimer?.invalidate()

        // Reset score and coins
        internalScore = 0
        coinCount = 0
        scoreUpdateHandler?(internalScore)
        coinUpdateHandler?(coinCount)

        if let view = self.view {
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
            newScene.scoreUpdateHandler = self.scoreUpdateHandler
            newScene.coinUpdateHandler = self.coinUpdateHandler  // ← Also reassign this!
            let transition = SKTransition.fade(withDuration: 0.5)
            view.presentScene(newScene, transition: transition)
        }
    }
    
    func spawnGroundObject() {
        let imageNames = ["barrier", "gerobak-1", "gerobak-2"]
        let randomImageName = imageNames.randomElement() ?? "barrier"
        
        let object = SKSpriteNode(imageNamed: randomImageName)
        
        // Default values
        var scale: CGFloat = 0.5
        var yPos: CGFloat = self.size.height / 3
        
        // Customize size and position per image
        switch randomImageName {
        case "barrier":
            scale = 0.3
            yPos = self.size.height / 3.5
        case "gerobak-1":
            scale = 0.5
            yPos = self.size.height / 3
        case "gerobak-2":
            scale = 0.4
            yPos = self.size.height / 3.5
        default:
            break
        }
        
        object.setScale(scale)
        object.position = CGPoint(x: self.size.width + object.size.width / 2, y: yPos)
        object.zPosition = 1
        
        // Use actual scaled size for physics body
        let scaledSize = CGSize(width: object.size.width * object.xScale,
                                height: object.size.height * object.yScale)
        
        object.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
        object.physicsBody?.isDynamic = false
        object.physicsBody?.categoryBitMask = 0x1 << 2 // Obstacle
        object.physicsBody?.contactTestBitMask = 0x1 << 0
        object.physicsBody?.collisionBitMask = 0x1 << 0
        
        addChild(object)
        
        let moveDistance = self.size.width + 60 + object.size.width
        let backgroundSpeed: CGFloat = 240 // pts/sec
        let moveDuration = moveDistance / backgroundSpeed
        
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDuration))
        let remove = SKAction.removeFromParent()
        object.run(SKAction.sequence([move, remove]))
    }
    
    func spawnCoinChunk() {
        let chunkSize = Int.random(in: 1...3)
        let horizontalSpacing: CGFloat = 60

        // Force Y to spawn clearly *above* most obstacle heights
        let minYAboveObstacles = self.size.height / 2.5
        let maxY = self.size.height * 0.75
        let yPos = CGFloat.random(in: minYAboveObstacles...maxY)

        for i in 0..<chunkSize {
            let coin = SKSpriteNode(imageNamed: "coin")
            coin.setScale(0.1)
            coin.zPosition = 1

            let xOffset = CGFloat(i) * (horizontalSpacing + 10)
            coin.position = CGPoint(x: self.size.width + coin.size.width / 2 + xOffset, y: yPos)

            coin.physicsBody = SKPhysicsBody(circleOfRadius: coin.size.width / 2)
            coin.physicsBody?.isDynamic = false
            coin.physicsBody?.categoryBitMask = coinCategory
            coin.physicsBody?.contactTestBitMask = characterCategory
            coin.physicsBody?.collisionBitMask = 0

            addChild(coin)

            let moveDistance = self.size.width + 60 + coin.size.width + CGFloat(chunkSize - 1) * (horizontalSpacing + 10)
            let moveDuration = moveDistance / 240
            let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDuration))
            let remove = SKAction.removeFromParent()
            coin.run(SKAction.sequence([move, remove]))
        }
    }
    
    func spawnPowerUp() {
        let powerUp = SKSpriteNode(imageNamed: "cat food")
        powerUp.setScale(0.025)
        powerUp.zPosition = 1

        let minYAboveObstacles = self.size.height / 2.5
        let maxY = self.size.height * 0.75
        let yPos = CGFloat.random(in: minYAboveObstacles...maxY)
        powerUp.position = CGPoint(x: self.size.width + powerUp.size.width / 2, y: yPos)

        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width / 2)
        powerUp.physicsBody?.isDynamic = false
        powerUp.physicsBody?.categoryBitMask = powerUpCategory
        powerUp.physicsBody?.contactTestBitMask = characterCategory
        powerUp.physicsBody?.collisionBitMask = 0

        addChild(powerUp)

        let moveDistance = self.size.width + 60 + powerUp.size.width
        let moveDuration = moveDistance / 240
        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDuration))
        let remove = SKAction.removeFromParent()
        powerUp.run(SKAction.sequence([move, remove]))
    }
    
    func applyPowerUp() {
        // Speed up character animation
        character.removeAction(forKey: "characterRun")
        let fastAnimation = SKAction.animate(with: characterTextures, timePerFrame: characterAnimationSpeed * 0.1)
        character.run(SKAction.repeatForever(fastAnimation), withKey: "characterRun")

        // Move runner further back
        if let runner = runnerNode {
            let moveBack = SKAction.moveBy(x: -80, y: 0, duration: 0.2)
            runner.run(moveBack)
        }

        // Reset after 5 seconds
        let wait = SKAction.wait(forDuration: 5.0)
        let reset = SKAction.run {
            self.character.removeAction(forKey: "characterRun")
            let normalAnimation = SKAction.animate(with: self.characterTextures, timePerFrame: self.characterAnimationSpeed)
            self.character.run(SKAction.repeatForever(normalAnimation), withKey: "characterRun")

            if let runner = self.runnerNode {
                let moveForward = SKAction.moveBy(x: 80, y: 0, duration: 0.2)
                runner.run(moveForward)
            }
        }
        run(SKAction.sequence([wait, reset]))
    }

    
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        // MARK: - Character and Obstacle Contact
        if (a.categoryBitMask == characterCategory && b.categoryBitMask == obstacleCategory) ||
            (a.categoryBitMask == obstacleCategory && b.categoryBitMask == characterCategory) {
            
            let characterBody = a.categoryBitMask == characterCategory ? a : b
            let objectBody = a.categoryBitMask == obstacleCategory ? a : b
            
            // Only consider it a "landing" if character is coming from above
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
    
    func didEnd(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB
        
        // If character leaves obstacle
        if (a.categoryBitMask == 0x1 << 0 && b.categoryBitMask == 0x1 << 2) ||
            (a.categoryBitMask == 0x1 << 2 && b.categoryBitMask == 0x1 << 0) {
            objectUnderCharacter = nil
        }
    }
}
