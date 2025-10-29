//
//  PhotoCollectionListView.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

// 임시 view
// 버튼을 공간에 배치하는 기능을 대신하는 list view
// 공간에 배치될 PhotoCollectionButton을 list보여주는 view
// 추후 기능 연결 후 삭제 필수

import SwiftUI

struct PhotoCollectionListView: View {
    @Environment(CollectionStore.self) var collectionStore
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(collectionStore.collections) { col in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(col.title).font(.headline)
                            Text("\(col.photoFileNames.count)장 · \(col.createdAt.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        // 공간 버튼의 동작
                        Button("열기") {
                            openWindow(id: appModel.photoCollectionWindowID, value: col.id)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("컬렉션")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // 컬렉션을 생성하는 동작
                    Button {
                        let newCol = collectionStore.createCollection()
                        collectionStore.renameCollection(newCol.id, to: newCol.id.uuidString)
                        openWindow(id: "PhotoCollectionWindow", value: newCol.id)
                    } label: {
                        Label("새 컬렉션", systemImage: "plus")
                    }
                }
            }
        }
    }
    
    // 컬렉션 삭제 함수
    private func delete(at offsets: IndexSet) {
        offsets
            .map { collectionStore.collections[$0].id }
            .forEach(collectionStore.deleteCollection)
    }
}
