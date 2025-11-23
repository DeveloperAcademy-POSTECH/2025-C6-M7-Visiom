//
//  SeletedImageView.swift
//  Visiom
//
//  Created by jiwon on 11/23/25.
//

import SwiftUI

struct SeletedImageView: View {
    let url: URL
    let collectionID: UUID

    @Environment(AppModel.self) var appModel
    @Environment(PlacedImageStore.self) var placedImageStore

    var body: some View {
        VStack {
            Divider()
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .frame(width: 990, height: 557)

                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 990, height: 557)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                } placeholder: {
                    ProgressView()
                }
            }
            .padding(.bottom, 7)
            .padding(.bottom, 20)
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    print("삭제 버튼 클릭됨")
                } label: {
                    Text("삭제")
                        .font(.system(size: 19, weight: .bold))

                }
                .glassBackgroundEffect()

                Button {
                    let fileName = url.lastPathComponent
                    let placedImage = placedImageStore.createPlacedImage(
                        imageFileName: fileName,
                        from: collectionID
                    )
                    placedImageStore.placedImageToAnchorID = placedImage.id
                    appModel.itemAdd = .placedImage
                } label: {
                    Text("공간에 추가")
                        .font(.system(size: 19, weight: .bold))
                }
                .glassBackgroundEffect()
                .padding(.trailing, 30)
                .padding(.leading, 10)
            }
        }
    }
}
