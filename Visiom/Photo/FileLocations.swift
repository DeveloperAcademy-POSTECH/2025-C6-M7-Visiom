//
//  FileLocations.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import Foundation
import UniformTypeIdentifiers

enum FileLocations {
    static func appSupportDir() throws -> URL {
        let fm = FileManager.default
        let base = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let appDir = base.appendingPathComponent("Visiom", isDirectory: true) // TODO : 앱이름 혹은 Bundle로 변경
        if !fm.fileExists(atPath: appDir.path) {
            try fm.createDirectory(at: appDir, withIntermediateDirectories: true)
        }
        return appDir
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
}
