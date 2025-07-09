//
//  GameScene.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 08/07/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate{
    var character: SKSpriteNode!
    var backgrounds: [SKSpriteNode] = []
    var objectUnderCharacter: SKSpriteNode?
    
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
        
        let spawnAction = SKAction.sequence([
            SKAction.run { self.spawnGroundObject() },
            SKAction.wait(forDuration: 2.0)
        ])
        run(SKAction.repeatForever(spawnAction))
        
        animateCharacter()
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeUp(_ :)))
        swipeUp.direction = .up
        self.view?.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown(_ :)))
        swipeDown.direction = .down
        self.view?.addGestureRecognizer(swipeDown)
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
        
        self.addChild(character)
        
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        character.run(SKAction.repeatForever(animation))
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
    
    func restartGame() {
        if let view = self.view {
            let newScene = GameScene(size: self.size)
            newScene.scaleMode = self.scaleMode
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        // Character and obstacle contact
        if (a.categoryBitMask == 0x1 << 0 && b.categoryBitMask == 0x1 << 2) ||
           (a.categoryBitMask == 0x1 << 2 && b.categoryBitMask == 0x1 << 0) {

            let characterBody = a.categoryBitMask == 0x1 << 0 ? a : b
            let objectBody = a.categoryBitMask == 0x1 << 2 ? a : b

            // Only consider it a "landing" if character is coming from above
            if character.physicsBody!.velocity.dy <= 0 {
                if let node = objectBody.node as? SKSpriteNode {
                    objectUnderCharacter = node
                }
            }
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
