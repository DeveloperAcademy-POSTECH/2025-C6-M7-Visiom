//
//  PlacedImage.swift
//  Visiom
//
//  Created by Elphie on 11/18/25.
//

import Foundation

struct PlacedImage: Identifiable, Codable, Equatable {
    let id: UUID
    let imageFileName: String
    let sourcePhotoCollectionID: UUID
    let createdAt: Date

    init(
        id: UUID = UUID(),
        imageFileName: String,
        sourcePhotoCollectionID: UUID,
        createdAt: Date = .now
    ) {
        self.id = id
        self.imageFileName = imageFileName
        self.sourcePhotoCollectionID = sourcePhotoCollectionID
        self.createdAt = createdAt
    }
}
