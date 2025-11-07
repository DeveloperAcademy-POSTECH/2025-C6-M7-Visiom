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
        VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 218)
                .frame(maxWidth: .infinity)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 32,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 32
                    )
                )
                .clipped()

            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))

                Text(description)
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.top, 12)
            .padding(.horizontal, 26)
            .padding(.bottom, 26)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }

        .frame(width: 267, height: 308)

        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(.clear)
        )

        .clipShape(RoundedRectangle(cornerRadius: 32))
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .glassBackgroundEffect()
        .contentShape(RoundedRectangle(cornerRadius: 32))
        .hoverEffect()
    }
}
