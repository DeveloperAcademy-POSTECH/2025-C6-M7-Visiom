//
//  CrimeSceneLoadingView.swift
//  Visiom
//
//  Created by jiwon on 11/7/25.
//

import SwiftUI

struct CrimeSceneLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image("icon")
                .resizable()
                .frame(width: 52, height: 52)

            Text("사건 현장 불러오는 중...")
                .font(.title3)
                .foregroundStyle(.white)

            ProgressView()
                .progressViewStyle(.linear)
                .foregroundStyle(.white)
                .frame(width: 228)
        }
        .padding(.vertical, 40)
        .padding(.horizontal, 50)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}
