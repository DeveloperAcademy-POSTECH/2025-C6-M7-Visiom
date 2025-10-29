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
    @Environment(CollectionStore.self) var collectionStore
    @State private var photoViewModel: PhotoViewModel?
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    @State private var importErrorMessage: String? = nil
    
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
            .overlay {
                if let photoViewModel, photoViewModel.isLoading {
                    LoadingOverlay()
                }
            }
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: 0,
            matching: .images
        )
        .onChange(of: pickerItems) { newItems in
            importFromPhotos(newItems)
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.jpeg, .png, .heic, .tiff],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                guard !urls.isEmpty else { return }
                importFromFiles(urls)
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == NSUserCancelledError { return }
                importErrorMessage = nsError.localizedDescription
            }
        }
        // 실패 알림
        .alert("가져오기 실패", isPresented: Binding(
            get: { importErrorMessage != nil },
            set: { if !$0 { importErrorMessage = nil } }
        )) {
            Button("확인", role: .cancel) { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "알 수 없는 오류가 발생했습니다.")
        }
        .task(id: collectionID) {
            if photoViewModel == nil {
                photoViewModel = PhotoViewModel(store: collectionStore, collectionID: collectionID)
            }
        }
    }
    
    private func importFromPhotos(_ items: [PhotosPickerItem]) {
        Task {
            if let photoViewModel = photoViewModel {
                await photoViewModel.importFromPhotosPicker(items)
            } else {
                importErrorMessage = "뷰를 준비 중입니다. 잠시 후 다시 시도해주세요."
            }
            pickerItems.removeAll()
        }
    }
    
    private func importFromFiles(_ urls: [URL]) {
        Task {
            if let photoViewModel = photoViewModel {
                await photoViewModel.importFromFiles(urls)
            } else {
                importErrorMessage = "뷰를 준비 중입니다. 잠시 후 다시 시도해주세요."
            }
        }
    }
    
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
