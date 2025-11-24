//
//  ImageGalleryView.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import SwiftUI

struct ImageGalleryView: View {
    @Environment(AppModel.self) var appModel
    @Environment(PlacedImageStore.self) var placedImageStore

    let urls: [URL]
    let collectionID: UUID
    @Binding var selectedIndex: Int

    var cornerRadius: CGFloat = 8
    var previewSize: CGSize = .init(width: 1143, height: 419)
    var thumbnailSize: CGSize = .init(width: 284, height: 186)
    var thumbnailSpacing: CGFloat = 8

    let columns: [GridItem] = Array(
        repeating: .init(.flexible(), spacing: 11),
        count: 4
    )

    var body: some View {
        NavigationStack {
            Divider()
            ScrollView {
                LazyVGrid(columns: columns, spacing: thumbnailSpacing) {
                    ForEach(urls.indices, id: \.self) { idx in
                        let url = urls[idx]

                        NavigationLink(value: url) {
                            ImageThumbnail(
                                url: url,
                                cornerRadius: cornerRadius,
                                isSelected: idx == selectedIndex,
                                size: thumbnailSize
                            )
                            .hoverEffect(.lift)
                        }
                        .overlay(alignment: .bottomLeading) {
                            FilenameBadge(url: url)
                        }
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: cornerRadius,
                                style: .continuous
                            )
                        )
                        .contentShape(
                            .hoverEffect,
                            RoundedRectangle(
                                cornerRadius: cornerRadius,
                                style: .continuous
                            )
                        )
                        .id(idx)
                    }
                }.padding(16)
            }
            .navigationTitle("Photo Collection")
            .navigationDestination(for: URL.self) { url in
                SeletedImageView(
                    url: url,
                    collectionID: collectionID
                )
            }
        }
    }
}

private struct FilenameBadge: View {
    let url: URL
    var body: some View {
        Text(url.lastPathComponent)
            .font(.system(size: 19, weight: .medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
    }
}

// 인덱싱
extension Collection {
    fileprivate subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
