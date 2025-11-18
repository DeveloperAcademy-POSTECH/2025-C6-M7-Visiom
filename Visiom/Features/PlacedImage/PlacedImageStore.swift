//
//  PlacedImageStore.swift
//  Visiom
//
//  Created by Elphie on 11/18/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class PlacedImageStore {
    private let persistence = PersistenceActor()
    var placedImages: [PlacedImage] = []
    
    init() {
        Task { await load() }
    }
    
    func load() async {
        do {
            let url = try FileLocations.placedImagesIndexFile()
            let decoded: [PlacedImage] = try await persistence.load(from: url)
            self.placedImages = decoded
        } catch {
            print("Load PlacedImages error:", error)
            self.placedImages = []
        }
    }
    
    private func scheduleSave() {
        let snapshot = self.placedImages
        guard let url = try? FileLocations.placedImagesIndexFile() else { return }
        Task {
            await persistence.enqueueWrite(snapshot, to: url)
        }
    }
    
    func flushSaves() async {
        await persistence.flush()
    }
    
    // MARK: - CRUD
    // Create
    @discardableResult
    func createPlacedImage(imageFileName: String,
                           from sourceCollectionID: UUID) -> PlacedImage {
        let item = PlacedImage(
            imageFileName: imageFileName,
            sourcePhotoCollectionID: sourceCollectionID
        )
        placedImages.append(item)
        scheduleSave()
        return item
    }
    
    // Read
    func placedImage(with id: UUID) -> PlacedImage? {
        placedImages.first(where: { $0.id == id })
    }
    
    /// 특정 PhotoCollection에서 온 것만 Read
    func placedImages(from sourceCollectionID: UUID) -> [PlacedImage] {
        placedImages.filter { $0.sourcePhotoCollectionID == sourceCollectionID }
    }
    
    // Delete
    func deletePlacedImage(id: UUID) {
        guard let index = placedImages.firstIndex(where: { $0.id == id }) else { return }
        placedImages.remove(at: index)
        scheduleSave()
    }
    
    /// 특정 컬렉션에서 파생된 PlacedImage를 모두 Delete
    func removeAll(from sourceCollectionID: UUID) {
        let originalCount = placedImages.count
        placedImages.removeAll { $0.sourcePhotoCollectionID == sourceCollectionID }
        if placedImages.count != originalCount {
            scheduleSave()
        }
    }
}
