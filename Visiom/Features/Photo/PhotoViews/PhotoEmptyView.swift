//
//  PhotoEmptyView.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import SwiftUI

struct PhotoEmptyView: View {
    let title: String = "사진을 선택해보세요"
    let systemImageName: String = "photo.on.rectangle.angled"
    let subtitle: String = "우상단 + 버튼으로 여러 장 선택"
    
    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImageName,
            description: Text(subtitle)
        )
    }
}

