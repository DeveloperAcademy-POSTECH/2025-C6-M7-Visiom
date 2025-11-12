//
//  TeleportNotifications.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  Reality Kit 내부에서 발생한 텔레포트 요청을 시스템에 알려주는 Notification
//

import Foundation
import RealityKit
import simd

public extension Notification.Name {
    // 이벤트 이름 등록
    static let didRequestTeleport = Notification.Name("Visiom.didRequestTeleport")
}
