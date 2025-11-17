//
//  FileLocations.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import Foundation
import UniformTypeIdentifiers

enum FileLocations {
    @discardableResult
    private static func ensureDirectory(_ url: URL) throws -> URL {
        let fm = FileManager.default
        if !fm.fileExists(atPath: url.path) {
            try fm.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }
    
    static func appSupportDir() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        
        let appComponent =
        Bundle.main.bundleIdentifier
        ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String)
        ?? ProcessInfo.processInfo.processName
        
        let appDir = base.appendingPathComponent(appComponent, isDirectory: true)
        
        return try ensureDirectory(appDir)
    }
    
    static func collectionsRoot() throws -> URL {
        let root = try appSupportDir().appendingPathComponent("Collections", isDirectory: true)
        let fm = FileManager.default
        if !fm.fileExists(atPath: root.path) {
            try fm.createDirectory(at: root, withIntermediateDirectories: true)
        }
        return root
    }
    
    static func collectionFolder(id: UUID) throws -> URL {
        let folder = try collectionsRoot().appendingPathComponent(id.uuidString, isDirectory: true)
        let fm = FileManager.default
        if !fm.fileExists(atPath: folder.path) {
            try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }
    
    static func collectionsIndexFile() throws -> URL {
        try appSupportDir().appendingPathComponent("collections.json", conformingTo: .json)
    }
    
    static func memosIndexFile() throws -> URL {
        try appSupportDir().appendingPathComponent("memos.json", conformingTo: .json)
    }
    
    static func timelinesIndexFile() throws -> URL {
        try appSupportDir().appendingPathComponent("timelines.json", conformingTo: .json)
    }
}
