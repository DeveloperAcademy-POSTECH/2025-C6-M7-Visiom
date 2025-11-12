//
//  PersistenceManager.swift
//  Visiom
//
//  Created by Elphie on 11/5/25.
//
//  Anchor Record의 단일 저장/복원 책임자

import Foundation
import simd

@MainActor
public final class PersistenceManager {
    private let url: URL
    private let anchorRegistry: AnchorRegistry
    
    public init(filename: String = "AnchorRegistry.json",
                anchorRegistry: AnchorRegistry) {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.url = dir.appendingPathComponent(filename)
        self.anchorRegistry = anchorRegistry
    }
    
    public func save() {
        let all = anchorRegistry.all()
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let data = try enc.encode(all)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Persistence save error:", error)
        }
    }
    
    public func load() -> [AnchorRecord] {
        do {
            let data = try Data(contentsOf: url)
            let dec = JSONDecoder()
            return try dec.decode([AnchorRecord].self, from: data)
        } catch {
            return []
        }
    }
}
