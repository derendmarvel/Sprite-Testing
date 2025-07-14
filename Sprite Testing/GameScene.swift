//
//  GameScene.swift
//  Sprite Testing
//
//  Created by Derend Marvel Hanson Prionggo on 08/07/25.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var scoreUpdateHandler: ((Int) -> Void)?
    var coinUpdateHandler: ((Int) -> Void)?
    private var gameManager: GameManager!

    override func didMove(to view: SKView) {
        gameManager = GameManager(
            scene: self,
            scoreUpdateHandler: scoreUpdateHandler,
            coinUpdateHandler: coinUpdateHandler
        )
        gameManager.startGame()
    }

    override func update(_ currentTime: TimeInterval) {
        gameManager.update(currentTime)
    }

    func didBegin(_ contact: SKPhysicsContact) {
        gameManager.didBegin(contact)
    }

    func didEnd(_ contact: SKPhysicsContact) {
        gameManager.didEnd(contact)
    }

    @objc func handleSwipeUp(_ sender: UISwipeGestureRecognizer) {
        gameManager.handleSwipeUp()
    }

    @objc func handleSwipeDown(_ sender: UISwipeGestureRecognizer) {
        gameManager.handleSwipeDown()
    }
}
