//
//  GameViewController.swift
//  HitTheTree
//
//  Created by Brian Advent on 26.04.18.
//  Copyright © 2018 Brian Advent. All rights reserved.
//

import UIKit
import SceneKit

class GameViewController: UIViewController {
    
    //MARK:- Scene properties
    var sceneView: SCNView!
    var scene: SCNScene!
    
    var ballNode: SCNNode!
    var selfieStickNode: SCNNode! // help to control the following camera
    
    var motion = MotionHelper()
    var motionForce = SCNVector3(0, 0, 0) // force has direction and strength
    
    var sounds: [String:SCNAudioSource] = [:]
    
    override func viewDidLoad() {
        setupScene()
        setupNodes()
        setupSounds()
    }
    
    func setupScene() {
        // get the view
        sceneView = self.view as? SCNView
        sceneView.allowsCameraControl = true //since we didn't allow any logic for camera control, this allows us to do it manually
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        sceneView.scene = scene
        
        // create tap recgonizer
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.numberOfTouchesRequired = 1
        tapRecognizer.numberOfTapsRequired = 1
        
        tapRecognizer.addTarget(self, action: #selector(sceneViewTapped(recognizer:)))
        sceneView.addGestureRecognizer(tapRecognizer)
        
    }
    
    //MARK:- Node setup
    func setupNodes() {
        // because recursive is true, it'll look through the file path tree to find our node
        ballNode = scene.rootNode.childNode(withName: "ball", recursively: true)!
        
        selfieStickNode = scene.rootNode.childNode(withName: "selfieStick", recursively: true)!
    }
    
    func setupSounds() {
        // load the sound files, adjust volume and prepare for usage
        guard let sawSound = SCNAudioSource(fileNamed: "chainsaw.wav") else { return }
        guard let jumpSound = SCNAudioSource(fileNamed: "jump.wav") else { return }
        
        sawSound.load()
        jumpSound.load()
        
        sawSound.volume = 0.3
        jumpSound.volume = 0.4
        
        // add them to our sounds dictionary
        sounds["saw"] = sawSound
        sounds["jump"] = jumpSound
        
        // background music setup
        guard let backgroundMusic = SCNAudioSource(fileNamed: "background.mp3") else { return }
        backgroundMusic.volume = 0.1
        backgroundMusic.loops = true
        backgroundMusic.load()
        
        // play the music with the SCNAudioPlayer and add it to our ball node to begin playback
        let musicPlayer = SCNAudioPlayer(source: backgroundMusic)
        ballNode.addAudioPlayer(musicPlayer)
    }
    
    //MARK:- Tap gesture recognizer
    @objc func sceneViewTapped(recognizer: UITapGestureRecognizer) {
        // 1. Grab the touch point's location
        let location = recognizer.location(in: sceneView)
        
        // 2. Locate the 2D points in the scene
        let hitResults = sceneView.hitTest(location, options: nil)
        
        if hitResults.count > 0 {
            let result = hitResults.first
            
            // if there's a node at the touch point, check if it's the ball. If it's the ball, play the jump sound and perform the jump by applying a physics impulse force.
            if let node = result?.node {
                if node.name == "ball" {
                    let jumpSound = sounds["jump"]!
                    ballNode.runAction(SCNAction.playAudio(jumpSound, waitForCompletion: false))
                    // asImpulse = apply the force once
                    ballNode.physicsBody?.applyForce(SCNVector3(0, 4, -2), asImpulse: true)
                }
            }
        }
    }
    
    override var shouldAutorotate: Bool {
        // portrait only
        return false
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
