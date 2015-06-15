//
//  MainMenuScreen.swift
//  ZombieConga
//
//  Created by Andrew Perrault on 2015-06-15.
//  Copyright (c) 2015 Andrew Perrault. All rights reserved.
//

import Foundation
import SpriteKit

class MainMenuScene: SKScene {
    var inTransition = false
    
    override init(size: CGSize) {
       super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMoveToView(view: SKView) {
        var background = SKSpriteNode(imageNamed: "MainMenu")
        background.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(background)
        
    }
    
    #if os(iOS)
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        sceneTapped()
    }
    #else
    override func mouseDown(theEvent: NSEvent) {
        sceneTapped()
    }
    #endif
    
    func sceneTapped() {
        if !inTransition {
            inTransition = true
            var gameScene = GameScene(size: size)
            gameScene.scaleMode = scaleMode
            let reveal = SKTransition.doorwayWithDuration(1.5)
            view?.presentScene(gameScene, transition: reveal)
            
        }
    }
}
