//
//  ImageGalleryView.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import SwiftUI

struct ImageGalleryView: View {
    @Environment(PlacedImageStore.self) var placedImageStore

    let urls: [URL]
    let collectionID: UUID
    @Binding var selectedIndex: Int
    
    var cornerRadius: CGFloat = 8
    var previewSize: CGSize = .init(width: 1143, height: 419)
    var thumbnailSize: CGSize = .init(width: 156, height: 110)
    var thumbnailSpacing: CGFloat = 8
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.05)
                
                if let url = urls[safe: selectedIndex] {
                    // 이미지 사이즈 조정
                    AspectFitImage(targetSize: previewSize, url: url)
                        .frame(width: previewSize.width, height: previewSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .stroke(.quaternary, lineWidth: 1)
                        )
                        .overlay(alignment: .topLeading) {
                            FilenameBadge(url: url)
                                .padding(10)
                        }
                        .overlay(alignment: .topTrailing) {
                            Button{
                                let fileName = url.lastPathComponent
                                let placedImage = placedImageStore.createPlacedImage(imageFileName: fileName, from: collectionID)
                                placedImageStore.placedImageToAnchorID = placedImage.id
                            } label: {
                                PlacedImageButtonLabel()
                            }
                        }
                        .id(selectedIndex)
                }
            }
            .frame(width: previewSize.width, height: previewSize.height)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // 하단 썸네일 스크롤
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: thumbnailSpacing) {
                        ForEach(urls.indices, id: \.self) { idx in
                            let url = urls[idx]
                            Button {
                                withAnimation(.easeInOut) {
                                    selectedIndex = idx
                                    proxy.scrollTo(idx, anchor: .center)
                                }
                            } label: {
                                ImageThumbnail(
                                    url: url,
                                    cornerRadius: cornerRadius,
                                    isSelected: idx == selectedIndex,
                                    size: thumbnailSize
                                )
                            }
                            .id(idx)
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                // 초기 선택 썸네일로 스크롤
                .onAppear {
                    if urls.indices.contains(selectedIndex) {
                        proxy.scrollTo(selectedIndex, anchor: .center)
                    }
                }
                .onChange(of: selectedIndex, initial: false) { _, newValue in
                    if urls.indices.contains(newValue) {
                        withAnimation(.easeInOut) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
    }
}

private struct FilenameBadge: View {
    let url: URL
    var body: some View {
        Text(url.lastPathComponent)
            .font(.callout.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

private struct PlacedImageButtonLabel: View {
    var body: some View {
        Text("공간에 추가하기")
            .font(.callout.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

// 인덱싱
private extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
