//
//  WordsShowingView.swift
//  EL-UI
//
//  Created by WJR on 4/8/24.
//

import SwiftUI
import UIKit
import CoreImage

struct WordsShowingView: View {
  var bookName: String
  var selectedPageId: Int?
  @Binding var selectedWordIndex: Int
  
  @ObservedObject var CL: RP_ContentLoader
  @ObservedObject var VO: RP_ViewObserver
  
  var body: some View {
    if let selectedPageIndex = CL.contents.firstIndex(where: {$0.id == selectedPageId ?? VO.appearedPageIds.first}),
       let textContent = CL.contents[selectedPageIndex].textContent {
      VStack {
        Spacer()
        TabView(selection: $selectedWordIndex) {
          ForEach(textContent.unknownWordsIndex!, id: \.self) { index in
            WordCardView(content: $CL.contents[selectedPageIndex], index: index, bookName: bookName, pageIndex: selectedPageIndex, opacity: 0.75)
              .tag(index)
          }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: 90)
      }
    }
  }
}
