//
//  ArcadeGameMain.swift
//  MiniGames Ultra
//
//  Created by Roman Nikitin on 21.04.15.
//  Copyright (c) 2015 TheUnbelievable. All rights reserved.
//

import Foundation
import SpriteKit

class MonsterNode : SKSpriteNode {
    init (imageNamed : String, lives : Int, damage : Int) {
        let texture = SKTexture(imageNamed: imageNamed)
        super.init(texture: texture, color: nil, size: texture.size())
        self.lives = lives
        self.damage = damage
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var lives = 0
    lazy var damage = 0
}

class Shuriken : SKSpriteNode {
    init (imageNamed : String, damag : Int) {
        let texture = SKTexture(imageNamed: imageNamed)
        super.init(texture: texture, color: nil, size: texture.size())
        self.damage = damag
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    lazy var damage = 0
}

class ArcadeGameScene: SKScene, SKPhysicsContactDelegate {
    
    struct Detection {
        static var no : UInt32 = 0
        static var all : UInt32 = UInt32.max
        static var monster : UInt32 = 1 << 1
        static var suric : UInt32 = 1 << 2
        static var ninja : UInt32 = 1 << 3
        static var world : UInt32 = 1 << 4
        static var field : UInt32 = 1 << 5
    }
    
    let player = SKSpriteNode(imageNamed: "ninja.png")
    let lifeLabel = SKLabelNode(fontNamed: "Helvetica")
    let stageLabel = SKLabelNode(fontNamed: "Helvetica")
    
    var lives = 0
    var storage = NSUserDefaults.standardUserDefaults()
    var stage = 0
    var nOfMon = 0
    var t : CGFloat = 0.0
    var finish = false
    
    override init(size: CGSize) {
        super.init(size: size)
        self.size = size
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        
        backgroundColor = SKColor.lightGrayColor()
        lives = storage.integerForKey("ninjaLives")
        storage.setInteger(storage.integerForKey("stage") + 1, forKey: "stage")
        stage = storage.integerForKey("stage")
        if stage % 5 == 0 {
            lives += 50
            storage.setInteger(lives, forKey: "ninjaLives")
        }
        storage.synchronize()
        
        let field = SKFieldNode.turbulenceFieldWithSmoothness(10, animationSpeed: 1)
        field.position = CGPoint(x: self.size.width * 0.55, y: size.height / 2)
        field.physicsBody = SKPhysicsBody(rectangleOfSize: CGSize(width: size.width * 0.45, height: size.height))
        field.physicsBody?.categoryBitMask = Detection.field
        field.strength = 2
        addChild(field)
        
        physicsWorld.gravity = CGVectorMake(0.0, -10)
        physicsWorld.contactDelegate = self
        
        player.position = CGPoint(x: self.size.width * 0.1, y: self.size.height / 2)
        player.physicsBody = SKPhysicsBody(rectangleOfSize: player.size)
        player.physicsBody?.dynamic = false
        player.physicsBody?.categoryBitMask = Detection.ninja
        player.physicsBody?.collisionBitMask = Detection.no
        player.physicsBody?.contactTestBitMask = Detection.monster
        player.physicsBody?.fieldBitMask = Detection.no
        player.setScale(0.25)
        addChild(player)
        
        lifeLabel.position = CGPoint(x: self.size.width / 2 + 100, y: self.size.width * 0.05)
        lifeLabel.fontColor = SKColor.blackColor()
        lifeLabel.fontSize = 15
        lifeLabel.text = "lives: \(lives)"
        addChild(lifeLabel)
        
        stageLabel.position = CGPoint(x: self.size.width / 2 - 100, y: self.size.width * 0.05)
        stageLabel.fontSize = 15
        stageLabel.fontColor = SKColor.blackColor()
        stageLabel.text = "stage: \(stage)"
        addChild(stageLabel)
        
        physicsBody = SKPhysicsBody(edgeLoopFromRect: CGRect(x: -500, y: size.height * 0.04 + 20, width: size.width + 1000, height: size.height - (size.height * 0.04 + 20)))
        physicsBody?.categoryBitMask = Detection.world
        physicsBody?.collisionBitMask = Detection.monster
        
        let win = SKAction.runBlock() {
            self.view?.presentScene(GameOverScene(size: size, won: true, stage: stage))
        }
        
        let dur : CGFloat
        
        switch stage {
        case 1...3:
            dur = random(min: 2.0, 2.5)
        case 4...7:
            dur = random(min: 1.5, 2.0)
        case 7...11:
            dur = random(min: 1, 1.5)
        case 11...17:
            dur = random(min: 0.5, 1)
        default:
            dur = random(min: 0.5, 0.7)
        }
        
        let action = SKAction.repeatAction(SKAction.sequence([SKAction.runBlock(createMonster), SKAction.waitForDuration(NSTimeInterval(dur))]), count: 10 + stage * 5)
        runAction(SKAction.sequence([action, SKAction.runBlock() {
            self.finish = true
            }]))
    }
    
    override func mouseDown(theEvent: NSEvent) {
        let location = theEvent.locationInNode(self)
        var s = ""
        var damage : Int = 100
        var r = arc4random_uniform(4)
        switch r {
        case 0:
            s = "starBlack.png"
        case 1:
            s = "starCyclone.png"
            damage = 150
        case 2:
            s = "starDragon.png"
            damage = 150
        default:
            s = "ninjaStar.png"
        }
        
        let suric = Shuriken(imageNamed: s, damag: damage)
        suric.position = player.position
        suric.physicsBody = SKPhysicsBody(circleOfRadius: suric.size.width / 2)
        suric.physicsBody?.categoryBitMask = Detection.suric
        suric.physicsBody?.collisionBitMask = Detection.no
        suric.physicsBody?.contactTestBitMask = Detection.monster
        suric.physicsBody?.usesPreciseCollisionDetection = true
        suric.physicsBody?.dynamic = true
        suric.physicsBody?.angularVelocity = -10.0
        suric.physicsBody?.mass = 2.5 + CGFloat(abs(suric.size.width - 30) * 0.05)
        suric.physicsBody?.fieldBitMask = Detection.no
        let offset = location - suric.position
        addChild(suric)
        
        let direc = offset.normalized()
        
        suric.physicsBody?.applyImpulse(CGVector(dx: offset.x * 10, dy: offset.y * 10))
    }
    
    func suricHit(monster : MonsterNode?, suric : Shuriken?) {
        if suric != nil && monster != nil {
            monster!.lives -= suric!.damage
            suric?.removeFromParent()
            if monster!.lives <= 0 {
                destroyMonster(monster!.position, monster: monster!)
                monster?.removeFromParent()
                nOfMon--
            }
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var first : SKPhysicsBody
        var second : SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            first = contact.bodyA
            second = contact.bodyB
        }
        else {
            first = contact.bodyB
            second = contact.bodyA
        }
        
        if ((first.categoryBitMask == 2) && (second.categoryBitMask == 4)) {
            suricHit(first.node as? MonsterNode, suric: second.node as? Shuriken)
        }
        else if second.categoryBitMask == 8 && first.categoryBitMask == 2 {
            nOfMon--
            if let monster = first.node as? MonsterNode {
                lose(monster.damage * 2)
            }
            first.node?.removeFromParent()
            detonate(contact.contactPoint)
        }
    }
    
    func detonate(pos : CGPoint) {
        let explosion = SKEmitterNode(fileNamed: "ExplosionParticle.sks")
        explosion.particlePosition = pos
        addChild(explosion)
        runAction(SKAction.waitForDuration(1.0), completion: {
            explosion.removeFromParent()
        })
    }
    
    func destroyMonster(pos : CGPoint, monster : MonsterNode) {
        let effect = SKEmitterNode(fileNamed: "MonsterDestroy.sks")
        effect.particlePositionRange = CGVector(dx: monster.size.width, dy: monster.size.height)
        effect.particlePosition = pos
        addChild(effect)
        runAction(SKAction.waitForDuration(12.0), completion: {effect.removeFromParent()})
    }
    
    func createMonster() {
        var n = arc4random_uniform(100)
        var s = ""
        var scale : CGFloat
        var l : Int
        var mass : CGFloat
        switch stage {
        case 1...4:
            t = 600
        case 5...18:
            t = 650
        case 9...13:
            t = 700
        case 14...17:
            t = 950
        case 17...21:
            t = 900
        default:
            t = 1000
        }
        switch n {
        case 0...59:
            mass = 20
            s = "GhostSmall.png"
            scale = 0.3
            l = 100
        case 60...85:
            mass = 60
            s = "GhostMedium.png"
            scale = 0.19
            l = 150
        default:
            mass = 30
            s = "GhostBig.png"
            scale = 0.30
            l = 300
        }
        
        let monster = MonsterNode(imageNamed: s, lives : l, damage: l / 2)
        monster.setScale(scale)
        let y = random(min: monster.size.height / 2 + size.height * 0.04 + 25, size.height - monster.size.height)
        monster.position = CGPoint(x: self.size.width + monster.size.width / 2, y: y)
        monster.physicsBody = SKPhysicsBody(texture: SKTexture(imageNamed: s), alphaThreshold: 0.1, size: monster.size)
        monster.physicsBody?.usesPreciseCollisionDetection = true
        monster.physicsBody?.categoryBitMask = Detection.monster
        monster.physicsBody?.contactTestBitMask = Detection.suric | Detection.world
        monster.physicsBody?.collisionBitMask = Detection.world
        monster.physicsBody?.fieldBitMask = Detection.field
        monster.physicsBody?.affectedByGravity = false
        monster.physicsBody?.dynamic = true
        monster.physicsBody?.allowsRotation = false
        monster.physicsBody?.mass = mass
        addChild(monster)
        
        monster.physicsBody?.applyImpulse(CGVectorMake(-t, 0))
        nOfMon++
    }
    
    func lose(n : Int) {
        lives -= n
        storage.setInteger(lives, forKey: "ninjaLives")
        if lives <= 0 {
            runAction(SKAction.sequence([SKAction.waitForDuration(1.0), SKAction.runBlock() {
                self.storage.setInteger(0, forKey: "stage")
                self.view?.presentScene(GameOverScene(size: self.size, won: false, stage: self.stage), transition: SKTransition.flipHorizontalWithDuration(0.5))
                }]))
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if finish {
            runAction(SKAction.sequence([SKAction.waitForDuration(2.0), SKAction.runBlock() {
                self.storage.setInteger(self.lives, forKey: "ninjaLives")
                self.storage.synchronize()
                self.view?.presentScene(GameOverScene(size: self.size, won: true, stage: self.stage))
                }]))
        }
        if lives < 0 {
            lives = 0
        }
        lifeLabel.text = "lives: \(lives)"
        for node in self.children {
            if let monster = node as? MonsterNode {
                if monster.position.x < monster.size.width / 2 {
                    detonate(monster.position)
                    nOfMon--
                    lose(monster.damage)
                    monster.removeFromParent()
                }
                else if monster.physicsBody?.velocity.dx >= 0 {
                    monster.physicsBody?.applyImpulse(CGVector(dx: -t, dy: monster.position.y))
                }
            }
        }
    }
}