//
//  PhotoViewModel.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import Observation
import PhotosUI
import SwiftUI

@MainActor
@Observable
final class PhotoViewModel {
    var isLoading = false
    var photoURLs: [URL] = []
    var lookIndex: Int = 0
    var errorMessage: String?
    
    private let store: CollectionsStore
    private let collectionID: UUID
    
    init(store: CollectionsStore, collectionID: UUID) {
        self.store = store
        self.collectionID = collectionID
        self.refreshFromDisk()
    }
    
    func refreshFromDisk() {
        self.photoURLs = store.resolvedPhotoURLs(for: collectionID)
        if photoURLs.isEmpty {
            lookIndex = 0
        } else if lookIndex >= photoURLs.count {
            lookIndex = max(0, photoURLs.count - 1)
        }
    }
    // 앨범에서 선택된 항목 처리
    func importFromPhotosPicker(_ items: [PhotosPickerItem], downsampleTo: CGFloat = 1600) async {
        guard !items.isEmpty else { return }
        defer { isLoading = false }
        
        let tempURLs = await PhotoPipeline.savePickerItemsToTempURLs(items, downsampleTo: downsampleTo)
        _ = store.addTempImageURLs(tempURLs, to: collectionID)
        refreshFromDisk()
    }
    
    // Files에서 선택된 URL 처리
    func importFromFiles(_ urls: [URL]) async {
        guard !urls.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        store.addFiles(urls, to: collectionID)
        refreshFromDisk()
    }
    
    func remove(at offsets: IndexSet) {
        store.removePhotos(at: offsets, in: collectionID)
        refreshFromDisk()
    }
    
    func deduplicate() {
        var seen = Set<String>()
        photoURLs = photoURLs.filter { url in
            if seen.contains(url.lastPathComponent) { return false }
            seen.insert(url.lastPathComponent)
            return true
        }
        if photoURLs.isEmpty {
            lookIndex = 0
        } else if lookIndex >= photoURLs.count {
            lookIndex = max(0, photoURLs.count - 1)
        }
    }
}
