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
    
    let CategoryTree = 2
    
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
        sceneView.delegate = self
        
        // sceneView.allowsCameraControl = true
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        sceneView.scene = scene
        
        scene.physicsWorld.contactDelegate = self
        
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
        ballNode.physicsBody?.contactTestBitMask = CategoryTree
        
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


extension GameViewController: SCNSceneRendererDelegate {
    // called every frame
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        //MARK:- Camera positioning method
        
        // get the ball position as it currently appears on scene during the frame
        let ball = ballNode.presentation
        let ballPosition = ball.position
        
        // target position for the camera to have - move from initial position to target
        let targetPosition = SCNVector3(ballPosition.x, ballPosition.y + 5, ballPosition.z + 5)
        var cameraPosition = selfieStickNode.position
        
        // we're using damping to more smoothly move the camera between points
        let camDamping: Float = 0.3
        let xComponent = cameraPosition.x * (1 - camDamping) + targetPosition.x * camDamping
        let yComponent = cameraPosition.y * (1 - camDamping) + targetPosition.y * camDamping
        let zComponent = cameraPosition.z * (1 - camDamping) + targetPosition.z * camDamping
        
        cameraPosition = SCNVector3(xComponent, yComponent, zComponent)
        selfieStickNode.position = cameraPosition
        
        //MARK:- Motion event handling
        motion.getAccelerometerData { (x, y, z) in
            // uses helper function to creation this motionforce. It'll be used to change the direction of the ballNode, proportionally.
            self.motionForce = SCNVector3(x * 0.05, 0, (y + 0.8) * -0.05)
        }
        
        ballNode.physicsBody?.velocity += motionForce
        
        //MARK:- Collision detection
        // what happens when the ball hits the tree?
        // 2 for contact bitmaask so that we're notified of contact between the two objects
        
    }

}

extension GameViewController : SCNPhysicsContactDelegate {
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        //notifies us each time a contact is established
        var contactNode: SCNNode!
        
        // if the first node is ball, node B must be the tree. Else, node A must the tree.
        if contact.nodeA.name == "ball" {
            contactNode = contact.nodeB
        } else {
            contactNode = contact.nodeA
        }
        
        if contactNode.physicsBody?.categoryBitMask == CategoryTree {
            // play sound, remove it and show it again after period of time
            contactNode.isHidden = true
            let sawSound = sounds["saw"]!
            ballNode.runAction(SCNAction.playAudio(sawSound, waitForCompletion: false))
            
            let waitAction = SCNAction.wait(duration: 15)
            let unhideAction = SCNAction.run { (node) in
                node.isHidden = false
            }
            
            let actionSequence = SCNAction.sequence([waitAction, unhideAction])
            contactNode.runAction(actionSequence)
        }
    }
}
