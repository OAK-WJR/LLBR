//
//  EditView.swift
//  EL-UI
//
//  Created by WJR on 4/10/24.
//

import SwiftUI

/*
struct ResourceEditView: View {
  private let triggerLoadNumber = 1
  
  @ObservedObject var CL = RE_ContentLoader()
  
  @State var selectedId: Int = 1
  var body: some View {
    if !CL.ids.isEmpty {
      ScrollView(.horizontal) {
        LazyHStack(spacing: 0) {
          ForEach(CL.ids, id: \.self) { id in
            if let index: Int = CL.contents.firstIndex(where: { $0.id == id}) {
              Image(uiImage: CL.contents[index].image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onAppear {
                  appearProcessing(id: id)
                }
            } else {
              LoadingView()
            }
          }
        }
        .scrollTargetLayout()
      }
      .scrollTargetBehavior(.paging)
      .ignoresSafeArea()
    } else {
      LoadingView()
        .onAppear {
          CL.loadInitialContent()
          selectedId = CL.ids.first ?? 0
        }
    }
  }
}

extension ResourceEditView {
  
  func appearProcessing(id: Int) {
    if let index: Int = CL.contents.firstIndex(where: { $0.id == id}) {
      if Double(index) <= Double(triggerLoadNumber) - 1 {
        // User has scrolled near the top, load previous content
        CL.loadMoreViewContent(direction: .previous)
      } else if Double(index) >= Double(CL.contents.count) - Double(triggerLoadNumber) {
        // User has scrolled near the bottom, load next content
        CL.loadMoreViewContent(direction: .next)
      }
    }
  }
}

class RE_ContentLoader: ObservableObject {
  private let batchSize = 2
  private let maxContentCount = 4
  
  @Published var ids: [Int] = []
  @Published var contents: [CroppingImage] = []
  
  @Published var isLoading = false
  
  func loadInitialContent() {
    ids = EditResourceDatabase().fetchSortedIds()
    
    let initialIndexes = Array(ids.prefix(maxContentCount))
    singleDirectionLoadViewContent(for: initialIndexes, direction: .next) {
      self.isLoading = false
    }
  }
  // Load more content in the given direction
  func loadMoreViewContent(direction: DataLoadDirection) {
    guard !isLoading else { return }
    isLoading = true
    
    // Determine the ID of the relevant content based on the direction of loading
    let relevantId: Int?
    switch direction {
    case .previous:
      relevantId = contents.first?.id
    case .next:
      relevantId = contents.last?.id
    }
    
    // Ensure the ID is valid and determine the new range of IDs to load
    guard let id = relevantId, let index = ids.firstIndex(of: id) else {
      isLoading = false
      return
    }
    
    let newIndexes: [Int]
    switch direction {
    case .previous:
      // Load the previous batch of content
      let start = max(0, index - batchSize)
      newIndexes = Array(ids[start..<index])
    case .next:
      // Load the next batch of content
      let end = min(ids.count, index + batchSize)
      newIndexes = Array(ids[index..<end])
    }
    
    // Load the content for the new range of IDs
    singleDirectionLoadViewContent(for: newIndexes, direction: direction) {
      // After loading new content, adjust the currently held content based on the maxContentCount
      switch direction {
      case .previous:
        if self.contents.count > self.maxContentCount {
          // If the maximum number is exceeded, remove the trailing elements
          self.contents.removeLast(self.contents.count - self.maxContentCount)
        }
      case .next:
        if self.contents.count > self.maxContentCount {
          // If the maximum number is exceeded, remove the header element
          self.contents.removeFirst(self.contents.count - self.maxContentCount)
        }
      }
      print(self.contents.count)
      self.isLoading = false
    }
  }
  
  // Function to load view content for the specified IDs and handle the completion
  func singleDirectionLoadViewContent(for loadImagesIds: [Int], direction: DataLoadDirection, completion: @escaping () -> Void) {
    
    DispatchQueue.global(qos: .userInitiated).async {
      // Fetch the original images from the database for the specified IDs
      let newContents: [CroppingImage] = EditResourceDatabase().fetchImages(ids: loadImagesIds)
      
      DispatchQueue.main.async {
        // Insert or append new images to the contents array based on the direction
        if direction == .previous {
          // Loading content to be displayed above the current content
          self.contents.insert(contentsOf: newContents, at: 0)
        } else {
          // Loading content to be displayed below the current content
          self.contents.append(contentsOf: newContents)
        }
        
        // Call the completion handler
        completion()
      }
    }
  }
  
  func doubleDirectionsLoadViewContent(for id: Int, completion: @escaping () -> Void) {
    // Calculate the range of IDs to load
    let halfRange = maxContentCount / 2
    let startIdIndex = max(0, id - halfRange)
    let endIdIndex = min(self.ids.count, id + halfRange)
    let loadImagesIds: [Int] = Array(self.ids[startIdIndex..<endIdIndex])
    // Load images for the calculated range of IDs
    self.contents = EditResourceDatabase().fetchImages(ids: loadImagesIds)
    
    // Call the completion handler
    completion()
  }
}
*/

import SwiftUI

struct ResourceEditView: View {
  @StateObject var CL = RE_ContentLoader()
  @State var selectedIndex: Int = Int()
  
  var body: some View {
    ZStack {
      if !CL.ids.isEmpty {
        if let index = CL.contents.firstIndex(where: {$0.id == CL.ids[selectedIndex]}), let image = CL.contents[index].image {
          Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: UIScreen.main.bounds.height)
            .transition(.asymmetric(
              insertion: .move(edge: .trailing),
              removal: .move(edge: .leading)
            ))
            .onSwipeGesture { direction in
              if direction == .left {
                withAnimation {
                  selectedIndex = min(selectedIndex + 1, CL.ids.count-1)
                }
                
                let loadIndexes = (-1...1).map{selectedIndex + $0}.filter({$0>=0 && $0<=CL.ids.count-1})
                CL.upDateContents(indexes: loadIndexes)
                
                print(selectedIndex)
              } else if direction == .right {
                withAnimation {
                  selectedIndex = max(0, selectedIndex - 1)
                }
                
                let loadIndexes = (-1...1).map{selectedIndex + $0}.filter({$0>=0 && $0<=CL.ids.count-1})
                print(loadIndexes)
                CL.upDateContents(indexes: loadIndexes)
                
                print(selectedIndex)
              }
              
            }
        }
      } else {
        LoadingView()
          .onAppear {
            CL.ids = EditResourceDatabase().fetchSortedIds()
            print(CL.ids)
            self.selectedIndex = 0
            let loadIndexes = (-1...1).map{selectedIndex + $0}.filter({$0>=0 && $0<=CL.ids.count-1})
            print(loadIndexes)
            CL.upDateContents(indexes: loadIndexes)
            
          }
      }
    }
    .ignoresSafeArea()
  }
}

class RE_ContentLoader: ObservableObject {
  @Published var ids: [Int] = []
  @Published var contents: [CroppingImage] = []
  
  func upDateContents(indexes: [Int]) {
    let loadIds: [Int] = indexes.map{ids[$0]}
    
    //Load the ones we need
    let newImages = EditResourceDatabase().fetchImages(ids: loadIds)
    
    DispatchQueue.main.async {
      self.contents = newImages
      print(self.contents.map{$0.id})
    }
  }
}
