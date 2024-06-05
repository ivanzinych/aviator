//
//  GameScene.swift
//  FlappyBird
//
//  Created by Nate Murray on 6/2/14.
//  Copyright (c) 2014 Fullstack.io. All rights reserved.
//

import SpriteKit

protocol GameSceneDelegate {
    func endGame(score: Int)
    func isScenePaused(_ value: Bool)
    func showCounter()
}

class GameScene: SKScene, SKPhysicsContactDelegate{
    let verticalPipeGap = 200.0
    
    var bird:SKSpriteNode!
    var skyColor:SKColor!
    var pipeTextureUp:SKTexture!
    var pipeTextureDown:SKTexture!
    var blowTexture: SKTexture!
    var birdTexture: SKTexture!
    var movePipesAndRemove:SKAction!
    var moving:SKNode!
    var pipes:SKNode!
    var canRestart = Bool()
    var scoreLabelNode:SKLabelNode!
    var score = NSInteger()
    
    let birdCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    var spawnThenDelayForever: SKAction?
    
    var viewDelegate: GameSceneDelegate?
    
    var timer: Timer?
    
    override var isPaused: Bool {
        didSet {
            
            viewDelegate?.isScenePaused(isPaused)
            
            if isPaused {
                timer?.invalidate()
                timer = nil
            } else {
                timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(addTrail), userInfo: nil, repeats: true)
            }
        }
    }

    override func didMove(to view: SKView) {
                        
        canRestart = true
        
        // setup physics
        self.physicsWorld.gravity = CGVector( dx: 0.0, dy: -5.0 )
        self.physicsWorld.contactDelegate = self
        
        // setup background color
        skyColor = SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.backgroundColor = skyColor
        
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        // ground
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest // shorter form for SKTextureFilteringMode.Nearest
        
        let moveGroundSprite = SKAction.moveBy(x: -groundTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.02 * groundTexture.size().width * 2.0))
        let resetGroundSprite = SKAction.moveBy(x: groundTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroundSprite,resetGroundSprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( groundTexture.size().width )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(1.0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveGroundSpritesForever)
//            moving.addChild(sprite)
        }
        
        // skyline
        let skyTexture = SKTexture(imageNamed: "space")
        skyTexture.filteringMode = .nearest
        
        let moveSkySprite = SKAction.moveBy(x: -skyTexture.size().width * 2.0, y: 0, duration: TimeInterval(0.1 * skyTexture.size().width * 2.0))
        let resetSkySprite = SKAction.moveBy(x: skyTexture.size().width * 2.0, y: 0, duration: 0.0)
        let moveSkySpritesForever = SKAction.repeatForever(SKAction.sequence([moveSkySprite,resetSkySprite]))
        
        for i in 0 ..< 2 + Int(self.frame.size.width / ( skyTexture.size().width * 2 )) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: skyTexture)
            sprite.setScale(1)
            sprite.zPosition = -20
            sprite.position = CGPoint(x: i * sprite.size.width, y: sprite.size.height / 2.0)
            sprite.run(moveSkySpritesForever)
            moving.addChild(sprite)
        }
        
        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        blowTexture = SKTexture(imageNamed: "explosion")
        blowTexture.filteringMode = .nearest
        birdTexture = SKTexture(imageNamed: "bird-01")
        birdTexture.filteringMode = .nearest
        // create the pipes movement actions
        let distanceToMove = CGFloat(self.frame.size.width + 0.5 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // spawn the pipes
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.5))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.spawnThenDelayForever = spawnThenDelayForever
        self.run(spawnThenDelayForever)
        
        // setup our bird
        
        bird = SKSpriteNode(texture: birdTexture)
        bird.setScale(1.0)
        bird.position = CGPoint(x: self.frame.size.width * 0.4, y:self.frame.size.height * 0.6)
        
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.addChild(bird)
        
        // create the ground
        let ground = SKNode()
        ground.position = CGPoint(x: 0, y: 0)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.size.width, height: 1))
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = worldCategory
        self.addChild(ground)
        
        // Initialize label and create a label which holds the score
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"MarkerFelt-Wide")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3.5 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        
        self.isPaused = true
        viewDelegate?.showCounter()
    }
    
   @objc func addTrail() {
       
       let trail = SKSpriteNode(texture: SKTexture(imageNamed: "trail_circle"))
       trail.size = .init(width: 10, height: 10)
       trail.position = bird.position
       trail.zPosition = bird.zPosition - 0.1
       trail.alpha = 0.5
       
       let distanceToMove = CGFloat(self.frame.size.width + 0.5 * blowTexture.size().width)
       let moveTrail = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
       addChild(trail)
       
//       trail.run(SKAction.scale(to: .zero, duration: 1))
       trail.run(SKAction.fadeOut(withDuration: 1))
       trail.run(moveTrail)

       DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
           trail.removeFromParent()
       }
    }

    func spawnPipes() {
        let pipePair = SKNode()
        pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
        pipePair.zPosition = -10
        
        let height = UInt32( self.frame.size.height / 3)
        let y = Double(arc4random_uniform(height))
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(1.3)
        pipeDown.position = CGPoint(x: -300.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
        
        
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(1.3)
        pipeUp.position = CGPoint(x: -300.0, y: y)
        
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint( x: -300 + pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = birdCategory
        pipePair.addChild(contactNode)
        
        pipePair.run(movePipesAndRemove)
        pipes.addChild(pipePair)
        
    }
    
    func resetScene() {
        // Move bird to original position and reset velocity
        bird.texture = birdTexture
        bird.position = CGPoint(x: self.frame.size.width / 2.5, y: self.frame.midY)
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0 )
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        
        // Reset score
        score = 0
        scoreLabelNode.text = String(score)
        
        // Restart animation
        moving.speed = 1
        
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if moving.speed > 0  {
            for _ in touches { // do we need all touches?
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 20))
            }
        } else if canRestart {
            self.resetScene()
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        /* Called before each frame is rendered */
        let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
        bird.zRotation = min( max(-1, value), 0.5 )
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if moving.speed > 0 {
            
            if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                // Bird has contact with score entity
                score += 1
                scoreLabelNode.text = String(score)
                
                // Add a little visual feedback for the score increment
                scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
            } else {
                                
                moving.speed = 0
                
                bird.texture = blowTexture
                
                bird.physicsBody?.collisionBitMask = worldCategory
                bird.run(SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
                
                UserDefaults.standard.set(Int(score), forKey: "lastResult")
                if let bestScore = UserDefaults.standard.value(forKey: "bestScore") as? Int {
                    if bestScore < Int(score) {
                        UserDefaults.standard.set(Int(score), forKey: "bestScore")
                    }
                } else {
                    UserDefaults.standard.set(Int(score), forKey: "bestScore")
                }
                
                if let numberOfGames = UserDefaults.standard.value(forKey: "numberOfGames") as? Int {
                        UserDefaults.standard.set(numberOfGames + 1, forKey: "numberOfGames")
                } else {
                    UserDefaults.standard.set(1, forKey: "numberOfGames")
                }
                
                viewDelegate?.endGame(score: Int(score))
                
                
                // Flash background if contact is detected
                self.removeAction(forKey: "flash")
                self.run(SKAction.sequence([SKAction.repeat(SKAction.sequence([SKAction.run({
                    self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                    }),SKAction.wait(forDuration: TimeInterval(0.05)), SKAction.run({
                        self.backgroundColor = self.skyColor
                        }), SKAction.wait(forDuration: TimeInterval(0.05))]), count:4), SKAction.run({
                            self.canRestart = true
                            })]), withKey: "flash")
            }
        }
    }
    
    func finishGame() {
        self.removeAllActions()
    }
}
