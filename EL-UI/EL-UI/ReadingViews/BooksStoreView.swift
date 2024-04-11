//
//  BooksStore.swift
//  EL-UI
//
//  Created by WJR on 1/26/24.
//

import SwiftUI
import SceneKit

struct BooksStoreView: View {
  @Binding var bookName: String
  @Binding var content: ViewContent
  
  @State var bookList: [BookInfo] = []
  @State var bookStoreViewDuration: CGFloat = 3
  @State var showBookList: Bool = false
  var body: some View {
    if showBookList {
      BookListView(bookName: $bookName, content: $content, bookList: $bookList)
    } else {
      BooksStoreSceneView(duration: bookStoreViewDuration)
        .ignoresSafeArea()
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + bookStoreViewDuration) {
            withAnimation {
              showBookList = true
            }
          }
          bookList.append(BookInfo(name: "diary", coverImage: nil, addTime: Date.now, finalOpenTime: Date.now, pageNumber: 0))
        }
    }
  }
}

struct BookListView: View {
  @Binding var bookName: String
  @Binding var content: ViewContent
  
  @Binding var bookList: [BookInfo]
  @State var showSearchBar: Bool = false
  @State var searchBookName: String = ""
  var body: some View {
    List {
      if showSearchBar {
        TextField("Search for the book title", text: $searchBookName)
      }
      ForEach(0 ..< bookList.count, id: \.self) { i in
        HStack(spacing: 30) {
          if let cover = bookList[i].coverImage {
            Image(uiImage: cover)
              .resizable()
              .frame(width: 50, height: 50)
          } else {
            Image("DiaryCover")
              .resizable()
              .scaledToFill()
              .frame(width: 50, height: 50)
          }
          VStack(alignment: .leading) {
            Text(bookList[i].name.uppercased())
              .font(.system(size: 26))
              .bold()
            Text(bookList[i].finalOpenTime.formatted(.dateTime.year().month().day()))
              .font(.headline)
              .foregroundColor(.gray)
            Text("Page Amount: " + String(bookList[i].pageNumber))
              .font(.headline)
              .foregroundColor(.gray)
          }
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
          Button(action: {
            withAnimation {
              bookName = bookList[i].name
              content = .reading(.bookContent(.readPage))
            }
          }) {
            Color.clear
          }
        }
      }
      .onDelete(perform: { indexs in
        if let index = indexs.first {
          bookList.remove(at: index)
        }
      })
    }
    .refreshable {
      withAnimation {
        showSearchBar.toggle()
      }
    }
    .overlay {
      if showSearchBar {
        VStack {
          HStack {
            Spacer()
            HStack {
              Button(action: {
                //Edit
              }) {
                Image(systemName: "list.dash")
                  .foregroundColor(.black)
                  .bold()
              }
              Button(action: {
                //Add Book
              }) {
                Image(systemName: "plus")
                  .foregroundColor(.black)
                  .bold()
              }
            }
            .padding(30)
          }
          Spacer()
        }
        .ignoresSafeArea()
      }
    }
  }
}

struct BooksStoreSceneView: UIViewRepresentable {
  let duration: CGFloat
  func makeUIView(context: Context) -> SCNView {
    let sceneView = SCNView()
    sceneView.scene = SCNScene()
    
    setupSceneView(sceneView, duration)
    
    let scene = SCNScene(named: "BookFrame.scn")
    
    for i in 0..<6 {
      let numberOfCubes = 33 + i * 10
      let radius: CGFloat = CGFloat(i) / 2 + 2
      let ringNode = SCNNode()
      
      for j in 0..<numberOfCubes {
        let angle = 2 * CGFloat.pi / CGFloat(numberOfCubes) * CGFloat(j)
        let cubePosition = SCNVector3(radius * cos(angle), 0, radius * sin(angle))
        
        let cubeNode = scene?.rootNode.childNode(withName: "Cube", recursively: true)?.clone() ?? SCNNode()
        cubeNode.position = cubePosition
        
        let lookAtConstraint = SCNLookAtConstraint(target: scene?.rootNode)
        cubeNode.constraints = [lookAtConstraint]
        
        ringNode.addChildNode(cubeNode)
      }
      
      sceneView.scene?.rootNode.addChildNode(ringNode)
      
      // Rotate around the y axis
      let rotateY = CABasicAnimation(keyPath: "rotation")
      rotateY.toValue = SCNVector4(0, 1, 0, CGFloat.pi * 2)
      rotateY.duration = 99 / Double(i + 1)
      rotateY.repeatCount = .infinity
      
      // Rotate around the x axis
      let rotateX = CABasicAnimation(keyPath: "rotation")
      rotateX.toValue = SCNVector4(1, 0, 0, CGFloat.pi * 2)
      rotateX.duration = 33 / Double(i + 1)
      rotateX.repeatCount = .infinity
      
      // Add the animations to ringNode
      ringNode.addAnimation(rotateY, forKey: "rotateY")
      ringNode.addAnimation(rotateX, forKey: "rotateX")
    }
    
    return sceneView
  }
  
  func updateUIView(_ uiView: SCNView, context: Context) {}
  
  private func setupSceneView(_ sceneView: SCNView, _ duration: CGFloat) {
    let cameraStartPlace: CGFloat = 126
    let cameraEndPlace: CGFloat = 6
    
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(x: 0, y: 0, z: Float(cameraStartPlace))
    sceneView.scene?.rootNode.addChildNode(cameraNode)
    
    let animation = CABasicAnimation(keyPath: "position.z")
    animation.fromValue = cameraStartPlace
    animation.toValue = cameraEndPlace
    animation.duration = duration
    animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
    cameraNode.addAnimation(animation, forKey: "positionZChange")
    
    // Set up the light
    let lightNode = SCNNode()
    lightNode.light = SCNLight()
    lightNode.light?.type = .ambient
    lightNode.position = SCNVector3(x: 0, y: 0, z: 0)
    sceneView.scene?.rootNode.addChildNode(lightNode)
    
    sceneView.backgroundColor = UIColor.white
    sceneView.allowsCameraControl = true
  }
}
