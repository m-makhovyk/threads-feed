import UIKit
import SnapKit
import AVFoundation

final class VideoPlayerContext {

  let url: URL
  let player: AVQueuePlayer
  private let looper: AVPlayerLooper

  init(url: URL, muted: Bool) {
    self.url = url

    let item = AVPlayerItem(url: url)
    let queuePlayer = AVQueuePlayer()
    queuePlayer.isMuted = muted

    self.player = queuePlayer
    self.looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
  }

  func setMuted(_ muted: Bool) {
    player.isMuted = muted
  }
}

class VideoPlayerView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

class VideoAttachmentsView: UIView {

  var onVideoTapped: ((_ attachments: [VideoAttachment], _ index: Int, _ playerContext: VideoPlayerContext?) -> Void)?

  private var collectionView: UICollectionView!
  private var attachments: [VideoAttachment] = []
  private var isActive = false
  private var currentActiveIndex = 0
  private var blackedOutIndex: Int?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = LayoutConstants.attachmentImageSpacing

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.alwaysBounceHorizontal = true
    collectionView.backgroundColor = .clear
    collectionView.register(
      AttachmentVideoCell.self,
      forCellWithReuseIdentifier: AttachmentVideoCell.reuseIdentifier
    )
    addSubview(collectionView)

    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    collectionView.contentInset = UIEdgeInsets(
      top: 0,
      left: LayoutConstants.contentLeadingInset,
      bottom: 0,
      right: 16
    )
  }

  func configure(with attachments: [VideoAttachment]) {
    self.attachments = attachments
    currentActiveIndex = 0
    blackedOutIndex = nil
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = attachments.count > 1
  }

  func reset() {
    attachments = []
    isActive = false
    currentActiveIndex = 0
    blackedOutIndex = nil
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = false
  }

  func setActive(_ active: Bool) {
    isActive = active
    recalculateActiveIndex()
    applyPlaybackState()
  }

  func setBlackedOut(at index: Int, preserving contextToKeepPlaying: VideoPlayerContext? = nil) {
    blackedOutIndex = index
    for indexPath in collectionView.indexPathsForVisibleItems {
      guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentVideoCell else { continue }
      let isBlackedOut = indexPath.item == index
      cell.setBlackedOut(isBlackedOut)
      if isBlackedOut && cell.playerContext !== contextToKeepPlaying {
        cell.pause()
      }
    }
  }

  func clearBlackout() {
    defer {
      blackedOutIndex = nil
    }

    guard let blackedOutIndex else { return }

    let indexPath = IndexPath(item: blackedOutIndex, section: 0)
    if let cell = collectionView.cellForItem(at: indexPath) as? AttachmentVideoCell {
      cell.setBlackedOut(false)
    }
  }

  func scrollToVideo(at index: Int, animated: Bool) {
    guard attachments.indices.contains(index) else { return }
    let indexPath = IndexPath(item: index, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    currentActiveIndex = index
    if !animated {
      collectionView.layoutIfNeeded()
    }
    applyPlaybackState()
  }

  func videoView(at index: Int) -> UIView? {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentVideoCell else { return nil }
    return cell.playerView
  }

  func playerContext(at index: Int) -> VideoPlayerContext? {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentVideoCell else { return nil }
    return cell.playerContext
  }

  func replacePlayerContext(_ context: VideoPlayerContext, at index: Int) {
    guard attachments.indices.contains(index) else { return }

    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentVideoCell else { return }

    context.setMuted(true)
    cell.setPlayerContext(context)
    cell.setBlackedOut(index == blackedOutIndex)

    if isActive && index == currentActiveIndex {
      context.player.play()
    } else {
      context.player.pause()
    }
  }

  private func recalculateActiveIndex() {
    guard attachments.count > 1 else {
      currentActiveIndex = 0
      return
    }
    let centerX = collectionView.contentOffset.x + collectionView.bounds.width / 2
    var bestIndex = 0
    var bestDistance: CGFloat = .greatestFiniteMagnitude
    for index in attachments.indices {
      let indexPath = IndexPath(item: index, section: 0)
      guard let frame = collectionView.layoutAttributesForItem(at: indexPath)?.frame else { continue }
      let distance = abs(frame.midX - centerX)
      if distance < bestDistance {
        bestDistance = distance
        bestIndex = index
      }
    }
    currentActiveIndex = bestIndex
  }

  private func applyPlaybackState() {
    for indexPath in collectionView.indexPathsForVisibleItems {
      guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentVideoCell else { continue }
      if isActive && indexPath.item == currentActiveIndex {
        cell.play()
      } else {
        cell.pause()
      }
    }
  }
}

// MARK: - Data Source

extension VideoAttachmentsView: UICollectionViewDataSource {

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    attachments.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: AttachmentVideoCell.reuseIdentifier,
      for: indexPath
    ) as! AttachmentVideoCell
    cell.configure(with: attachments[indexPath.item].url)
    cell.setBlackedOut(indexPath.item == blackedOutIndex)
    if isActive && indexPath.item == currentActiveIndex {
      cell.play()
    }
    return cell
  }
}

// MARK: - Delegate

extension VideoAttachmentsView: UICollectionViewDelegateFlowLayout {

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let height = collectionView.bounds.height
    if attachments.count == 1 {
      let availableWidth = collectionView.bounds.width - collectionView.contentInset.left - collectionView.contentInset.right
      return CGSize(width: availableWidth, height: height)
    }
    return CGSize(width: LayoutConstants.attachmentImageWidth, height: height)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    onVideoTapped?(attachments, indexPath.item, playerContext(at: indexPath.item))
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard isActive else { return }
    let previousIndex = currentActiveIndex
    recalculateActiveIndex()
    if currentActiveIndex != previousIndex {
      applyPlaybackState()
    }
  }
}

// MARK: - Attachment Cell

private class AttachmentVideoCell: UICollectionViewCell {

  static let reuseIdentifier = "AttachmentVideoCell"

  let playerView = VideoPlayerView()
  private let blackoutView = UIView()
  private(set) var playerContext: VideoPlayerContext?

  override init(frame: CGRect) {
    super.init(frame: frame)

    playerView.backgroundColor = .secondarySystemBackground
    playerView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    playerView.layer.masksToBounds = true
    playerView.playerLayer.videoGravity = .resizeAspectFill
    contentView.addSubview(playerView)

    blackoutView.backgroundColor = .black
    blackoutView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    blackoutView.isHidden = true
    contentView.addSubview(blackoutView)

    playerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    blackoutView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with url: URL) {
    if playerContext?.url == url {
      playerContext?.setMuted(true)
      playerView.playerLayer.player = playerContext?.player
      return
    }

    playerContext?.player.pause()
    setPlayerContext(VideoPlayerContext(url: url, muted: true))
  }

  func setPlayerContext(_ context: VideoPlayerContext) {
    if playerContext !== context {
      playerContext?.player.pause()
    }
    playerContext = context
    context.setMuted(true)
    playerView.playerLayer.player = context.player
  }

  func setBlackedOut(_ blacked: Bool) {
    blackoutView.isHidden = !blacked
  }

  func play() {
    playerContext?.player.play()
  }

  func pause() {
    playerContext?.player.pause()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    playerContext?.player.pause()
    playerContext = nil
    playerView.playerLayer.player = nil
    blackoutView.isHidden = true
  }
}
