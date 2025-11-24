//
//  PhotoImporterMenuButton.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import SwiftUI

struct PhotoImportMenuButton: View {
    let cornerRadius: CGFloat = 100
    let paddingHorizontal: CGFloat = 18
    let paddingVertical: CGFloat = 8

    let pickFilesButtonTitle: String = "파일에서 선택"
    let pickAlbumButtonTitle: String = "앨범에서 선택"
    let pickButtonSystemImageName: String = "chevron.right"
    let menuButtonTitle: String = "사진 불러오기"
    let menuButtonSystemImageName: String = "plus.rectangle.on.rectangle"

    var onPickFiles: () -> Void
    var onPickAlbum: () -> Void

    var body: some View {
        Menu {
            Section(menuButtonTitle) {
                Button(action: onPickFiles) {
                    Label(
                        pickFilesButtonTitle,
                        systemImage: pickButtonSystemImageName
                    )
                }
                Button(action: onPickAlbum) {
                    Label(
                        pickAlbumButtonTitle,
                        systemImage: pickButtonSystemImageName
                    )
                }
            }
        } label: {
            Text(menuButtonTitle).font(.system(size: 19, weight: .bold))
                .padding(.horizontal, paddingHorizontal)
                .padding(.vertical, paddingVertical)
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .glassBackgroundEffect()
                }
        }
    }
}

#Preview {
    PhotoImportMenuButton(onPickFiles: {}, onPickAlbum: {})
}
