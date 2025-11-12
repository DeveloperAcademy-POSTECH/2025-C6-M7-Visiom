//
//  AspectFitImage.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//
// 이미지 비율 기준으로 가로나 세로에 맞춰서 이미지를 피팅하는 뷰

import SwiftUI

struct AspectFitImage: View {
    @Environment(\.displayScale) private var displayScale
    
    let targetSize: CGSize
    let url: URL
    let photoSystemName: String = "photo"
    
    var body: some View {
        Group {
            if let uiImage = PhotoPipeline.image(
                for: url,
                targetSize: targetSize,
                scale: displayScale
            ) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .background(Color.black.opacity(0.02))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(.quaternary)
                    Image(systemName: photoSystemName)
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
