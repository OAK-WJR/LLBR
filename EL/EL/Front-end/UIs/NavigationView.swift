//
//  NavigationView.swift
//  EL
//
//  Created by WJR on 11/25/23.
//

import SwiftUI

enum SideContentTag {
  case bookList
  case pageList
}

struct NavigationView: View {
  @State var screen = UIScreen.main.bounds.size
  @Binding var bookName: String
  @Binding var index: Int
  @Binding var ids: [Int]
  @Binding var sideContent: SideContentTag
  @Binding var mainContent: MainContentTag
  @Binding var showSideContent: Bool
  var body: some View {
    HStack {
      Button(action: {
        if mainContent == .camera {
          if showSideContent == true {
            withAnimation(.easeInOut(duration: 0.5)) {
              showSideContent = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
              if sideContent == .pageList {
                sideContent = .bookList
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  withAnimation(.easeInOut(duration: 0.5)) {
                    showSideContent = true
                  }
                }
              }
            }
            
          } else {
            sideContent = .bookList
            withAnimation {
              showSideContent = true
            }
          }
        } else if mainContent == .reading {
          mainContent = .camera
        }
      }) {
        if mainContent == .camera {
          HStack() {
            Image(systemName: "list.bullet")
            Text(bookName.uppercased())
          }
          .foregroundColor(.white)
          .font(Font.headline.weight(.bold))
          .padding()
        } else if mainContent == .reading {
          Image(systemName: "camera")
            .foregroundColor(.white)
            .font(Font.headline.weight(.bold))
            .padding()
        }
      }
      
      Button(action: {
        if showSideContent == true {
          withAnimation(.easeInOut(duration: 0.5)) {
            showSideContent = false
          }
          
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if sideContent == .bookList {
              sideContent = .pageList
              
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.5)) {
                  showSideContent = true
                }
              }
            }
          }
          
        } else {
          sideContent = .pageList
          withAnimation {
            showSideContent = true
          }
        }
      }) {
        Text(String(ids.count))
          .frame(maxWidth: .infinity)
          .foregroundColor(.white)
          .font(Font.headline.weight(.bold))
      }
      .onAppear {
        DispatchQueue.global(qos: .userInitiated).async {
          ids = BooksDatabase().getAllIds(from: bookName)
        }
      }
    }
  }
}
