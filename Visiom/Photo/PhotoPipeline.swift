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
    private static let tempSubdir = "VisiomPicker"
    
    private static let cache: NSCache<NSURL, UIImage> = {
        let c = NSCache<NSURL, UIImage>()
        c.totalCostLimit = 100 * 1024 * 1024
        c.countLimit = 200
        return c
    }()
    
    private static func ensureTempDir() throws -> URL {
        let base = FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent(tempSubdir, isDirectory: true)
        let fm = FileManager.default
        if !fm.fileExists(atPath: dir.path) {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    // 앨범에서 고른 원본들을 임시 저장
    static func savePickerItemsToTempURLs(_ items: [PhotosPickerItem],
                                          downsampleTo maxDim: CGFloat? = 1600) async -> [URL] {
        let tempDir: URL
        do { tempDir = try ensureTempDir() } catch { return [] }
        
        var result: [URL] = []
        
        for item in items {
            do {
                guard let data = try await item.loadTransferable(type: Data.self) else { continue }
                let finalData = (maxDim.flatMap { downsample(data: data, maxDimension: $0) }) ?? data
                
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
    
    // 임시저장 폴더 정리 함수
    static func cleanupTempFiles(olderThan age: TimeInterval = 24 * 60 * 60) {
        // age=24h 기본: 필요에 따라 조정
        let fm = FileManager.default
        guard let dir = try? ensureTempDir(),
              let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles]) else { return }
        
        let cutoff = Date().addingTimeInterval(-age)
        for url in files {
            do {
                let values = try url.resourceValues(forKeys: [.contentModificationDateKey])
                let mdate = values.contentModificationDate ?? Date.distantPast
                if mdate < cutoff {
                    try fm.removeItem(at: url)
                }
            } catch {
                // 개별 삭제 실패는 무시 (로그만)
                print("Temp cleanup error:", error)
            }
        }
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
    
    // 대략적인 바이트수(cost) 계산
    private static func cost(of image: UIImage) -> Int {
        if let cg = image.cgImage {
            return cg.bytesPerRow * cg.height
        }
        let pxW = Int(image.size.width * image.scale)
        let pxH = Int(image.size.height * image.scale)
        return pxW * pxH * 4
    }
    
    // 이미지 url을 캐시에서 조회, 없는 경우 이미지를 다운샘플해서 반환
    static func image(for url: URL, targetSize: CGSize, scale: CGFloat) -> UIImage? {
        if let cached = cache.object(forKey: url as NSURL) { return cached }
        guard let img = downsampledUIImage(at: url, to: targetSize, scale: scale) else { return nil }
        cache.setObject(img, forKey: url as NSURL, cost: cost(of: img))
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
