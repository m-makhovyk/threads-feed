import UIKit
import SnapKit
import AVFoundation

class VideoAttachmentsView: UIView {

  var onVideoTapped: ((_ urls: [URL], _ index: Int) -> Void)?

  private var collectionView: UICollectionView!
  private var attachments: [VideoAttachment] = []
  private var isActive = false
  private var currentActiveIndex = 0

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
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = attachments.count > 1
  }

  func reset() {
    attachments = []
    isActive = false
    currentActiveIndex = 0
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = false
  }

  func setActive(_ active: Bool) {
    isActive = active
    recalculateActiveIndex()
    applyPlaybackState()
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
    let urls = attachments.map(\.url)
    onVideoTapped?(urls, indexPath.item)
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

// MARK: - Player View

private class PlayerView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Attachment Cell

private class AttachmentVideoCell: UICollectionViewCell {

  static let reuseIdentifier = "AttachmentVideoCell"

  private let playerView = PlayerView()
  private var player: AVQueuePlayer?
  private var looper: AVPlayerLooper?

  override init(frame: CGRect) {
    super.init(frame: frame)

    playerView.backgroundColor = .secondarySystemBackground
    playerView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    playerView.layer.masksToBounds = true
    playerView.playerLayer.videoGravity = .resizeAspectFill
    contentView.addSubview(playerView)

    playerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with url: URL) {
    let item = AVPlayerItem(url: url)
    let queuePlayer = AVQueuePlayer()
    queuePlayer.isMuted = true
    looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
    player = queuePlayer
    playerView.playerLayer.player = queuePlayer
  }

  func play() {
    player?.play()
  }

  func pause() {
    player?.pause()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    player?.pause()
    player?.removeAllItems()
    looper = nil
    player = nil
    playerView.playerLayer.player = nil
  }
}
