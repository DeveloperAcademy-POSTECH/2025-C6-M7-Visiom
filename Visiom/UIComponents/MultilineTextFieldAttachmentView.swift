//
//  MultilineTextFieldAttachmentView.swift
//  Visiom
//
//  Created by jiwon on 11/7/25.
//

import SwiftUI

struct MultilineTextFieldAttachmentView: View {
    
    @Binding var text: String
    let placeholder: String
    let width: CGFloat
    let height: CGFloat
    let font: Font
    let alignment: TextAlignment
    let padding: CGFloat
    let cornerRadius: CGFloat
    let backgroundMaterial: Material
    
    init(
        text: Binding<String>,
        placeholder: String = "Enter text",
        width: CGFloat = 200,
        height: CGFloat = 200,
        font: Font = .headline,
        alignment: TextAlignment = .leading,
        padding: CGFloat = 6,
        cornerRadius: CGFloat = 12,
        backgroundMaterial: Material = .ultraThinMaterial
    ) {
        self._text = text
        self.placeholder = placeholder
        self.width = width
        self.height = height
        self.font = font
        self.alignment = alignment
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundMaterial = backgroundMaterial
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(font)
                    .padding(6)
            }
            
            TextEditor(text: $text)
                .font(font)
                .padding(5)
                .frame(width: width, height: height)
                .multilineTextAlignment(alignment)                
        }
        .frame(width: width, height: height)
        .cornerRadius(cornerRadius)
    }
}
