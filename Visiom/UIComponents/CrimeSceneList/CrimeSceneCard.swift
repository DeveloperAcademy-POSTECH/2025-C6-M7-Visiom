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
                            Capsule()
                                .fill(
                                    status == .solved
                                        ? Color(
                                            .sRGB,
                                            red: 84 / 255,
                                            green: 84 / 255,
                                            blue: 84 / 255
                                        )  // #5E5E5E21
                                        : status == .investigating
                                            ? Color(
                                                .sRGB,
                                                red: 208.0 / 255.0,
                                                green: 208.0 / 255.0,
                                                blue: 208.0 / 255.0,
                                                opacity: 128.0 / 255.0
                                            )  // #D0D0D080
                                            : Color(
                                                .sRGB,
                                                red: 255.0 / 255.0,
                                                green: 66.0 / 255.0,
                                                blue: 69.0 / 255.0,
                                                opacity: 1.0
                                            )  // #FF4245
                                )
                        )
                }
                Spacer(minLength: 8)
                HStack {
                    Text(occuredDate)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            Color(
                                .sRGB,
                                red: 84 / 255,
                                green: 84 / 255,
                                blue: 84 / 255
                            )
                        )
                    Spacer()
                    Text(location)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(
                            Color(
                                .sRGB,
                                red: 84 / 255,
                                green: 84 / 255,
                                blue: 84 / 255
                            )
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
