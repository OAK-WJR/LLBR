//
//  PhotosView.swift
//  EL
//
//  Created by mentor on 2023/11/23.
//

import SwiftUI

struct PhotosView: View {
  @Binding var bookName: String
  @Binding var index: Int
  @Binding var ids: [Int]
  @State var pictures = [UIImage]()
  @State var imagesPerLine: Int = 4
  var body: some View {
    if pictures.count != 0 {
      ScrollView {
        LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: -60), count: imagesPerLine), spacing: 2) {
          ForEach(0..<pictures.count, id: \.self) { idx in
            Button(action: {
              index = ids[idx]
            }) {
              Image(uiImage: pictures[idx])
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .clipped()
            }
          }
        }
        .padding(2)
      }
    } else {
      LoadingView()
        .onAppear {
          DispatchQueue.global(qos: .userInitiated).async {
            ids = BooksDatabase().getAllIds(from: bookName)
            let originals = BooksDatabase().getOriginal(at: ids, from: bookName)
              .compactMap { $0.original }
            let thumbnailPictures = OriginalProcessing.Photo().createThumbnail(images: originals,
                                                                  targetSize: CGSize(width: 100, height: 100)) ?? []
            DispatchQueue.main.async {
                pictures = thumbnailPictures
            }
          }
        }
    }
  }
}
