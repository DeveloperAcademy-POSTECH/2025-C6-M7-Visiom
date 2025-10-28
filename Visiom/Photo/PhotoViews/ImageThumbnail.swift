//
//  ImageThumbnail.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import SwiftUI

struct ImageThumbnail: View {
    @Environment(\.displayScale) private var displayScale
    
    let url: URL
    var cornerRadius: CGFloat = 8
    var isSelected: Bool = false
    var size: CGSize = CGSize(width: 156, height: 110)
    
    var body: some View {
        ZStack {
            if let uiImage = PhotoPipeline.image(
                for: url,
                targetSize: size,
                scale: displayScale
            ) {
                // 이미지 불러오기 성공
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                // 이미지 불러오기 실패
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius).fill(.quaternary)
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(isSelected ? Color.blue : .clear, lineWidth: 2)
        }
        .contentShape(Rectangle())
    }
}
