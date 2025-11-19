//
//  Height.swift
//  Visiom
//
//  Created by jiwon on 11/18/25.
//

import SwiftUI

struct CameraHeightView: View {

    @Environment(AppModel.self) var appModel
    @State private var userHeight: Int = 160

    let heights = Array(110...190).map { $0 }

    var body: some View {
        HStack {
            Picker("", selection: $userHeight) {
                ForEach(heights, id: \.self) { height in
                    Text("\(height)")
                        .font(.system(size: 29, weight: .semibold))
                        .tag(heighㅎt)
                }
            }
            .frame(width: 64, height: 236)
            .clipped()
            .pickerStyle(.wheel)
            .padding(.trailing, 16)
            .onChange(of: userHeight) { newValue in
                let meter = Float(newValue) / 100
                appModel.customHeight = meter
                print("시점 높이 변경: \(meter)m")
            }
            //            Slider(value: $userHeight, in: 1.1...1.9, step: 0.01) {
            //            } minimumValueLabel: {
            //                Text("1.1m")
            //            } maximumValueLabel: {
            //                Text("1.9m")
            //            } onEditingChanged: { editing in
            //                if editing == false {
            //                    appModel.customHeight = userHeight
            //                    print(
            //                        "시점 높이 변경: \(String(format: "%.2f", userHeight))m"
            //                    )
            //                }
            //            }

            Text("CM").font(.system(size: 29, weight: .semibold))
        }
    }
}

#Preview {
    CameraHeightView()
        .environment(AppModel())
        .frame(width: 207, height: 236)
        .background(.red)
}
