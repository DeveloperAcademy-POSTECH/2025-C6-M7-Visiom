//
//  MemoEditView.swift
//  Visiom
//
//  Created by Elphie on 10/30/25.
//

import SwiftUI

struct MemoEditView: View {
    @Environment(MemoStore.self) var memoStore
    @Environment(AppModel.self) var appModel
    @Environment(\.dismissWindow) private var dismissWindow
    
    let memoID: UUID
    
    private var textBinding: Binding<String> {
        Binding(
            get: { memoStore.memo(id: memoID)?.text ?? "" },
            set: { memoStore.updateText(id: memoID, to: $0) }
        )
    }
    
    var body: some View {
        TextFieldAttachmentView(
            text: textBinding
        )
        Button("작성 완료") {
            if memoStore.commit(id: memoID) {
                dismissWindow(id: appModel.memoEditWindowID)
            }
        }
    }
}
