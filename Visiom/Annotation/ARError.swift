////
////  ARError.swift
////  Visiom
////
////  Created by 윤창현 on 10/31/25.
////
//
//import Foundation
//
///// AR 작업 중 발생 가능한 에러
//enum ARError: LocalizedError {
//    case handTrackingNotSupported
//    case worldTrackingNotSupported
//    case sessionStartFailed(String)
//    case invalidAnchorID
//    case anchorNotFound(UUID)
//    case collectionNotFound(UUID)
//    case anchorCreationFailed(String)
//    case anchorRemovalFailed(String)
//    case permissionDenied(String)
//    case unknown(String)
//    
//    var errorDescription: String? {
//        switch self {
//        case .handTrackingNotSupported:
//            return "이 디바이스는 손 추적을 지원하지 않습니다."
//        case .worldTrackingNotSupported:
//            return "이 디바이스는 월드 추적을 지원하지 않습니다."
//        case .sessionStartFailed(let reason):
//            return "AR 세션 시작 실패: \(reason)"
//        case .invalidAnchorID:
//            return "유효하지 않은 앵커 ID입니다."
//        case .anchorNotFound(let id):
//            return "앵커를 찾을 수 없습니다: \(id)"
//        case .collectionNotFound(let id):
//            return "컬렉션을 찾을 수 없습니다: \(id)"
//        case .anchorCreationFailed(let reason):
//            return "앵커 생성 실패: \(reason)"
//        case .anchorRemovalFailed(let reason):
//            return "앵커 삭제 실패: \(reason)"
//        case .permissionDenied(let permission):
//            return "\(permission) 권한이 거부되었습니다."
//        case .unknown(let message):
//            return "알 수 없는 오류: \(message)"
//        }
//    }
//    
//    var recoverySuggestion: String? {
//        switch self {
//        case .handTrackingNotSupported, .worldTrackingNotSupported:
//            return "더 새로운 기기를 사용하세요."
//        case .sessionStartFailed:
//            return "앱을 다시 시작하세요."
//        case .permissionDenied:
//            return "설정에서 권한을 허용하세요."
//        default:
//            return "다시 시도하세요."
//        }
//    }
//}
//
///// AR 작업 결과 타입
//typealias ARResult<T> = Result<T, ARError>
