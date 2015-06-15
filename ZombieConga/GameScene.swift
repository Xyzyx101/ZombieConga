//
//  GameScene.swift
//  ZombieConga
//
//  Created by Andrew Perrault on 2015-06-04.
//  Copyright (c) 2015 Andrew Perrault. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene {
    var zombie:SKSpriteNode!
    var lastUpdateTime: NSTimeInterval = 0
    var dt: NSTimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0
    let zombieRotateRadiansPerSec:CGFloat = 2.5 * π
    var velocity = CGPointZero
    let playableRect: CGRect
    var lastTouchLocation:CGPoint!
    let zombieAnimation: SKAction
    let catCollisionSound = SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound = SKAction.playSoundFileNamed("hitCatLady.wav", waitForCompletion: false)
    var zombieInvincible = false
    let catMovePointsPerSec = 480.0
    var lives = 5
    var gameOver = false
    var trainCount = 0
    let backgroundMovePointsPerSec: CGFloat = 200.0
    let backgroundLayer = SKNode()
    
    override init(size: CGSize) {
        let maxAspectRatio: CGFloat = 16.0/9.0
        let playableHeight = size.width / maxAspectRatio
        let playableMargin = (size.height-playableHeight) / 2.0
        playableRect = CGRect(x:0, y:playableMargin, width: size.width, height: playableHeight)
        
        var textures:[SKTexture] = []
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        textures.append(textures[2])
        textures.append(textures[1])
        zombieAnimation = SKAction.animateWithTextures(textures, timePerFrame: 0.1)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        backgroundLayer.zPosition = -1
        addChild(backgroundLayer)
        backgroundColor = SKColor.whiteColor()
        for i in 0...1 {
            let background = backgroundNode()
            background.anchorPoint = CGPointZero
            background.position = CGPoint(x: CGFloat(i)*background.size.width, y:0)
            background.zPosition = -1
            backgroundLayer.addChild(background)
        }
        zombie = SKSpriteNode(imageNamed: "zombie1")
        zombie.position = CGPoint(x: 400, y: 400)
        zombie.zPosition = 100
        backgroundLayer.addChild(zombie)
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnEnemy),SKAction.waitForDuration(2.0)])))
        runAction(SKAction.repeatActionForever(SKAction.sequence([SKAction.runBlock(spawnCat), SKAction.waitForDuration(1.0)])))
        playBackgroundMusic("backgroundMusic.mp3")
    }
   
    func backgroundNode() -> SKSpriteNode {
        // 1
        let backgroundNode = SKSpriteNode()
        backgroundNode.anchorPoint = CGPointZero
        backgroundNode.name = "background"
        // 2
        let background1 = SKSpriteNode(imageNamed: "background1")
        background1.anchorPoint = CGPointZero
        background1.position = CGPoint(x: 0, y: 0)
        backgroundNode.addChild(background1)
        // 3
        let background2 = SKSpriteNode(imageNamed: "background2")
        background2.anchorPoint = CGPointZero
        background2.position =
            CGPoint(x: background1.size.width, y: 0)
        backgroundNode.addChild(background2)
        // 4
        backgroundNode.size = CGSize(
            width: background1.size.width + background2.size.width,
            height: background1.size.height)
        return backgroundNode
    }

    override func update(currentTime: NSTimeInterval) {
        if lastUpdateTime > 0 {
            dt = currentTime - lastUpdateTime
        } else {
            dt = 0
        }
        lastUpdateTime = currentTime
        moveSprite(zombie, velocity: velocity)
        boundsCheckZombie()
        rotateSprite(zombie,direction: velocity, rotationRadiansPerSec: zombieRotateRadiansPerSec)
        moveTrain()
        moveBackground()
        
        if lives <= 0 && !gameOver {
            gameOver = true
            println("You lose!")
            endLevel(GameOverScene(size: size, won:false))
            
        } else if trainCount >= 30 && !gameOver {
            gameOver = true
            println("You win!")
            endLevel(GameOverScene(size: size, won:true))
        }
    }
    
    func moveBackground() {
        let backgroundVelocity = CGPoint(x: -self.backgroundMovePointsPerSec, y:0)
        let amountToMove = backgroundVelocity * CGFloat(self.dt)
        backgroundLayer.position += amountToMove
        
        backgroundLayer.enumerateChildNodesWithName("background") { node, _ in
            let background = node as! SKSpriteNode
            let backgroundScreenPos = self.backgroundLayer.convertPoint(background.position, toNode: self)
            if backgroundScreenPos.x <= -background.size.width {
                background.position = CGPoint(
                    x: background.position.x + background.size.width * 2,
                    y: background.position.y
                )
            }
        }
    }
    func endLevel(newScene: SKScene) {
        newScene.scaleMode = scaleMode
        let reveal = SKTransition.flipHorizontalWithDuration(0.5)
        view?.presentScene(newScene, transition: reveal)
    }
    
    override func didEvaluateActions() {
        checkCollisions()
    }
    func moveSprite(sprite: SKSpriteNode, velocity: CGPoint) {
        let amountToMove = velocity * CGFloat(dt)
        sprite.position += amountToMove
    }
    
    func moveZombieToward(location: CGPoint) {
        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
        startZombieAnimation()
    }
    
    func sceneTouched(touchLocation: CGPoint) {
        lastTouchLocation = touchLocation
        moveZombieToward(touchLocation)
    }
    
    #if os(iOS)
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
    let touch = touches.first as! UITouch
    let touchLocation = touch.locationInNode(backgroundLayer)
    sceneTouched(touchLocation)
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
    let touch = touches.first as! UITouch
    let touchLocation = touch.locationInNode(backgroundLayer)
    sceneTouched(touchLocation)
    }
    #else
    override func mouseDown(theEvent: NSEvent) {
        let touchLocation = theEvent.locationInNode(backgroundLayer)
        sceneTouched(touchLocation)
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let touchLocation = theEvent.locationInNode(backgroundLayer)
        sceneTouched(touchLocation)
    }
    #endif
    
    func boundsCheckZombie() {
        let bottomLeft = backgroundLayer.convertPoint(CGPoint(x: 0, y: CGRectGetMinY(playableRect)), fromNode: self)
        let topRight = backgroundLayer.convertPoint(CGPoint(x: size.width, y: CGRectGetMaxY(playableRect)), fromNode: self)
        
        if zombie.position.x <= bottomLeft.x {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        } 
    }
    
    func debugDrawPlayableArea() {
        let shape = SKShapeNode()
        let path = CGPathCreateMutable()
        CGPathAddRect(path, nil, playableRect)
        shape.path = path
        shape.strokeColor = SKColor.redColor()
        shape.lineWidth = 4.0
        addChild(shape)
    }
    
    func rotateSprite(sprite: SKSpriteNode, direction: CGPoint, rotationRadiansPerSec: CGFloat) {
        let targetAngle = CGFloat(atan2(Double(direction.y), Double(direction.x)))
        let shortest = shortestAngleBetween(zombie.zRotation, targetAngle)
        let amtToRotate = rotationRadiansPerSec * CGFloat(dt)
        if abs(shortest) < amtToRotate {
            zombie.zRotation = targetAngle
        } else {
            zombie.zRotation = zombie.zRotation + amtToRotate * shortest.sign()
        }
    }
    
    func spawnEnemy() {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.name = "enemy"
        var enemyScenePos = CGPoint(
            x: size.width + enemy.size.width/2,
            y: CGFloat.random(
                min: CGRectGetMinY(playableRect) + enemy.size.height/2,
                max: CGRectGetMaxY(playableRect) - enemy.size.height/2))
        enemy.position = backgroundLayer.convertPoint(enemyScenePos, fromNode: self)
        backgroundLayer.addChild(enemy)
        let sceneTargetPos = CGPoint(x: -enemy.size.width/2, y: enemyScenePos.y)
        let targetPos = backgroundLayer.convertPoint(sceneTargetPos, fromNode: self)
        let actionMove = SKAction.moveTo(targetPos, duration: 2.0)
        let actionRemove = SKAction.removeFromParent()
        enemy.runAction(SKAction.sequence([actionMove, actionRemove]))
    }
    
    func startZombieAnimation() {
        if zombie.actionForKey("animation") == nil {
            zombie.runAction(
                SKAction.repeatActionForever(zombieAnimation),
                withKey: "animation")
        }
    }
    
    func stopZombieAnimation() {
        zombie.removeActionForKey("animation")
    }

    func spawnCat() {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.name = "cat"
        let catScenePos = CGPoint(
            x: CGFloat.random(min: CGRectGetMinX(playableRect),
                max: CGRectGetMaxX(playableRect)),
            y: CGFloat.random(min: CGRectGetMinY(playableRect),
                max: CGRectGetMaxY(playableRect)))
        cat.setScale(0)
        cat.position = backgroundLayer.convertPoint(catScenePos, fromNode: self)
        backgroundLayer.addChild(cat)
        let appear = SKAction.scaleTo(1.0, duration: 0.5)
        
        cat.zRotation = -π / 16.0
        let leftWiggle = SKAction.rotateByAngle(π/8.0, duration: 0.5)
        let rightWiggle = leftWiggle.reversedAction()
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle])
        let scaleUp = SKAction.scaleBy(1.2, duration: 0.25)
        let scaleDown = scaleUp.reversedAction()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeatAction(group, count: 10)
        
        let disappear = SKAction.scaleTo(0, duration: 0.5)
        let removeFromParent = SKAction.removeFromParent()
        let actions = [appear, groupWait, disappear, removeFromParent]
        cat.runAction(SKAction.sequence(actions))
    }
    
    func zombieHitCat(cat: SKSpriteNode) {
        cat.name = "train"
        runAction(catCollisionSound)
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.runAction(SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 0.6, duration: 0.8))
    }
    
    func zombieHitEnemy(enemy: SKSpriteNode) {
        makeZombieInvincible()
        runAction(enemyCollisionSound)
        loseCats()
        lives--
    }
    
    func checkCollisions() {
        var hitCats: [SKSpriteNode] = []
        backgroundLayer.enumerateChildNodesWithName("cat") { node, _ in
            let cat = node as! SKSpriteNode
            if CGRectIntersectsRect(cat.frame, self.zombie.frame) {
                hitCats.append(cat)
            }
        }
        self.trainCount += hitCats.count
        for cat in hitCats {
            zombieHitCat(cat)
        }
        
        if zombieInvincible {
            return
        }
        
        var hitEnemies: [SKSpriteNode] = []
        backgroundLayer.enumerateChildNodesWithName("enemy") { node, _ in
            let enemy = node as! SKSpriteNode
            if CGRectIntersectsRect(CGRectInset(node.frame, 40, 40), self.zombie.frame) {
                hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies {
            zombieHitEnemy(enemy)
        }
    }
    
    func makeZombieInvincible() {
        zombieInvincible = true
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customActionWithDuration(duration) {
            node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime) % slice
            node.hidden = remainder > slice / 2
        }
        let stopBlink = SKAction.runBlock() {
            self.zombieInvincible = false
        }
        zombie.runAction(SKAction.sequence([blinkAction, stopBlink]))
    }
    
    func moveTrain() {
        var targetPosition = zombie.position
        backgroundLayer.enumerateChildNodesWithName("train") {
            node, _ in
            if !node.hasActions() {
                let actionDuration = CGFloat(0.3)
                let offset = targetPosition - node.position
                let direction = offset.normalized()
                let amountToMovePerSec = direction * CGFloat(self.catMovePointsPerSec)
                let amountToMove = amountToMovePerSec * actionDuration
                let moveAction = SKAction.moveBy(CGVector(dx: amountToMove.x, dy: amountToMove.y), duration: 0.3)
                let angle = CGFloat(atan2(Double(direction.y), Double(direction.x)))
                let rotateAction = SKAction.rotateToAngle(angle, duration: 0.3, shortestUnitArc: true)
                node.runAction(SKAction.group([moveAction, rotateAction]))
                targetPosition = node.position
            }
        }
    }
    
    func loseCats() {
        var loseCount = 0
        backgroundLayer.enumerateChildNodesWithName("train") { node, stop in
                var randomSpot = node.position
            randomSpot.x += CGFloat.random(min: -500, max: 500)
            randomSpot.y += CGFloat.random(min:-500, max:500)
            node.name = ""
            node.zPosition = 100
            let flyAction = SKAction.sequence([
                SKAction.scaleTo(3, duration: 0.15),
                SKAction.scaleTo(0, duration: 1)
                ])
            
            flyAction.timingMode = .EaseOut
            node.runAction(
                SKAction.sequence(
                    [SKAction.group([
                        SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false),
                        SKAction.rotateToAngle(π*4, duration: 2.0),
                        SKAction.moveTo(randomSpot, duration: 2.0),
                        SKAction.colorizeWithColor(SKColor.greenColor(), colorBlendFactor: 0.0, duration: 1),
                        flyAction
                    ]),
                    SKAction.removeFromParent()
                ])
            )
            loseCount++
            if loseCount >= 2 {
                self.trainCount -= 2
                stop.memory = true
            }
        }
    }
    
    
}
