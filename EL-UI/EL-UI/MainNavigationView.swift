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
  var body: some View {
    ZStack {
      MainNavigationSceneView(content: $content, showMainNavigationView: $showMainNavigationView)
        .edgesIgnoringSafeArea(.all)
      VStack {
        Spacer()
        Text("Trust your self, it's a circle and always will be")
          .foregroundColor(.white)
          .font(.custom("Bubblegum", size: 9))
          .padding()
      }
    }
    .preferredColorScheme(.dark)
  }
}

struct MainNavigationSceneView: UIViewRepresentable {
  @Binding var content: ViewContent
  @Binding var showMainNavigationView: Bool
  @State var showAnimateCameraForward = false
  
  class Coordinator: NSObject, CAAnimationDelegate {
    var content: Binding<ViewContent>
    var showAnimateCameraForward: Binding<Bool>
    var showMainNavigationView: Binding<Bool>
    
    init(content: Binding<ViewContent>, showMainNavigationView: Binding<Bool>, showAnimateCameraForward: Binding<Bool>) {
      self.content = content
      self.showMainNavigationView = showMainNavigationView
      self.showAnimateCameraForward = showAnimateCameraForward
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
      if flag {
        DispatchQueue.main.async {
          self.showMainNavigationView.wrappedValue = false
        }
      }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
      if gesture.state == .began {
        self.content.wrappedValue = .reading(.booksList)
        self.showAnimateCameraForward.wrappedValue = true
      }
    }
  }
  
  func makeCoordinator() -> Coordinator {
    return Coordinator(content: $content, showMainNavigationView: $showMainNavigationView, showAnimateCameraForward: $showAnimateCameraForward)
  }
  
  func makeUIView(context: Context) -> SCNView {
    let sceneView = SCNView()
    sceneView.scene = SCNScene()
    
    let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress))
    sceneView.addGestureRecognizer(longPressGesture)
    
    // Set up the camera
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 0, y: 0, z: 5)
    sceneView.scene?.rootNode.addChildNode(cameraNode)
    
    // Set up the light
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light?.type = .omni
    lightNode.position = SCNVector3(x: 0, y: 10, z: 2)
    sceneView.scene?.rootNode.addChildNode(lightNode)
    
    
    // Add the star particle system
    if let stars = SCNParticleSystem(named: "StarsParticles.scnp", inDirectory: nil) {
      sceneView.scene?.rootNode.addParticleSystem(stars)
    }
    
    //Set up the sphere
    let sphere = SCNSphere(radius: 1)
    sphere.segmentCount = 1080
    let material = SCNMaterial()
    material.lightingModel = .constant // not affected by lighting
    material.isDoubleSided = true
    material.diffuse.contents = UIColor.white // set the color
    let image = self.textToImage(drawText: "READING",
                                 fontSize: 29,
                                 imageSize: CGSize(width: 900, height: 900),
                                 textColor: UIColor.black,
                                 backgroundColor: UIColor.white)
    material.diffuse.contents = image
    
    sphere.materials = [material]
    let sphereNode = SCNNode(geometry: sphere)
    sphereNode.name = "LearningPlanet"
    sceneView.scene?.rootNode.addChildNode(sphereNode)
    
    sceneView.backgroundColor = UIColor.black
    sceneView.allowsCameraControl = true
    
    return sceneView
  }
  
  func updateUIView(_ sceneView: SCNView, context: Context) {
    if showAnimateCameraForward {
      if let cameraNode = sceneView.pointOfView {
        sceneView.allowsCameraControl = false
        
        let animation = CABasicAnimation(keyPath: "position")
        animation.fromValue = cameraNode.position
        animation.toValue = SCNVector3(x: 0, y: 0, z: 1.9)
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let constraint = SCNLookAtConstraint(target: sceneView.scene?.rootNode.childNode(withName: "LearningPlanet", recursively: true))
        cameraNode.constraints = [constraint]
        
        animation.delegate = context.coordinator
        animation.fillMode = .forwards

        cameraNode.addAnimation(animation, forKey: "positionZChange")
      }
    }
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
    let rect = CGRect(x: 0, y: (imageSize.height - textSize.height) / 2, width: imageSize.width, height: textSize.height)
    text.draw(in: rect, withAttributes: attributes)
    
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return newImage ?? UIImage()
  }
}
