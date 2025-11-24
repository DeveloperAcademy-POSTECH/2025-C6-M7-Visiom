//
//  PhotoCollectionContent.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import Observation
import SwiftUI

struct PhotoCollectionContent: View {
    var photoViewModel: PhotoViewModel

    var body: some View {
        @Bindable var photoViewModel = photoViewModel

        if photoViewModel.photoURLs.isEmpty {
            PhotoEmptyView()
        } else {
            ImageGalleryView(
                urls: photoViewModel.photoURLs,
                collectionID: photoViewModel.id,
                selectedIndex: $photoViewModel.lookIndex,
                previewSize: .init(width: 1143, height: 419),
                thumbnailSize: .init(width: 284, height: 186),
                thumbnailSpacing: 8
            )
            .id(photoViewModel.photoURLs.count)
        }
    }
}
