//
//  PersistenceActor.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//
//  Disk I/O 담당

import Foundation

actor PersistenceActor {
    private var currentTask: Task<Void, Error>?
    private var generation: UInt64 = 0
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        
        return decoder
    }()
    
    // Disk I/O를 직렬로 처리
    func enqueueWrite<T: Codable>(_ snapshot: T, to url: URL, debounceMS: UInt64 = 120) {
        generation &+= 1
        let myGen = generation
        
        currentTask?.cancel()
        currentTask = Task(priority: .background) {
            // 디바운스
            try? await Task.sleep(nanoseconds: debounceMS * 1_000_000)
            try Task.checkCancellation()
            
            // 최신 호출인지 확인(세대 확인)
            try await self.ensureLatest(myGen)
            // 부모 디렉토리 확인
            try Self.ensureParentDirectoryExists(for: url)
            
            //인코딩
            let data = try self.encoder.encode(snapshot)
            
            // 취소 and 세대 재확인
            try Task.checkCancellation()
            try await self.ensureLatest(myGen)
            
            // 쓰기
            try data.write(to: url, options: .atomic)
        }
    }
    
    func deleteCollectionFolder(id: UUID) async throws {
        let folder = try FileLocations.collectionFolder(id: id)
        if FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.removeItem(at: folder)
        }
    }
    
    // 현재 예약된 저장이 끝날때까지 대기
    func flush() async {
        let t = currentTask
        _ = await t?.result
    }
    
    /// 파일에서 로드 후 PhotoCollection 배열로 반환
    func load<T: Decodable>(from url: URL) async throws -> T {
        if let data = try? Data(contentsOf: url) {
            return try self.decoder.decode(T.self, from: data)
        } else {
            throw CocoaError(.fileReadNoSuchFile)
        }
    }
    
    private func ensureLatest(_ myGen: UInt64) async throws {
        if myGen != generation { throw CancellationError() }
    }
    
    private static func ensureParentDirectoryExists(for url: URL) throws {
        let parentURL = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parentURL, withIntermediateDirectories: true)
    }
}
