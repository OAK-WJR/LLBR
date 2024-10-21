//
//  Navigation.swift
//  EL-UI
//
//  Created by WJR on 1/24/24.
//

import Foundation
import SwiftUI
import SceneKit

struct MainNavigationView: View {
  @Binding var content: ViewContent
  @Binding var showMainNavigationView: Bool
  
  @AppStorage("hasSeenUserTip") var hasSeenUserTip: Bool = false
  
  @State private var isRed = true
  
  var body: some View {
    ZStack {
      MainNavigationSceneView(content: $content, hasSeenUserTip: $hasSeenUserTip, showMainNavigationView: $showMainNavigationView)
        .edgesIgnoringSafeArea(.all)
      
      VStack {
        Spacer()
        if !hasSeenUserTip {
          Text("Click on the task (planet) you want to go to")
            .foregroundColor(isRed ? .white : .blue)
            .font(.custom("Bubblegum", size: 9))
            .padding()
            .onAppear {
              withAnimation(Animation.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                isRed.toggle()
              }
            }
        }
      }
    }
    .preferredColorScheme(.dark)
  }
}

struct MainNavigationSceneView: UIViewRepresentable {
  @Binding var content: ViewContent
  @Binding var hasSeenUserTip: Bool
  @Binding var showMainNavigationView: Bool
  @State var showAnimateCameraForward = false
  
  class Coordinator: NSObject, CAAnimationDelegate {
    var content: Binding<ViewContent>
    var hasSeenUserTip: Binding<Bool>
    var showAnimateCameraForward: Binding<Bool>
    var showMainNavigationView: Binding<Bool>
    var lastTappedNodeName: String?
    
    init(content: Binding<ViewContent>, hasSeenUserTip: Binding<Bool>, showMainNavigationView: Binding<Bool>, showAnimateCameraForward: Binding<Bool>) {
      self.content = content
      self.hasSeenUserTip = hasSeenUserTip
      self.showMainNavigationView = showMainNavigationView
      self.showAnimateCameraForward = showAnimateCameraForward
      self.lastTappedNodeName = nil
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
      if flag {
        DispatchQueue.main.async {
          self.showMainNavigationView.wrappedValue = false
          self.showAnimateCameraForward.wrappedValue = false
        }
      }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      let sceneView = gesture.view as! SCNView
      let touchLocation = gesture.location(in: sceneView)
      let hitResults = sceneView.hitTest(touchLocation, options: [:])
      
      if let hitResult = hitResults.first {
        let nodeName = hitResult.node.name
        
        if nodeName == "ReadingPlanet" {
          // Remove the spin animation
          //hitResult.node.removeAnimation(forKey: "readingRotation", blendOutDuration: 0.2)
          self.content.wrappedValue = .reading(.booksList)
          self.showAnimateCameraForward.wrappedValue = true
          self.lastTappedNodeName = nodeName
        } else if nodeName == "LearningPlanet" {
          // Remove the spin and orbit animations
          //hitResult.node.removeAnimation(forKey: "learningRotation", blendOutDuration: 0.2)
          //hitResult.node.parent?.removeAnimation(forKey: "orbitAnimation", blendOutDuration: 0.2)
          self.content.wrappedValue = .learning
          self.showAnimateCameraForward.wrappedValue = true
          self.lastTappedNodeName = nodeName
        }
        self.hasSeenUserTip.wrappedValue = true
      }
    }
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(content: $content, hasSeenUserTip: $hasSeenUserTip, showMainNavigationView: $showMainNavigationView, showAnimateCameraForward: $showAnimateCameraForward)
  }
  
  func makeUIView(context: Context) -> SCNView {
    let sceneView = SCNView()
    let scene = SCNScene()
    sceneView.scene = scene
    sceneView.antialiasingMode = .multisampling4X
    
    let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
    sceneView.addGestureRecognizer(tapGesture)
    
    // Scale-down factor
    let scaleFactor: Float = 0.01
    
    // Set up the camera
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 0, y: 0, z: 2.5 * scaleFactor)
    cameraNode.look(at: SCNVector3(0, 0, 0))
    // Adjust the camera zNear and zFar
    cameraNode.camera?.zNear = 0.001
    cameraNode.camera?.zFar = 100
    scene.rootNode.addChildNode(cameraNode)
    
    // Add ambient light
    let ambientLight = SCNLight()
    ambientLight.type = .ambient
    ambientLight.color = UIColor(white: 0.3, alpha: 1.0)
    ambientLight.intensity = 500
    let ambientLightNode = SCNNode()
    ambientLightNode.light = ambientLight
    scene.rootNode.addChildNode(ambientLightNode)
    
    // Add the star particle system
    if let stars = SCNParticleSystem(named: "StarsParticles.scnp", inDirectory: nil) {
      let starsNode = SCNNode()
      starsNode.addParticleSystem(stars)
      starsNode.position = SCNVector3(0, 0, 0)
      // Adjust the scale of the star particle system
      starsNode.scale = SCNVector3(x: 1, y: 1, z: 1)
      scene.rootNode.addChildNode(starsNode)
    }
    
    // Create the "READING" sphere
    let readingSphere = SCNSphere(radius: 0.5 * CGFloat(scaleFactor))
    readingSphere.segmentCount = 1080
    let readingMaterial = createMaterial(with: "READING", textColor: .black, backgroundColor: .white)
    readingSphere.materials = [readingMaterial]
    let readingSphereNode = SCNNode(geometry: readingSphere)
    readingSphereNode.name = "ReadingPlanet"
    readingSphereNode.position = SCNVector3(x: 0, y: 0, z: 0)
    scene.rootNode.addChildNode(readingSphereNode)
    
    // Add the spin animation to the "READING" sphere
    let readingRotation = CABasicAnimation(keyPath: "rotation")
    readingRotation.fromValue = SCNVector4(0, 1, 0, 0)
    readingRotation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
    readingRotation.duration = 10
    readingRotation.repeatCount = .infinity
    readingSphereNode.addAnimation(readingRotation, forKey: "readingRotation")
    
    // Create the "LEARNING" sphere
    let learningSphere = SCNSphere(radius: 0.25 * CGFloat(scaleFactor))
    learningSphere.segmentCount = 1080
    let learningMaterial = createMaterial(with: "LEARNING", textColor: .black, backgroundColor: .white)
    learningSphere.materials = [learningMaterial]
    let learningSphereNode = SCNNode(geometry: learningSphere)
    learningSphereNode.name = "LearningPlanet"
    
    // Set up the orbit node
    let learningOrbitNode = SCNNode()
    learningOrbitNode.name = "LearningOrbitNode"
    scene.rootNode.addChildNode(learningOrbitNode)
    
    // Set the position of the "LEARNING" sphere
    learningSphereNode.position = SCNVector3(x: 1.0 * scaleFactor, y: 0, z: 0)
    learningOrbitNode.addChildNode(learningSphereNode)
    
    // Add the orbit animation to the "LEARNING" sphere
    let orbitAnimation = CABasicAnimation(keyPath: "rotation")
    orbitAnimation.fromValue = SCNVector4(0, 1, 0, 0)
    orbitAnimation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
    orbitAnimation.duration = 20
    orbitAnimation.repeatCount = .infinity
    learningOrbitNode.addAnimation(orbitAnimation, forKey: "orbitAnimation")
    
    // Add the spin animation to the "LEARNING" sphere
    let learningRotation = CABasicAnimation(keyPath: "rotation")
    learningRotation.fromValue = SCNVector4(0, 1, 0, 0)
    learningRotation.toValue = SCNVector4(0, 1, 0, Float.pi * 2)
    learningRotation.duration = 5
    learningRotation.repeatCount = .infinity
    learningSphereNode.addAnimation(learningRotation, forKey: "learningRotation")
    
    sceneView.backgroundColor = UIColor.black
    sceneView.allowsCameraControl = true
    
    return sceneView
  }
  
  func updateUIView(_ sceneView: SCNView, context: Context) {
    let scaleFactor: Float = 0.1
    
    if showAnimateCameraForward {
      if let cameraNode = sceneView.pointOfView, let nodeName = context.coordinator.lastTappedNodeName {
        sceneView.allowsCameraControl = false
        
        if nodeName == "ReadingPlanet" {
          // Remove the spin animation and reset the rotation angle
          if let targetNode = sceneView.scene?.rootNode.childNode(withName: nodeName, recursively: true) {
            targetNode.removeAllAnimations()
          }
        } else if nodeName == "LearningPlanet" {
          // Remove the spin and orbit animations and reset the rotation angle
          if let learningOrbitNode = sceneView.scene?.rootNode.childNode(withName: "LearningOrbitNode", recursively: true) {
            learningOrbitNode.removeAllAnimations()
          }
          if let learningPlanetNode = sceneView.scene?.rootNode.childNode(withName: nodeName, recursively: true) {
            learningPlanetNode.removeAllAnimations()
          }
        }
        
        // Camera animation
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = cameraNode.position
        animation.toValue = SCNVector3(x: 0, y: 0, z: 0.08 * scaleFactor) // adjust the camera position
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        if let targetNode = sceneView.scene?.rootNode.childNode(withName: nodeName, recursively: true) {
          let constraint = SCNLookAtConstraint(target: targetNode)
          cameraNode.constraints = [constraint]
        }
        
        animation.delegate = context.coordinator
        animation.fillMode = .forwards
        
        cameraNode.addAnimation(animation, forKey: "positionZChange")
      }
    }
  }
  
  // Create the material: white background, black text
  func createMaterial(with text: String, textColor: UIColor, backgroundColor: UIColor) -> SCNMaterial {
    let material = SCNMaterial()
    material.lightingModel = .constant // use the constant model so lighting does not change the white
    material.isDoubleSided = false
    
    // Diffuse (base color)
    let diffuseImage = self.textToImage(drawText: text,
                                        fontSize: 50, // adjust the font size
                                        imageSize: CGSize(width: 1080, height: 1080), // adjust the texture size
                                        textColor: textColor,
                                        backgroundColor: backgroundColor)
    material.diffuse.contents = diffuseImage
    
    return material
  }
  
  func textToImage(drawText text: String, fontSize: CGFloat, imageSize: CGSize, textColor: UIColor, backgroundColor: UIColor) -> UIImage {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    
    let font = UIFont(name: "Bubblegum", size: fontSize) ?? .systemFont(ofSize: fontSize)
    let attributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: textColor,
      .paragraphStyle: paragraphStyle
    ]
    
    let scale = UIScreen.main.scale
    UIGraphicsBeginImageContextWithOptions(imageSize, true, scale)
    backgroundColor.setFill()
    UIRectFill(CGRect(origin: .zero, size: imageSize))
    
    let textSize = text.size(withAttributes: attributes)
    let rect = CGRect(x: (imageSize.width - textSize.width) / 2, y: (imageSize.height - textSize.height) / 2, width: textSize.width, height: textSize.height)
    text.draw(in: rect, withAttributes: attributes)
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage ?? UIImage()
  }
}
