//
//  MemoEditView.swift
//  Visiom
//
//  Created by Elphie on 10/30/25.
//

import SwiftUI

struct MemoEditView: View {
    @Environment(AppModel.self) var appModel
    @Environment(MemoStore.self) var memoStore
    @Environment(\.dismissWindow) private var dismissWindow

    let memoID: UUID

    private var textBinding: Binding<String> {
        Binding(
            get: { memoStore.memo(id: memoID)?.text ?? "" },
            set: { memoStore.updateText(id: memoID, to: $0) }
        )
    }

    var body: some View {
        ZStack {
            Color(red: 0.35, green: 0.69, blue: 1)
                .ignoresSafeArea()
            VStack {
                MultilineTextFieldAttachmentView(
                    text: textBinding,
                    placeholder: "메모를 입력하세요",
                    width: 525,
                    height: 440,
                    font: .system(size: 48),
                    cornerRadius: 0,
                )
                .background(Color.clear)

                Button("작성 완료") {
                    if memoStore.commit(id: memoID) {
                        appModel.memoToAnchorID = memoID
                        dismissWindow(id: appModel.memoEditWindowID)
                    }
                }
            }
        }
    }
}
