//
//  ViewController.swift
//  ARDrawing
//
//  Created by Dmytro Skorokhod on 12/22/17.
//  Copyright © 2017 Dmytro Skorokhod. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import EFColorPicker

class ViewController: UIViewController, ARSCNViewDelegate, EFColorSelectionViewControllerDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var drawButton: UIButton!
    
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.run(configuration)
    }
    
    let pointer = SCNNode(geometry: SCNSphere(radius: 0.01))
    let dotRadius: CGFloat = 0.01
    
    func selectedColor() -> UIColor {
        return self.drawButton.backgroundColor ?? UIColor.white
    }
    
    func renderer(_ renderer: SCNSceneRenderer,
                  willRenderScene scene: SCNScene,
                  atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else {
            return
        }
        
        let orientation = SCNVector3(-pointOfView.transform.m31,
                                     -pointOfView.transform.m32,
                                     -pointOfView.transform.m33)
        let location = SCNVector3(pointOfView.transform.m41,
                                  pointOfView.transform.m42,
                                  pointOfView.transform.m43)
        let currentPositionOfCamera = orientation + location
        
        DispatchQueue.main.async { [weak self] in
            guard let this = self else { return }
            
            if this.drawButton.isHighlighted {
                let sphereNode = SCNNode(geometry: SCNSphere(radius: this.dotRadius))
                sphereNode.position = currentPositionOfCamera
                sphereNode.geometry?.firstMaterial?.diffuse.contents = this.selectedColor()
                
                this.sceneView.scene.rootNode.addChildNode(sphereNode)
            } else {
                this.pointer.removeFromParentNode()
                
                this.pointer.position = currentPositionOfCamera
                this.pointer.geometry?.firstMaterial?.diffuse.contents = this.drawButton.backgroundColor ?? UIColor.white
                
                this.sceneView.scene.rootNode.addChildNode(this.pointer)
            }
        }
        
    }
    
    @IBAction func changeColor(_ sender: Any) {
        let colorSelectionController = EFColorSelectionViewController()
        let navCtrl = UINavigationController(rootViewController: colorSelectionController)
        navCtrl.navigationBar.backgroundColor = UIColor.white
        navCtrl.navigationBar.isTranslucent = false
        navCtrl.modalPresentationStyle = UIModalPresentationStyle.popover
        navCtrl.preferredContentSize = colorSelectionController.view.systemLayoutSizeFitting(
            UILayoutFittingCompressedSize
        )
        
        let doneBtn: UIBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Done", comment: ""),
            style: UIBarButtonItemStyle.done,
            target: self,
            action: #selector(ef_dismissViewController(sender:)))
        
        colorSelectionController.navigationItem.rightBarButtonItem = doneBtn
        
        colorSelectionController.delegate = self
        colorSelectionController.color = drawButton.backgroundColor ?? UIColor.white
        
        self.present(navCtrl, animated: true, completion: nil)
    }
    
    @IBAction func reset(_ sender: Any) {
        restartSession()
    }
    
    // MARK:- EFColorSelectionViewControllerDelegate
    func colorViewController(colorViewCntroller: EFColorSelectionViewController, didChangeColor color: UIColor) {
        drawButton.backgroundColor = color
    }
    
    func restartSession() {
        sceneView.session.pause()
        
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        
        sceneView.session.run(configuration,
                              options: [.resetTracking,
                                        .removeExistingAnchors])
    }
    
    @objc func ef_dismissViewController(sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x,
                          left.y + right.y,
                          left.z + right.z)
}

