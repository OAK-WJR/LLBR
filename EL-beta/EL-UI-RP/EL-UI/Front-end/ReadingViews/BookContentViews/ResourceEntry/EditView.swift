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

enum TurnDiection {
  case left
  case right
}

struct ResourceEditView: View {
  @Binding var bookName: String
  @Binding var mainContent: ViewContent
  @Binding var viewContent: BookEditContent
  @EnvironmentObject var CL: RE_ContentLoader
  @State var selectedIndex: Int = 0
  @State var turnDiection: TurnDiection = .right
  
  @State var startSetting: Bool = false
  @State var previousFingerOffset: Double = 0
  @State var fingerOffset: Double = 0
  
  var body: some View {
    ZStack {
      if !CL.ids.isEmpty {
        if let index = CL.contents.firstIndex(where: {$0.id == CL.ids[selectedIndex]}), 
            let image = CL.contents[index].image {
          
          Group {
            Color.black
            Image(uiImage: image)
              .resizable()
              .aspectRatio(contentMode: .fit)
              .transition(.opacity)
              .id(selectedIndex)
          }
          .onSwipeGesture { direction in
            if direction == .left {
              turnDiection = .right
              withAnimation {
                selectedIndex = min(selectedIndex + 1, CL.ids.count-1)
              }
              
              let loadIndexes = (-1...1).map{selectedIndex + $0}.filter({$0>=0 && $0<=CL.ids.count-1})
              CL.upDateContents(indexes: loadIndexes)
              
              print(selectedIndex)
            } else if direction == .right {
              turnDiection = .left
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
        Color.black.ignoresSafeArea()
      }

      VStack {
        HStack {
          Button(action: {
            withAnimation {
              viewContent = .entry
            }
          }) {
            Image(systemName: "camera")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 25, height: 25)
              .foregroundStyle(.white)
              .opacity(0.7)
          }
          
          Spacer()
          
          Button(action: {
            DispatchQueue.global(qos: .background).async {
              let chunkSize = 5
              var chunks = [[Int]]()
              for startIndex in stride(from: 0, to: CL.ids.count, by: chunkSize) {
                let endIndex = startIndex + chunkSize
                if endIndex <= CL.ids.count {
                  chunks.append(Array(CL.ids[startIndex..<endIndex]))
                } else {
                  chunks.append(Array(CL.ids[startIndex..<CL.ids.count]))
                }
              }
              
              for loadIds in chunks {
                EditResourceDatabase().fetchImages(ids: loadIds) { images in
                  BooksDatabase().addOriginal(originals: images, to: bookName, chapterId: 0)
                }
              }
              
              EditResourceDatabase().dropTables() {
                DispatchQueue.main.async {
                  withAnimation {
                    mainContent = .reading(.bookContent(.readPage))
                  }
                }
              }
            }
          }) {
            Text("Finish")
              .font(.headline)
              .foregroundStyle(.white)
              .opacity(0.7)
          }
        }
        .padding(30)
        .padding(.top, 20)
        
        Spacer()

        ZStack {
          HStack {
            Spacer()
            HStack(spacing: 20) {
              Button(action: {
                
              }) {
                Image(systemName: "plus.square.on.square")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 25, height: 25)
                  .foregroundStyle(.white)
                  .opacity(0.7)
              }
              
              Button(action: {
                print(EditResourceDatabase().fetchSortedIds())
                EditResourceDatabase().deleteImages(startId: CL.ids[selectedIndex], quantity: 1, ids: CL.ids) {
                  print(EditResourceDatabase().fetchSortedIds())
                }
                CL.ids = EditResourceDatabase().fetchSortedIds().map{$0.id}
                let loadIndexes = (-1...1).map{selectedIndex + $0}.filter({$0>=0 && $0<=CL.ids.count-1})
                CL.upDateContents(indexes: loadIndexes)
              }) {
                Image(systemName: "trash")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 25, height: 25)
                  .foregroundStyle(.white)
                  .opacity(0.7)
              }
            }
            .overlay(
              RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(.white.opacity(0.8), lineWidth: 2)
                .frame(width: 120, height: 40)
            )
            .onLongPressGesture {
              print("yes")
              startSetting = true
            }
            .simultaneousGesture(
              DragGesture()
                .onChanged { gesture in
                  if startSetting == true {
                    fingerOffset += gesture.translation.height
                  }
                }
                .onEnded { _ in
                  if startSetting == true {
                    startSetting = false
                  }
                }
            )
          }
          .padding(.bottom, 50  + fingerOffset)
          .padding(.horizontal, 20)
        }
 
        HStack {
          Button(action: {
            
          }) {
            HStack(spacing: 0) {
              Text(String(selectedIndex + 1))
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
              Text("/\(String(CL.ids.count))")
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .top)))
                .font(.headline)
                .bold()
                .foregroundStyle(.white)
            }
          }
          Spacer()
        }
        .padding(30)
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
    
    EditResourceDatabase().fetchImages(ids: loadIds) { images in
      DispatchQueue.main.async {
        self.contents = images
        print(self.contents.map{$0.id})
      }
    }
  }
  
  func load() {
    ids = EditResourceDatabase().fetchSortedIds().map{$0.id}
    print(ids)
    let loadIndexes = (-1...1).map{0 + $0}.filter({$0>=0 && $0<=ids.count-1})
    upDateContents(indexes: loadIndexes)
  }
}
