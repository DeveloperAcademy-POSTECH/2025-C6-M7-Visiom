//
//  TextFieldAttachmentView.swift
//  Visiom
//
//  Created by 윤창현 on 10/21/25.
//

import SwiftUI

struct TextFieldAttachmentView: View {
    @Binding var text: String
    let placeholder: String
    let width: CGFloat
    let height: CGFloat
    let font: Font
    let alignment: TextAlignment
    let padding: CGFloat
    let cornerRadius: CGFloat
    let backgroundMaterial: Material
    
    /// 완전히 커스터마이징 가능한 TextField
    /// - Parameters:
    ///   - text: 바인딩할 텍스트
    ///   - placeholder: 플레이스홀더 (기본값: "Enter text")
    ///   - width: TextField 너비 (기본값: 200)
    ///   - font: 폰트 스타일 (기본값: .headline)
    ///   - alignment: 텍스트 정렬 (기본값: .center)
    ///   - padding: 내부 여백 (기본값: 6)
    ///   - cornerRadius: 모서리 둥글기 (기본값: 12)
    ///   - useRoundedBorder: 둥근 테두리 스타일 사용 여부 (기본값: true)
    ///   - backgroundMaterial: 배경 Material (기본값: .ultraThinMaterial)
    
    init(
        text: Binding<String>,
        placeholder: String = "Enter text",
        width: CGFloat = 200,
        height: CGFloat = 200,
        font: Font = .headline,
        alignment: TextAlignment = .center,
        padding: CGFloat = 6,
        cornerRadius: CGFloat = 12,
        backgroundMaterial: Material = .ultraThinMaterial
    ) {
        self._text = text
        self.placeholder = placeholder
        self.width = width
        self.height = width
        self.font = font
        self.alignment = alignment
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundMaterial = backgroundMaterial
    }
    
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.automatic)
            .font(font)
            .multilineTextAlignment(alignment)
            .frame(width: width, height: height)
            .padding(padding)
            .background(backgroundMaterial)
            .cornerRadius(cornerRadius)
    }
}

