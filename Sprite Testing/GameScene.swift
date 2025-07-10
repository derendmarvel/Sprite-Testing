//
//  GameScene.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 08/07/25.
//

import SpriteKit
import GameplayKit

enum ChunkType: CaseIterable {
    case barrier, gerobak1, gerobak2

    var weight: Int {
        switch self {
        case .barrier: return 33
        case .gerobak1: return 33
        case .gerobak2: return 33
        }
    }

    func createNode(at position: CGPoint) -> SKNode {
        let object: SKSpriteNode
        switch self {
        case .barrier:
            object = SKSpriteNode(imageNamed: "barrier")
            object.setScale(0.3)
        case .gerobak1:
            object = SKSpriteNode(imageNamed: "gerobak-1")
            object.setScale(0.3)
        case .gerobak2:
            object = SKSpriteNode(imageNamed: "gerobak-2")
            object.setScale(0.3)
        }

        object.position = position
        object.zPosition = 1
        let scaledSize = CGSize(
            width: object.size.width * object.xScale,
            height: object.size.height * object.yScale
        )
        object.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
        object.physicsBody?.isDynamic = false
        object.physicsBody?.categoryBitMask = 0x1 << 2
        object.physicsBody?.contactTestBitMask = 0x1 << 0
        object.physicsBody?.collisionBitMask = 0x1 << 0
        return object
    }
}


class GameScene: SKScene, SKPhysicsContactDelegate{
    var character: SKSpriteNode!
    var backgrounds: [SKSpriteNode] = []
    var objectUnderCharacter: SKSpriteNode?
    
    //Noise
    var noiseMap: GKNoiseMap!
    var lastGeneratedX: CGFloat = 800
    let chunkSpacing: CGFloat = 300
    var scrollOffsetX: CGFloat = 0
    var weightedChunkTypes: [ChunkType] = []
    var recentChunks: [ChunkType] = []

    
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
        
        let noiseSource = GKPerlinNoiseSource(frequency: 0.04, octaveCount: 3, persistence: 0.5, lacunarity: 2, seed: Int32(Int.random(in: 0..<2147483648)))
        let noise = GKNoise(noiseSource)
        noiseMap = GKNoiseMap(
            noise,
            size: vector_double2(1000, 1),
            origin: vector_double2(0, 0),
            sampleCount: vector_int2(1000, 1),
            seamless: false
        )
        
        for type in ChunkType.allCases {
            weightedChunkTypes += Array(repeating: type, count: type.weight)
        }

        
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: self.size.height / 4 - 75)
        ground.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x:0, y:0), to: CGPoint(x: self.size.width, y: 0))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = 0x1 << 1
        addChild(ground)
        
//        let spawnAction = SKAction.sequence([
//            SKAction.run { self.spawnGroundObject() },
//            SKAction.wait(forDuration: 2.0)
//        ])
//        run(SKAction.repeatForever(spawnAction))
        
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
        
        let scrollSpeed: CGFloat = 2
        scrollOffsetX += scrollSpeed
        generateProceduralChunks(cameraX: scrollOffsetX)
//        generateProceduralChunks(cameraX: character.position.x)

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
    
    func generateProceduralChunks(cameraX: CGFloat) {
        let spawnAheadDistance: CGFloat = 300

        while lastGeneratedX < cameraX + spawnAheadDistance {
            // 1. Sample noise
            let noiseIndex = Int32(lastGeneratedX / 200)
            let noiseValue = noiseMap.value(at: vector_int2(noiseIndex, 0))
            let normalized = max(0, min((noiseValue + 1) / 2, 1)) // 0...1

            // 2. Use noise as seed to shuffle weighted chunk types
            var shuffled = weightedChunkTypes.shuffled()
            let noiseSeedIndex = Int(CGFloat(normalized) * CGFloat(shuffled.count - 1))
            let candidate = shuffled[noiseSeedIndex]

            // 3. Check if we've seen this chunk type too recently
            var type = candidate
            if recentChunks.suffix(3).allSatisfy({ $0 == candidate }) {
                // Force something else if it's too repetitive
                type = ChunkType.allCases.filter { $0 != candidate }.randomElement()!
            }

            recentChunks.append(type)
            if recentChunks.count > 5 {
                recentChunks.removeFirst()
            }

            // 4. Spawn the chunk
            let position = CGPoint(x: lastGeneratedX, y: self.size.height / 3 - 40)
            let chunk = type.createNode(at: position)
            addChild(chunk)

            let scrollSpeed: CGFloat = 240.0 // pts/sec
            let travelDistance = position.x + 300
            let moveDuration = TimeInterval(travelDistance / scrollSpeed)

            chunk.run(.sequence([.moveBy(x: -travelDistance, y: 0, duration: moveDuration), .removeFromParent()]))

            lastGeneratedX += CGFloat.random(in: 150...300)
            print("Generated \(type) at x=\(lastGeneratedX)")
        }
    }

    
//    func generateProceduralChunks(cameraX: CGFloat) {
//        let spawnAheadDistance: CGFloat = 300
//
//        while lastGeneratedX < cameraX + spawnAheadDistance {
//            // Use noise to get a smooth value
//            let noiseIndex = Int32(lastGeneratedX / CGFloat.random(in: 150...300))
//            let noiseValue = noiseMap.value(at: vector_int2(noiseIndex, 0))
//            let normalized = max(0, min((noiseValue + 1) / 2, 1)) // -1 to 1 → 0 to 1
//
//            // Select type based on weighted distribution
//            let weightedIndex = Int(CGFloat(normalized) * CGFloat(weightedChunkTypes.count - 1))
//            let type = weightedChunkTypes[weightedIndex]
//
//            // Place chunk
//            let position = CGPoint(x: lastGeneratedX, y: self.size.height / 3 - 40)
//            let chunk = type.createNode(at: position)
//            addChild(chunk)
//
//            // Animate chunk moving left at the same speed as the background
//            let scrollSpeed: CGFloat = 240.0 // pts per second
//            let travelDistance = position.x + 300
//            let moveDuration = TimeInterval(travelDistance / scrollSpeed)
//
//            let move = SKAction.moveBy(x: -travelDistance, y: 0, duration: moveDuration)
//            let remove = SKAction.removeFromParent()
//            chunk.run(SKAction.sequence([move, remove]))
//
//            // Random spacing between chunks
//            lastGeneratedX += CGFloat.random(in: 150...300)
//
//            print("Generated \(type) at x=\(lastGeneratedX)")
//        }
//    }
    
//    func spawnGroundObject() {
//        let imageNames = ["barrier", "gerobak-1", "gerobak-2"]
//        let randomImageName = imageNames.randomElement() ?? "barrier"
//        
//        let object = SKSpriteNode(imageNamed: randomImageName)
//
//        // Default values
//        var scale: CGFloat = 0.5
//        var yPos: CGFloat = self.size.height / 3
//
//        // Customize size and position per image
//        switch randomImageName {
//        case "barrier":
//            scale = 0.3
//            yPos = self.size.height / 3.5
//        case "gerobak-1":
//            scale = 0.5
//            yPos = self.size.height / 3
//        case "gerobak-2":
//            scale = 0.4
//            yPos = self.size.height / 3.5
//        default:
//            break
//        }
//
//        object.setScale(scale)
//        object.position = CGPoint(x: self.size.width + object.size.width / 2, y: yPos)
//        object.zPosition = 1
//
//        // Use actual scaled size for physics body
//        let scaledSize = CGSize(width: object.size.width * object.xScale,
//                                height: object.size.height * object.yScale)
//
//        object.physicsBody = SKPhysicsBody(rectangleOf: scaledSize)
//        object.physicsBody?.isDynamic = false
//        object.physicsBody?.categoryBitMask = 0x1 << 2 // Obstacle
//        object.physicsBody?.contactTestBitMask = 0x1 << 0
//        object.physicsBody?.collisionBitMask = 0x1 << 0
//
//        addChild(object)
//
//        let moveDistance = self.size.width + 60 + object.size.width
//        let backgroundSpeed: CGFloat = 240 // pts/sec
//        let moveDuration = moveDistance / backgroundSpeed
//
//        let move = SKAction.moveBy(x: -moveDistance, y: 0, duration: TimeInterval(moveDuration))
//        let remove = SKAction.removeFromParent()
//        object.run(SKAction.sequence([move, remove]))
//    }
    
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
