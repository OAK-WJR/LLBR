//
//  FlowViewNew.swift
//  EL
//
//  Written in 2026 for the public copy of this project. The original file was
//  written by my mentor and is not included here. This version only puts the
//  existing screens together so that the Beta 1.0 project builds.
//

import SwiftUI

/// The screen shown in the main area.
enum MainContentTag {
  case camera
  case processing
  case reading
}

/// The main screen of Beta 1.0: the current page (camera, photo editing or
/// reading), a side panel that slides in (book list or page list), and the
/// navigation bar.
struct FlowViewNew: View {
  @State private var mainContent: MainContentTag = .camera
  @State private var sideContent: SideContentTag = .bookList
  @State private var showSideContent = false

  @State private var bookName = "diary"
  @State private var pageIndex = 0
  @State private var ids = [Int]()

  @State private var image = UIImage()
  @State private var result = PictureShowPage()
  @State private var showImage = false
  @State private var showResult = false

  var body: some View {
    GeometryReader { geometry in
      let size = geometry.size
      let landscape = size.width > size.height
      let stack = landscape
        ? AnyLayout(HStackLayout(alignment: .top, spacing: 0))
        : AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
      stack {
        contentArea(panelWidth: size.width * InterfaceData.sidebarScaleL)
          .frame(width: landscape ? size.width * (1 - InterfaceData.sidebarScaleH) : size.width,
                 height: landscape ? size.height : min(size.height, size.width * InterfaceData.photoScale))
        NavigationView(bookName: $bookName, index: $pageIndex, ids: $ids,
                       sideContent: $sideContent, mainContent: $mainContent,
                       showSideContent: $showSideContent)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    // The Beta 1.0 screens are drawn for a dark background.
    .preferredColorScheme(.dark)
  }

  /// The current page, with the side panel sliding in from the trailing edge.
  private func contentArea(panelWidth: CGFloat) -> some View {
    ZStack(alignment: .trailing) {
      currentPage
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      if showSideContent {
        sidePanel
          .frame(width: panelWidth)
          .frame(maxHeight: .infinity)
          .background(Color(.systemBackground))
          .transition(.move(edge: .trailing))
      }
    }
    .clipped()
    .animation(.easeInOut(duration: 0.25), value: showSideContent)
  }

  @ViewBuilder
  private var currentPage: some View {
    switch mainContent {
    case .camera:
      CameraView(bookName: $bookName, index: $pageIndex, ids: $ids)
        .ignoresSafeArea()
    case .processing:
      ProcessPhotoView()
    case .reading:
      ReadingView(bookName: $bookName, pageIndex: $pageIndex,
                  image: $image, result: $result,
                  showImage: $showImage, showResult: $showResult)
    }
  }

  @ViewBuilder
  private var sidePanel: some View {
    switch sideContent {
    case .bookList:
      BookListView()
    case .pageList:
      PageListView(mainContent: $mainContent, showSideContent: $showSideContent,
                   bookName: $bookName, pageIndex: $pageIndex, ids: $ids,
                   image: $image, result: $result,
                   showImage: $showImage, showResult: $showResult)
    }
  }
}

#Preview {
  FlowViewNew()
}
