//
//  PhotoPipeline.swift
//  Visiom
//
//  Created by Elphie on 10/29/25.
//
// 이미지 디코딩, 다운샘플, 캐싱 함수를 정의하는 enum

import Foundation
import ImageIO
import PhotosUI
import UIKit
import SwiftUI

enum PhotoPipeline {
    private static let cache = NSCache<NSURL, UIImage>()
    
    // 앨범에서 고른 원본들을 임시 저장
    static func savePickerItemsToTempURLs(_ items: [PhotosPickerItem],
                                          downsampleTo maxDim: CGFloat? = 1600) async -> [URL] {
        let tempDir = FileManager.default.temporaryDirectory
        var result: [URL] = []
        
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                
                let finalData: Data
                if let maxDim, let downsized = downsample(data: data, maxDimension: maxDim) {
                    finalData = downsized
                } else {
                    finalData = data
                }
                
                // 확장자 추정(간단 처리: jpeg로 저장)
                let url = tempDir.appendingPathComponent("\(UUID().uuidString).jpg")
                try finalData.write(to: url, options: .atomic)
                result.append(url)
            } catch {
                print("Save error: \(error)")
            }
        }
        return result
    }
    
    /// 앨범에서 고른 이미지를 JPEG로 인코딩
    static func downsample(data: Data, maxDimension: CGFloat) -> Data? {
        let opts: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let src = CGImageSourceCreateWithData(data as CFData, opts as CFDictionary) else { return nil }
        
        let downOpts: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension)
        ]
        guard let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, downOpts as CFDictionary) else { return nil }
        let ui = UIImage(cgImage: cg)
        return ui.jpegData(compressionQuality: 0.9)
    }
    
    // 이미지 url을 캐시에서 조회, 없는 경우 이미지를 다운샘플해서 반환
    static func image(for url: URL, targetSize: CGSize, scale: CGFloat) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let img = downsampledUIImage(at: url, to: targetSize, scale: scale) else { return nil }
        cache.setObject(img, forKey: url as NSURL)
        return img
    }
    
    // 이미지를 다운샘플하여 썸네일 생성
    private static func downsampledUIImage(at url: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage? {
        let maxDimension = max(pointSize.width, pointSize.height) * max(1, scale)
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Int(maxDimension),
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        guard
            let src = CGImageSourceCreateWithURL(url as CFURL, nil),
            let cgThumb = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary)
        else { return nil }
        return UIImage(cgImage: cgThumb)
    }
}
