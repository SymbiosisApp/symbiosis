//
//  GameViewController.swift
//  POC-SceneKit
//
//  Created by Etienne De Ladonchamps on 15/02/2016.
//  Copyright (c) 2016 Etienne De Ladonchamps. All rights reserved.
//

import UIKit
import SceneKit

class PlantSceneViewController: UIViewController, SCNSceneRendererDelegate {
    
    var animProgress: Float = 0
    var morpher: SCNMorpher?
    var scnView: SCNView?
    var lastUpdateTimeInterval: NSTimeInterval = 0
    var currentCameraRotationVert: Float = 0
    var currentCameraRotationHor: Float = 0
    let rotationNode = SCNNode()
    
    // State
    let state = SYStateManager.sharedInstance
    
    var plant: SYPlant!
    var annimProgress: Float = 0
    var plantProps: [SYElementRootProps] = [
        SYElementRootProps(size: 0, hasLeefs: false, nbrOfFlower: 0, nbrOfFruits: 0, nbrOfSeed: 0),
        SYElementRootProps(size: 1, hasLeefs: true, nbrOfFlower: 0, nbrOfFruits: 0, nbrOfSeed: 0),
        SYElementRootProps(size: 4, hasLeefs: true, nbrOfFlower: 1, nbrOfFruits: 0, nbrOfSeed: 0),
        SYElementRootProps(size: 6, hasLeefs: true, nbrOfFlower: 0, nbrOfFruits: 1, nbrOfSeed: 0),
        SYElementRootProps(size: 6, hasLeefs: true, nbrOfFlower: 0, nbrOfFruits: 0, nbrOfSeed: 1)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen to events
        state.listenTo(.Update, action: self.onStateUpdate)

        // retrieve the SCNView
        let scnView = self.view as! SCNView
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        scnView.backgroundColor = UIColor(red: 0.8, green: 0.9, blue: 0.98, alpha: 1)
        scnView.delegate = self
        
        // create a new scene
        let scene = SCNScene()
        // set the scene to the view
        scnView.scene = scene
        
//        let startTime = CFAbsoluteTimeGetCurrent()

//        let plant = SYElementBranch()
//        scene.rootNode.addChildNode(plant)
//        
//        // Async task
//        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
//        dispatch_async(dispatch_get_global_queue(priority, 0)) {
//            plant.render(1.6)
//        }

        self.plant = SYPlant(states: self.plantProps)
        scene.rootNode.addChildNode(plant)
        plant.render(0)
        
        
//        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        // print("Render time : \(timeElapsed)")

        let cameraTarget = SCNNode()
        cameraTarget.position = SCNVector3Make(0, 0.5, 0)
        scene.rootNode.addChildNode(cameraTarget)
        
        // Create the camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.xFov = 30.0
        cameraNode.position = SCNVector3Make(0, 0.5, 2)
        // add rotationNode
        rotationNode.addChildNode(cameraNode)
        rotationNode.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(rotationNode)

        // Front light
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = SCNLightTypeOmni
        lightNode.position = SCNVector3Make(0, 1.5, 6)
        rotationNode.addChildNode(lightNode)
        lightNode.geometry = SCNSphere(radius: 0.1)
        
//        // create and add a light to the scene
//        let lightNode2 = SCNNode()
//        lightNode2.light = SCNLight()
//        lightNode2.light!.type = SCNLightTypeOmni
//        lightNode2.position = SCNVector3Make(0, 0, 0);
//        rotationNode.addChildNode(lightNode2)
//        lightNode2.geometry = SCNSphere(radius: 0.5)
        
//        // create and add a light to the scene
//        let lightNode3 = SCNNode()
//        lightNode3.light = SCNLight()
//        lightNode3.light!.type = SCNLightTypeOmni
//        lightNode3.position = SCNVector3Make(2, 2, 2);
//        rotationNode.addChildNode(lightNode3)
//        lightNode3.geometry = SCNSphere(radius: 0.1)

        // scnView.technique =
        if let path = NSBundle.mainBundle().pathForResource("vignette", ofType: "plist") {
            if let dico1 = NSDictionary(contentsOfFile: path)  {
                let dico = dico1 as! [String : AnyObject]
                let technique = SCNTechnique(dictionary:dico)
                //Need the screen size
                technique?.setValue(NSValue(CGSize: CGSizeApplyAffineTransform(self.view.frame.size, CGAffineTransformMakeScale(2.0, 2.0))), forKeyPath: "size_screen")
                scnView.technique = technique
            }
        }
        
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // print("Tap")
        annimProgress = annimProgress + 1
        if annimProgress >  Float(plantProps.count - 1) {
            annimProgress = 0
        }
        SCNTransaction.begin()
        SCNTransaction.setAnimationDuration(0.5)
        plant.render(annimProgress)
        SCNTransaction.commit()
    }
    
    @IBAction func onPlantPan(gestureRecognize: UIPanGestureRecognizer) {
        let translation = gestureRecognize.translationInView(self.view)
        
        let horRotate = (self.currentCameraRotationHor - Float(translation.x)/80) % (Float(M_PI) * 2)
        var vertRotate = self.currentCameraRotationVert - Float(translation.y)/100
        vertRotate = max(vertRotate, -1)
        vertRotate = min(vertRotate, 0.2)
        
        let horRotateVect  = GLKMatrix4MakeRotation(horRotate, 0, 1, 0)
        let vertRotateVect = GLKMatrix4MakeRotation(vertRotate, 1, 0, 0)
        
        let result = GLKMatrix4Multiply(horRotateVect, vertRotateVect)
        
        let resultQuat = GLKQuaternionMakeWithMatrix4(result)
        
        rotationNode.orientation = SCNVector4Make(resultQuat.x, resultQuat.y, resultQuat.z, resultQuat.w)
        
        if(gestureRecognize.state == UIGestureRecognizerState.Ended) {
            currentCameraRotationHor = horRotate
            currentCameraRotationVert = vertRotate
        }
    }
    
    
    
    
    /**
     * State Update
     **/
    
    func onStateUpdate() {
        // print("Plant update")
        if state.plantShouldAnimate() {
            // print("Animate the plant !")
            state.plantStartAnimate()
            dispatch_after(
                dispatch_time(
                    DISPATCH_TIME_NOW,
                    Int64(2.0 * Double(NSEC_PER_SEC))
                ),
                dispatch_get_main_queue(),
                {
                    // print("end animate the plant !")
                    self.state.plantEndAnimating()
                }
            )
        } else if state.plantIsAnimating() {
            // print("Wait for end")
        } else {
            // print("Can do somethinf else :)")
        }
    }
    
    /**
     * Other
     **/
    
    override func shouldAutorotate() -> Bool {
        return true
    }

    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
