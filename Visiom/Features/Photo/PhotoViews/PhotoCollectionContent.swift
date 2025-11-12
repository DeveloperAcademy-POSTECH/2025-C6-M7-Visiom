//
//  PhotoCollectionContent.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import SwiftUI
import Observation

struct PhotoCollectionContent: View {
    var photoViewModel: PhotoViewModel
    
    var body: some View {
        @Bindable var photoViewModel = photoViewModel
        
        if photoViewModel.photoURLs.isEmpty {
            PhotoEmptyView()
        } else {
            ImageGalleryView(
                urls: photoViewModel.photoURLs,
                selectedIndex: $photoViewModel.lookIndex,
                previewSize: .init(width: 1143, height: 419),
                thumbnailSize: .init(width: 156, height: 110),
                thumbnailSpacing: 8
            )
            .id(photoViewModel.photoURLs.count)
        }
    }
}
