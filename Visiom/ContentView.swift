//
//  ContentView.swift
//  Visiom
//
//  Created by 윤창현 on 9/29/25.
//

import SwiftUI
ㅅ
// TODO : extension 파일로 옮길 예정
extension Image {
  init(resource name: String, ofType type: String) {
    guard let path = Bundle.main.path(forResource: name, ofType: type),
          let image = UIImage(contentsOfFile: path) else {
      self.init(name)
      return
    }
    self.init(uiImage: image)
  }
}

struct ContentView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        VStack(alignment: .trailing) {
            if appModel.immersiveSpaceState == .open {
                EmptyView()
            } else {
                Image(resource: "environment", ofType: "png")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .glassBackgroundEffect()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomOrnament) {
                VStack(spacing: 12) {
                    ToggleImmersiveSpaceButton()
                    
                    if appModel.immersiveSpaceState == .open {
                        Button(action: {
                            appModel.toggleMarkers()
                        }) {
                            Label(appModel.markersVisible ? "마커 숨기기" : "마커 보이기",
                                  systemImage: appModel.markersVisible ? "eye.slash.fill" : "eye.fill")
                        }
                    }
                    
                    Text("바닥의 파란색 원을 탭하여 텔레포트")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
