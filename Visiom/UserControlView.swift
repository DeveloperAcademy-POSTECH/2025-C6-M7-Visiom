//
//  UserControlView.swift
//  Visiom
//
//  Created by 제하맥 on 10/23/25.
//


import SwiftUI

struct UserControlView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        HStack {
            Button {
                
            } label: {
                Text("나가기")
            }
            
            Button {

            } label: {
                Text("사진")
            }
            Button {

            } label: {
                Text("메모")
            }
            Button {

            } label: {
                Text("숫자")
            }
            Button {

            } label: {
                Text("스티커")
            }
            Button {

            } label: {
                Text("마네킹")
            }
            Button {

            } label: {
                Text("필터")
            }
            Button {

            } label: {
                Text("이동")
            }
        }
        .glassBackgroundEffect()
    }
}

#Preview(windowStyle: .automatic) {
    UserControlView()
        .environment(AppModel())
}
