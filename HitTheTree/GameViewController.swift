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
    
    //MARK: - Scene properties
    var sceneView: SCNView!
    var scene: SCNScene!
    
    override func viewDidLoad() {
        setupScene()
    }
    
    func setupScene() {
        //get the view
        sceneView = self.view as? SCNView
        sceneView.allowsCameraControl = true //since we didn't allow any logic for camera control, this allows us to do it manually
        scene = SCNScene(named: "art.scnassets/MainScene.scn")
        sceneView.scene = scene
        
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
