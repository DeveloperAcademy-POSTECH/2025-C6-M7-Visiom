//
//  PhotoCollectionView.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import PhotosUI
import SwiftUI
import Observation

struct PhotoCollectionView: View {
    @Environment(CollectionsStore.self) var collectionStore
    @State private var photoViewModel: PhotoViewModel?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    
    let collectionID: UUID
    
    var body: some View {
        NavigationStack {
            Group {
                if let photoViewModel {
                    PhotoCollectionContent(photoViewModel: photoViewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("사진 보기")
            .toolbar { importToolbar }
            .overlay{
                if let photoViewModel, photoViewModel.isLoading {
                    LoadingOverlay()
                } }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: 0,
            matching: .images
        )
        .onChange(of: pickerItems) { newItems in
            Task {
                if let photoViewModel {
                    await photoViewModel.importFromPhotosPicker(newItems)
                }
                pickerItems.removeAll()
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.jpeg, .png, .heic, .tiff],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result {
                Task {
                    if let photoViewModel {
                        await photoViewModel.importFromFiles(urls)
                    }
                }
                
            }
        }
        .task(id: collectionID) {
            if photoViewModel == nil {
                photoViewModel = PhotoViewModel(store: collectionStore, collectionID: collectionID)
            }
        }
    }
    
    // MARK: - Toolbar
    private var importToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            PhotoImportMenuButton(
                onPickFiles: { showFileImporter = true },
                onPickAlbum: { showPhotoPicker = true }
            )
        }
    }
}

private struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.02).ignoresSafeArea()
            ProgressView().controlSize(.large)
        }
        .transition(.opacity)
    }
}
