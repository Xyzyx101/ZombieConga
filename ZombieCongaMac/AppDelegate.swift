//
//  AppDelegate.swift
//  ZombieCongaMac
//
//  Created by Andrew Perrault on 2015-06-15.
//  Copyright (c) 2015 Andrew Perrault. All rights reserved.
//


import Cocoa
import SpriteKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow?
    @IBOutlet weak var skView: SKView?
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let scene = MainMenuScene(size: CGSize(width: 2048, height: 1536))
        scene.scaleMode = .AspectFit
        self.skView!.presentScene(scene)
        self.skView!.ignoresSiblingOrder = true
        self.skView!.showsFPS = true
        self.skView!.showsNodeCount = true
    }

    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }
}
