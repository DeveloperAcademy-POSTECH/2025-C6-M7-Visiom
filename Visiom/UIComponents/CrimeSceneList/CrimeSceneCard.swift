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
    let occuredDate: String
    let location: String
    let status: CrimeSceneStatus

    var body: some View {
        VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 270, height: 218)
                .clipShape(RoundedRectangle(cornerRadius: 23))
                .padding(12)

            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                    Spacer()
                    Text(status.rawValue)
                        .font(.system(size: 15, weight: .regular))
                        .frame(width: 68, height: 28)
                        .background(
                            Capsule().fill(statusColor(status: status))
                        )
                }
                Spacer(minLength: 8)
                HStack {
                    Text(occuredDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            textColor()
                        )
                    Spacer()
                    Text(location)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            textColor()
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
            .frame(
                alignment: .topLeading
            )
        }

        .frame(width: 296, height: 316)
        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 35, style: .continuous)
        )
        .contentShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
        .hoverEffect()
    }
}

private func statusColor(status: CrimeSceneStatus) -> Color {
    switch status {
    case .coldcase:
        return Color(.sRGB, red: 1.0, green: 66 / 255, blue: 69 / 255)
    case .investigating:
        return Color(
            .sRGB,
            red: 208 / 255,
            green: 208 / 255,
            blue: 208 / 255,
            opacity: 128 / 255
        )
    case .solved:
        return Color(
            .sRGB,
            red: 84 / 255,
            green: 84 / 255,
            blue: 84 / 255,
        )
    }
}

private func textColor() -> Color {
    Color(.sRGB, red: 84 / 255, green: 84 / 255, blue: 84 / 255)
}
