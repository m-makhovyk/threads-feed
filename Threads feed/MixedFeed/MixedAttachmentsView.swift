import UIKit
import SnapKit
import AVFoundation
import NukeUI

class MixedAttachmentsView: UIView {

  var onAttachmentTapped: ((_ attachments: [MixedAttachment], _ index: Int) -> Void)?

  private var collectionView: UICollectionView!
  private var attachments: [MixedAttachment] = []
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
      MixedImagePageCell.self,
      forCellWithReuseIdentifier: MixedImagePageCell.reuseIdentifier
    )
    collectionView.register(
      MixedVideoPageCell.self,
      forCellWithReuseIdentifier: MixedVideoPageCell.reuseIdentifier
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

  func configure(with attachments: [MixedAttachment]) {
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
      let isBlackedOut = indexPath.item == index
      if let imageCell = collectionView.cellForItem(at: indexPath) as? MixedImagePageCell {
        imageCell.setBlackedOut(isBlackedOut)
      } else if let videoCell = collectionView.cellForItem(at: indexPath) as? MixedVideoPageCell {
        videoCell.setBlackedOut(isBlackedOut)
        if isBlackedOut {
          if videoCell.playerContext !== contextToKeepPlaying {
            videoCell.pause()
          }
        } else {
          videoCell.pause()
        }
      }
    }
  }

  func clearBlackout() {
    defer {
      blackedOutIndex = nil
    }

    guard let blackedOutIndex else { return }

    let indexPath = IndexPath(item: blackedOutIndex, section: 0)
    if let imageCell = collectionView.cellForItem(at: indexPath) as? MixedImagePageCell {
      imageCell.setBlackedOut(false)
    } else if let videoCell = collectionView.cellForItem(at: indexPath) as? MixedVideoPageCell {
      videoCell.setBlackedOut(false)
    }

    applyPlaybackState()
  }

  func scrollToAttachment(at index: Int, animated: Bool) {
    guard attachments.indices.contains(index) else { return }
    let indexPath = IndexPath(item: index, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    currentActiveIndex = index
    if !animated {
      collectionView.layoutIfNeeded()
    }
    applyPlaybackState()
  }

  func replacePlayerContext(_ context: VideoPlayerContext, at index: Int) {
    guard attachments.indices.contains(index) else { return }

    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? MixedVideoPageCell else { return }

    context.setMuted(true)
    cell.setPlayerContext(context)
    cell.setBlackedOut(index == blackedOutIndex)

    if isActive && index == currentActiveIndex {
      context.play()
    } else {
      context.pause()
    }
  }

  func attachmentView(at index: Int) -> UIView? {
    let indexPath = IndexPath(item: index, section: 0)
    if let imageCell = collectionView.cellForItem(at: indexPath) as? MixedImagePageCell {
      return imageCell.lazyImageView
    }
    if let videoCell = collectionView.cellForItem(at: indexPath) as? MixedVideoPageCell {
      return videoCell.playerView
    }
    return nil
  }

  func image(at index: Int) -> UIImage? {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? MixedImagePageCell else { return nil }
    return cell.lazyImageView.imageView.image
  }

  func playerContext(at index: Int) -> VideoPlayerContext? {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? MixedVideoPageCell else { return nil }
    return cell.playerContext
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
      guard let cell = collectionView.cellForItem(at: indexPath) as? MixedVideoPageCell else { continue }
      if isActive && indexPath.item == currentActiveIndex {
        cell.play()
      } else {
        cell.pause()
      }
    }
  }
}

// MARK: - Data Source

extension MixedAttachmentsView: UICollectionViewDataSource {

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
    switch attachments[indexPath.item] {
    case .image(let attachment):
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: MixedImagePageCell.reuseIdentifier,
        for: indexPath
      ) as! MixedImagePageCell
      cell.configure(with: attachment.url)
      cell.setBlackedOut(indexPath.item == blackedOutIndex)
      return cell
    case .video(let attachment):
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: MixedVideoPageCell.reuseIdentifier,
        for: indexPath
      ) as! MixedVideoPageCell
      cell.configure(with: attachment.url)
      cell.setBlackedOut(indexPath.item == blackedOutIndex)
      if isActive && indexPath.item == currentActiveIndex {
        cell.play()
      }
      return cell
    }
  }
}

// MARK: - Delegate

extension MixedAttachmentsView: UICollectionViewDelegateFlowLayout {

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

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard isActive else { return }
    let previousIndex = currentActiveIndex
    recalculateActiveIndex()
    if currentActiveIndex != previousIndex {
      applyPlaybackState()
    }
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    onAttachmentTapped?(attachments, indexPath.item)
  }
}

// MARK: - Image page cell

private class MixedImagePageCell: UICollectionViewCell {

  static let reuseIdentifier = "MixedImagePageCell"

  let lazyImageView = LazyImageView()
  private let blackoutView = UIView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    lazyImageView.imageView.contentMode = .scaleAspectFill
    lazyImageView.clipsToBounds = true
    lazyImageView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    lazyImageView.placeholderView = makePlaceholder()
    contentView.addSubview(lazyImageView)

    blackoutView.backgroundColor = .black
    blackoutView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    blackoutView.isHidden = true
    contentView.addSubview(blackoutView)

    lazyImageView.snp.makeConstraints { make in
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
    lazyImageView.url = url
  }

  func setBlackedOut(_ blacked: Bool) {
    blackoutView.isHidden = !blacked
    lazyImageView.isHidden = blacked
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    lazyImageView.url = nil
    lazyImageView.isHidden = false
    blackoutView.isHidden = true
  }

  private func makePlaceholder() -> UIView {
    let view = UIView()
    view.backgroundColor = .secondarySystemBackground
    view.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    return view
  }
}

// MARK: - Video page cell

private class MixedVideoPageCell: UICollectionViewCell {

  static let reuseIdentifier = "MixedVideoPageCell"

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
    playerContext?.pause()
    setPlayerContext(VideoPlayerContext(url: url, muted: true))
  }

  func setPlayerContext(_ context: VideoPlayerContext) {
    if playerContext !== context {
      playerContext?.pause()
    }
    playerContext = context
    context.setMuted(true)
    playerView.playerLayer.player = context.player
  }

  func setBlackedOut(_ blacked: Bool) {
    blackoutView.isHidden = !blacked
  }

  func play() {
    playerContext?.play()
  }

  func pause() {
    playerContext?.pause()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    playerContext?.pause()
    playerContext = nil
    playerView.playerLayer.player = nil
    blackoutView.isHidden = true
  }
}
