//
//  TimeListView.swift
//  Visiom
//
//  Created by 윤창현 on 11/3/25.
//

import SwiftUI

// Entity 리스트 뷰
struct TimeListView: View {
    @Environment(EntityManager.self) private var entityManager
    
    @Environment(\.editMode) private var editMode
    @State private var isEditMode: Bool = false
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 0) {
                // 헤더 정보
                HStack {
                    Text("총 \(entityManager.entities.count)개")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    Button(isEditMode ? "완료" : "편집") {
                        withAnimation {
                            isEditMode.toggle()
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemGroupedBackground))
                
                // Entity 리스트
                List {
                    ForEach(entityManager.entities) { entityInfo in
                        Button(action: {
                            if !isEditMode{
                                entityManager.animateEntity(entityInfo)
                            }
                        }) {
                            HStack {
                                // Entity 타입 아이콘
                                Image(systemName: iconName(for: entityInfo.type))
                                    .foregroundColor(color(for: entityInfo.type))
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(entityInfo.name)
                                        .font(.headline)
                                    Text(typeName(for: entityInfo.type))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                if !isEditMode {
                                    Image(systemName: "play.circle")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isEditMode)
                    }
                    .onDelete { indexSet in
                        entityManager.removeEntity(at: indexSet)
                    }
                    .onMove { source, destination in
                        entityManager.moveEntity(from: source, to: destination)
                    }
                }
            }
            .environment(\.editMode, .constant(isEditMode ? .active : .inactive))
        }
        .navigationTitle("Entity 목록")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditMode && !entityManager.entities.isEmpty {
                    Button(role: .destructive) {
                        withAnimation {
                            // 모든 Entity 삭제
                            let allIndices = IndexSet(integersIn: 0..<entityManager.entities.count)
                            entityManager.removeEntity(at: allIndices)
                        }
                    } label: {
                        Label("모두 삭제", systemImage: "trash")
                    }
                }
            }
        }
    }
}

private func iconName(for type: EntityType) -> String {
    switch type {
    case .sphere: return "circle.fill"
    case .box: return "square.fill"
    }
}

private func color(for type: EntityType) -> Color {
    switch type {
    case .sphere: return .red
    case .box: return .blue
    }
}

private func typeName(for type: EntityType) -> String {
    switch type {
    case .sphere: return "구"
    case .box: return "박스"
    }
}
