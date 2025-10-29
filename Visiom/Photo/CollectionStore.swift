//
//  CollectionStore.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class CollectionStore {
    var collections: [PhotoCollection] = []
    
    init() {
        Task { await load() }
    }
    
    func load() async {
        do {
            let url = try FileLocations.collectionsIndexFile()
            if let data = try? Data(contentsOf: url) {
                let decoded = try JSONDecoder().decode([PhotoCollection].self, from: data)
                self.collections = decoded
            } else {
                self.collections = []
            }
        } catch {
            print("Load collections error:", error)
            self.collections = []
        }
    }
    
    private func persist() {
        let snapshot = self.collections
        let url = try? FileLocations.collectionsIndexFile()
        guard let url else { return }
        
        Task.detached{
            do {
                let data = try JSONEncoder().encode(snapshot)
                try data.write(to: url, options: .atomic)
            } catch {
                print("Persist collections error:", error)
            }
        }
    }
    
    // MARK: - CRUD
    @discardableResult
    func createCollection(title: String? = nil) -> PhotoCollection {
        let defaultTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = (defaultTitle?.isEmpty == false) ? defaultTitle! : "컬렉션 \(collections.count + 1)"
        let col = PhotoCollection(title: name)
        collections.insert(col, at: 0)
        persist()
        return col
    }
    
    func deleteCollection(_ id: UUID) {
        guard let idx = collections.firstIndex(where: { $0.id == id }) else { return }
        do {
            let folder = try FileLocations.collectionFolder(id: id)
            if FileManager.default.fileExists(atPath: folder.path) {
                try FileManager.default.removeItem(at: folder)
            }
        } catch {
            print("Delete folder error:", error)
        }
        collections.remove(at: idx)
        persist()
    }
    
    func renameCollection(_ id: UUID, to newTitle: String) {
        guard let idx = collections.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        collections[idx].title = newTitle
        persist()
    }
    
    func collection(with id: UUID) -> PhotoCollection? {
        collections.first(where: { $0.id == id })
    }
    
    
    /// URL → 컬렉션 폴더로 복사 → 파일명 반환
    private func copyFile(to folder: URL, from src: URL) -> String? {
        let ext = src.pathExtension.isEmpty ? "jpg" : src.pathExtension
        let fileName = UUID().uuidString + "." + ext
        let dest = folder.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: dest.path) {
                try FileManager.default.removeItem(at: dest)
            }
            try FileManager.default.copyItem(at: src, to: dest)
            return fileName
        } catch {
            print("Copy file error:", error)
            return nil
        }
    }
    
    /// 파일 선택 URL들을 컬렉션 폴더에 저장
    func addFiles(_ urls: [URL], to collectionID: UUID) {
        guard var col = collection(with: collectionID) else { return }
        do {
            let folder = try FileLocations.collectionFolder(id: collectionID)
            var newNames: [String] = []
            for src in urls {
                let ok = src.startAccessingSecurityScopedResource()
                defer { if ok { src.stopAccessingSecurityScopedResource() } }
                if let name = copyFile(to: folder, from: src) {
                    newNames.append(name)
                }
            }
            col.photoFileNames.append(contentsOf: newNames)
            update(col)
        } catch {
            print("AddFiles error:", error)
        }
    }
    
    @discardableResult
    func addTempImageURLs(_ tempURLs: [URL], to collectionID: UUID) -> [String] {
        guard var col = collection(with: collectionID) else { return [] }
        do {
            let folder = try FileLocations.collectionFolder(id: collectionID)
            var newNames: [String] = []
            for src in tempURLs {
                if let name = copyFile(to: folder, from: src) {
                    newNames.append(name)
                }
            }
            col.photoFileNames.append(contentsOf: newNames)
            update(col)
            return newNames
        } catch {
            print("AddTempImageURLs error:", error)
            return []
        }
    }
    
    func removePhotos(at offsets: IndexSet, in collectionID: UUID) {
        guard var col = collection(with: collectionID) else { return }
        do {
            let folder = try FileLocations.collectionFolder(id: collectionID)
            
            for i in offsets.sorted(by: >) { // 높은 인덱스부터
                let name = col.photoFileNames[i]
                let path = folder.appendingPathComponent(name)
                try? FileManager.default.removeItem(at: path)
                col.photoFileNames.remove(at: i) //수정
            }
            
            update(col)
        } catch {
            print("Remove photos error:", error)
        }
    }
    
    private func update(_ updated: PhotoCollection) {
        if let idx = collections.firstIndex(where: { $0.id == updated.id }) {
            collections[idx] = updated
            persist()
        }
    }
    
    // 컬렉션 내 파일명 → 절대 URL 배열
    func resolvedPhotoURLs(for collectionID: UUID) -> [URL] {
        guard let col = collection(with: collectionID),
              let folder = try? FileLocations.collectionFolder(id: collectionID) else { return [] }
        return col.photoFileNames.map { folder.appendingPathComponent($0) }
    }
}
