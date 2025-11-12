////
////  RoomEntity.swift
////  Visiom
////
////  Created by 윤창현 on 10/28/25.
////
//import SwiftUI
//import RealityKit
//import RealityKitContent
//
//class RoomEntity: Entity {
//
//    // MARK: - Sub-entities
//
//    /// room 모델
//    private var room: Entity = Entity()
//
//
//    // MARK: - Internal state
//
//
//    // MARK: - Initializers
//    @MainActor required init() {
//        super.init()
//    }
//
//    /// 새로운 Entity를 init
//    /// - Parameters:
//    ///   - configuration: 룸 Entity 설정 정보.
//    init(
//        configuration: Configuration,
//    ) async {
//        super.init()
//        
//        guard let room = await entity(named: "room")
//        else {return}
//        
//        self.room = room
//        
//        self.addChild(room)
//    }
//
//    // MARK: - Updates
//    func update () {
////        move(to: <#T##Transform#>, relativeTo: <#T##Entity?#>)
////        component.set()
//        
//    }
//    
//    // MARK: - Entity load
//    public func entity(named name: String) async -> Entity? {
//        do {
////            return try await Entity(named: name, in: realityKitContentBundle)
//            if let localURL = Bundle.main.url(forResource: name, withExtension: "usdz") {
//                           return try await Entity(contentsOf: localURL)
//                       } else {
//                           print("❌ Local entity file not found in main bundle: \(name).usdz")
//                           return nil
//                       }
//
//        } catch is CancellationError {
//            // entity 초기화시 발생하는 에러 처리 모델이 로드전 RealityView disappears 단계에서 종료
//            return nil
//
//        } catch let error {
//            // 다른 에러 표시
//            fatalError("Failed to load \(name): \(error)")
//        }
//    }
//
//}
//
//
//
