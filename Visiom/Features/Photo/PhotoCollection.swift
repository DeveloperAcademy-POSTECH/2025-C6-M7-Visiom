//
//  PhotoCollection.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//

import Foundation

struct PhotoCollection: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    let createdAt: Date
    var photoFileNames: [String]

    init(id: UUID = UUID(), title: String, createdAt: Date = .now, photoFileNames: [String] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.photoFileNames = photoFileNames
    }
}
