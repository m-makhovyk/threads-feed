import Foundation
import AVFoundation
import CryptoKit
import CachingPlayerItem

final class VideoCacheClient {

  static let shared = VideoCacheClient()

  private let diskCache: DiskCache

  init(diskCache: DiskCache = DiskCache(folderName: "VideoCache")) {
    self.diskCache = diskCache
  }

  func makePlayerItem(for url: URL) -> AVPlayerItem {
    let key = cacheKey(for: url)

    if let cachedURL = diskCache.fileURL(key: key) {
      return AVPlayerItem(url: cachedURL)
    }

    let fileExtension = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
    let tempPath = diskCache.makeTempPath(fileExtension: fileExtension)
    let item = CachingPlayerItem(
      url: url,
      saveFilePath: tempPath,
      customFileExtension: fileExtension
    )
    let handler = CachingHandler(diskCache: diskCache, key: key)
    item.delegate = handler
    // Strong reference so the handler outlives the item even though `delegate` is weak.
    item.passOnObject = handler
    return item
  }

  private func cacheKey(for url: URL) -> String {
    let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
    return digest.map { String(format: "%02x", $0) }.joined()
  }
}

private final class CachingHandler: NSObject, CachingPlayerItemDelegate {

  private let diskCache: DiskCache
  private let key: String

  init(diskCache: DiskCache, key: String) {
    self.diskCache = diskCache
    self.key = key
    super.init()
  }

  func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingFileAt filePath: String) {
    diskCache.finalize(tempPath: filePath, key: key)
  }
}
