//
//  CrimeSceneCard.swift
//  Visiom
//
//  Created by jiwon on 10/30/25.
//
import SwiftUI

struct CrimeSceneCard: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 218)
                .frame(maxWidth: .infinity)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,  // 왼쪽 위 모서리
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32  // 오른쪽 위 모서리
                    )
                )

            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .lineSpacing(5)

                Text(description)
                    .font(.system(size: 13, weight: .medium))
                    .lineSpacing(5)
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
            .padding(.leading, 26)
            .frame(maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(width: 267, height: 308)
        .glassBackgroundEffect()
        .cornerRadius(32)
        .hoverEffect()

    }
}
