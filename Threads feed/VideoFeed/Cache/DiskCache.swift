import Foundation

nonisolated final class DiskCache: @unchecked Sendable {

  private static let cachedFileExtension = "mp4"

  private struct File {
    static let metadataKeys: Set<URLResourceKey> = [
      .contentAccessDateKey,
      .fileSizeKey
    ]

    let url: URL
    let accessDate: Date
    let size: Int

    init(fileURL: URL) {
      let meta = try? fileURL.resourceValues(forKeys: File.metadataKeys)
      self.url = fileURL
      self.accessDate = meta?.contentAccessDate ?? .distantPast
      self.size = meta?.fileSize ?? 0
    }
  }

  private let ioQueue = DispatchQueue(label: "com.makhovyk.threads-feed.videocache.io")
  private let fileManager: FileManager
  private let folderURL: URL
  private let tempFolderURL: URL
  private let totalCostLimit: Int

  init(
    fileManager: FileManager = .default,
    folderName: String,
    totalCostLimit: Int = 300 * 1024 * 1024  // 300 MB
  ) {
    self.fileManager = fileManager
    self.totalCostLimit = totalCostLimit
    let cachesRoot = (try? fileManager.url(
      for: .cachesDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )) ?? fileManager.temporaryDirectory
    let folder = cachesRoot.appendingPathComponent(folderName)
    let tempFolder = cachesRoot.appendingPathComponent(folderName + "-tmp")
    try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
    try? fileManager.createDirectory(at: tempFolder, withIntermediateDirectories: true)
    self.folderURL = folder
    self.tempFolderURL = tempFolder

    purgeTempOnLaunch()
    handleStorageLimit()
  }

  func isCached(key: String) -> Bool {
    fileExists(key)
  }

  func fileURL(key: String) -> URL? {
    fileExists(key) ? makeCacheURL(key: key) : nil
  }

  func makeCacheURL(key: String) -> URL {
    folderURL
      .appendingPathComponent(key)
      .appendingPathExtension(Self.cachedFileExtension)
  }

  func makeTempPath(fileExtension: String) -> String {
    tempFolderURL
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension(fileExtension)
      .path
  }

  func finalize(tempPath: String, key: String) {
    ioQueue.async { [weak self] in
      guard let self else { return }
      let destination = makeCacheURL(key: key)
      try? fileManager.removeItem(at: destination)
      try? fileManager.moveItem(at: URL(fileURLWithPath: tempPath), to: destination)
      evictIfNeeded()
    }
  }

  func handleStorageLimit() {
    ioQueue.async { [weak self] in self?.evictIfNeeded() }
  }

  private func purgeTempOnLaunch() {
    ioQueue.async { [weak self] in
      guard let self else { return }
      let files = (try? fileManager.contentsOfDirectory(
        at: tempFolderURL,
        includingPropertiesForKeys: nil,
        options: .skipsHiddenFiles
      )) ?? []
      files.forEach { try? self.fileManager.removeItem(at: $0) }
    }
  }

  private func fileExists(_ key: String) -> Bool {
    fileManager.fileExists(atPath: makeCacheURL(key: key).path)
  }

  private func evictIfNeeded() {
    var files = getStoredFiles().sorted { $0.accessDate > $1.accessDate }
    var size = files.map(\.size).reduce(0, +)
    while size > totalCostLimit, let victim = files.popLast() {
      size -= victim.size
      try? fileManager.removeItem(at: victim.url)
    }
  }

  private func getStoredFiles() -> [File] {
    let urls = try? fileManager.contentsOfDirectory(
      at: folderURL,
      includingPropertiesForKeys: Array(File.metadataKeys),
      options: .skipsHiddenFiles
    )
    return urls?.map(File.init(fileURL:)) ?? []
  }
}
