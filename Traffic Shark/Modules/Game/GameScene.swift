//
//  Created by Aleksey Pirogov on 6/2/14.
//

import SpriteKit

protocol GameSceneDelegate {
    func gameEnded(score: Int)
    func scenePaused(_ paused: Bool)
    func displayCounter()
}

final class GameScene: SKScene, SKPhysicsContactDelegate {
    let gapBetweenPipes = 200.0
    
    var birdNode: SKSpriteNode!
    var skyBackgroundColor: SKColor!
    var pipeUpTexture: SKTexture!
    var pipeDownTexture: SKTexture!
    var explosionTexture: SKTexture!
    var birdTexture: SKTexture!
    var pipeMovementAction: SKAction!
    var movingNode: SKNode!
    var pipesNode: SKNode!
    var isRestartable = false
    var scoreLabel: SKLabelNode!
    var currentScore = 0
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    var continuousSpawnAction: SKAction?
    
    var sceneDelegate: GameSceneDelegate?
    
    var trailTimer: Timer?
    
    override var isPaused: Bool {
        didSet {
            sceneDelegate?.scenePaused(isPaused)
            
            if isPaused {
                trailTimer?.invalidate()
                trailTimer = nil
            } else {
                trailTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(createTrail), userInfo: nil, repeats: true)
            }
        }
    }

    override func didMove(to view: SKView) {
        isRestartable = true
        
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -5.0)
        self.physicsWorld.contactDelegate = self
        
        skyBackgroundColor = SKColor(red: 81.0 / 255.0, green: 192.0 / 255.0, blue: 201.0 / 255.0, alpha: 1.0)
        self.backgroundColor = skyBackgroundColor
        
        movingNode = SKNode()
        self.addChild(movingNode)
        pipesNode = SKNode()
        movingNode.addChild(pipesNode)
        
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        
        let moveGroundAction = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundAction = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundForeverAction = SKAction.repeatForever(SKAction.sequence([moveGroundAction, resetGroundAction]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / groundTexture.size().width) {
            let groundSprite = SKSpriteNode(texture: groundTexture)
            groundSprite.setScale(1.0)
            groundSprite.position = CGPoint(x: CGFloat(i) * groundSprite.size.width, y: groundSprite.size.height / 2.0)
            groundSprite.run(moveGroundForeverAction)
        }
        
        let skyTexture = SKTexture(imageNamed: "space")
        skyTexture.filteringMode = .nearest
        
        let moveSkyAction = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkyAction = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkyForeverAction = SKAction.repeatForever(SKAction.sequence([moveSkyAction, resetSkyAction]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / (skyTexture.size().width * 2)) {
            let skySprite = SKSpriteNode(texture: skyTexture)
            skySprite.setScale(1)
            skySprite.zPosition = -20
            skySprite.position = CGPoint(x: CGFloat(i) * skySprite.size.width, y: skySprite.size.height / 2.0)
            skySprite.run(moveSkyForeverAction)
            movingNode.addChild(skySprite)
        }
        
        pipeUpTexture = SKTexture(imageNamed: "PipeUp")
        pipeUpTexture.filteringMode = .nearest
        pipeDownTexture = SKTexture(imageNamed: "PipeDown")
        pipeDownTexture.filteringMode = .nearest
        explosionTexture = SKTexture(imageNamed: "explosion")
        explosionTexture.filteringMode = .nearest
        birdTexture = SKTexture(imageNamed: "bird-01")
        birdTexture.filteringMode = .nearest
        
        let pipeDistance = CGFloat(self.frame.size.width + 0.5 * pipeUpTexture.size().width)
        let movePipesAction = SKAction.moveBy(x: -pipeDistance, y: 0.0, duration: TimeInterval(0.01 * pipeDistance))
        let removePipesAction = SKAction.removeFromParent()
        pipeMovementAction = SKAction.sequence([movePipesAction, removePipesAction])
        
        let spawnPipesAction = SKAction.run(spawnPipes)
        let delayAction = SKAction.wait(forDuration: TimeInterval(2.5))
        let spawnThenDelayAction = SKAction.sequence([spawnPipesAction, delayAction])
        let repeatSpawnAction = SKAction.repeatForever(spawnThenDelayAction)
        self.continuousSpawnAction = repeatSpawnAction
        self.run(repeatSpawnAction)
        
        birdNode = SKSpriteNode(texture: birdTexture)
        birdNode.setScale(1.0)
        birdNode.position = CGPoint(x: self.frame.size.width * 0.4, y: self.frame.size.height * 0.6)
        
        birdNode.physicsBody = SKPhysicsBody(circleOfRadius: birdNode.size.height / 2.0)
        birdNode.physicsBody?.isDynamic = true
        birdNode.physicsBody?.allowsRotation = false
        
        birdNode.physicsBody?.categoryBitMask = birdCategory
        birdNode.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        birdNode.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(birdNode)
        
        let groundNode = SKNode()
        groundNode.position = CGPoint(x: 0, y: 0)
        groundNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: 1))
        groundNode.physicsBody?.isDynamic = false
        groundNode.physicsBody?.categoryBitMask = worldCategory
        self.addChild(groundNode)
        
        currentScore = 0
        scoreLabel = SKLabelNode(fontNamed: "Montserrat")
        scoreLabel.position = CGPoint(x: self.frame.midX, y: 3.5 * self.frame.size.height / 4)
        scoreLabel.zPosition = 100
        scoreLabel.text = String(currentScore)
        self.addChild(scoreLabel)
        
        self.isPaused = true
        sceneDelegate?.displayCounter()
    }
    
    @objc func createTrail() {
        let trailNode = SKSpriteNode(texture: SKTexture(imageNamed: "trail_circle"))
        trailNode.size = CGSize(width: 10, height: 10)
        trailNode.position = birdNode.position
        trailNode.zPosition = birdNode.zPosition - 0.1
        trailNode.alpha = 0.5
        
        let trailDistance = CGFloat(self.frame.size.width + 0.5 * explosionTexture.size().width)
        let moveTrailAction = SKAction.moveBy(x: -trailDistance, y: 0.0, duration: TimeInterval(0.01 * trailDistance))
        addChild(trailNode)
        
        trailNode.run(SKAction.fadeOut(withDuration: 1))
        trailNode.run(moveTrailAction)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            trailNode.removeFromParent()
        }
    }

    func spawnPipes() {
        let pipePairNode = SKNode()
        pipePairNode.position = CGPoint(x: self.frame.size.width + pipeUpTexture.size().width * 2, y: 0)
        pipePairNode.zPosition = -10
        
        let pipeHeight = UInt32(self.frame.size.height / 3)
        let pipeYPosition = Double(arc4random_uniform(pipeHeight))
        
        let pipeDownNode = SKSpriteNode(texture: pipeDownTexture)
        pipeDownNode.setScale(1.3)
        pipeDownNode.position = CGPoint(x: -300.0, y: pipeYPosition + Double(pipeDownNode.size.height) + gapBetweenPipes)
        
        pipeDownNode.physicsBody = SKPhysicsBody(rectangleOf: pipeDownNode.size)
        pipeDownNode.physicsBody?.isDynamic = false
        pipeDownNode.physicsBody?.categoryBitMask = pipeCategory
        pipeDownNode.physicsBody?.contactTestBitMask = birdCategory
        pipePairNode.addChild(pipeDownNode)
        
        let pipeUpNode = SKSpriteNode(texture: pipeUpTexture)
        pipeUpNode.setScale(1.3)
        pipeUpNode.position = CGPoint(x: -300.0, y: pipeYPosition)
        
        pipeUpNode.physicsBody = SKPhysicsBody(rectangleOf: pipeUpNode.size)
        pipeUpNode.physicsBody?.isDynamic = false
        pipeUpNode.physicsBody?.categoryBitMask = pipeCategory
        pipeUpNode.physicsBody?.contactTestBitMask = birdCategory
        pipePairNode.addChild(pipeUpNode)
        
        let scoreNode = SKNode()
        scoreNode.position = CGPoint(x: -300 + pipeDownNode.size.width + birdNode.size.width / 2, y: self.frame.midY)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeUpNode.size.width, height: self.frame.size.height))
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = scoreCategory
        scoreNode.physicsBody?.contactTestBitMask = birdCategory
        pipePairNode.addChild(scoreNode)
        
        pipePairNode.run(pipeMovementAction)
        pipesNode.addChild(pipePairNode)
    }
    
    func resetGameScene() {
        birdNode.texture = birdTexture
        birdNode.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        birdNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        birdNode.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        birdNode.speed = 1.0
        birdNode.zRotation = 0.0
        
        pipesNode.removeAllChildren()
        
        isRestartable = false
        
        currentScore = 0
        scoreLabel.text = String(currentScore)
        
        movingNode.speed = 1
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if movingNode.speed > 0 {
            for _ in touches {
                birdNode.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                birdNode.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
            }
        } else if isRestartable {
            resetGameScene()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        let rotationValue = birdNode.physicsBody!.velocity.dy * (birdNode.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001)
        birdNode.zRotation = min(max(-1, rotationValue), 0.5)
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if movingNode.speed > 0 {
            if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
                currentScore += 1
                scoreLabel.text = String(currentScore)
                scoreLabel.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: 0.1), SKAction.scale(to: 1.0, duration: 0.1)]))
            } else {
                movingNode.speed = 0
                birdNode.texture = explosionTexture
                birdNode.physicsBody?.collisionBitMask = worldCategory
                birdNode.run(SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(birdNode.position.y) * 0.01, duration: 1), completion: { self.birdNode.speed = 0 })
                
                UserDefaults.standard.set(currentScore, forKey: "lastResult")
                let bestScore = UserDefaults.standard.integer(forKey: "bestScore")
                if bestScore < currentScore {
                    UserDefaults.standard.set(currentScore, forKey: "bestScore")
                }
                
                let numberOfGames = UserDefaults.standard.integer(forKey: "numberOfGames") + 1
                UserDefaults.standard.set(numberOfGames, forKey: "numberOfGames")
                
                sceneDelegate?.gameEnded(score: currentScore)
                
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([
                    SKAction.repeat(SKAction.sequence([
                        SKAction.run({ self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0) }),
                        SKAction.wait(forDuration: 0.05),
                        SKAction.run({ self.backgroundColor = self.skyBackgroundColor }),
                        SKAction.wait(forDuration: 0.05)
                    ]), count: 4),
                    SKAction.run({ self.isRestartable = true })
                ]), withKey: "flash")
            }
        }
    }
    
    func endGame() {
        self.removeAllActions()
    }
}
