import UIKit
import SnapKit
import AVFoundation
import NukeUI

class MixedPreviewViewController: UIViewController {

  private let attachments: [MixedAttachment]
  let initialIndex: Int
  private var currentPageIndex: Int
  private var hasScrolledToInitialPage = false
  private var lastCollectionViewSize: CGSize = .zero
  private var playerContexts: [Int: VideoPlayerContext] = [:]

  var attachmentsCount: Int { attachments.count }
  var currentPage: Int { currentPageIndex }

  let backgroundView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    return view
  }()

  lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.isPagingEnabled = true
    cv.showsHorizontalScrollIndicator = false
    cv.backgroundColor = .clear
    cv.register(
      FullScreenMixedImageCell.self,
      forCellWithReuseIdentifier: FullScreenMixedImageCell.reuseIdentifier
    )
    cv.register(
      FullScreenMixedVideoCell.self,
      forCellWithReuseIdentifier: FullScreenMixedVideoCell.reuseIdentifier
    )
    return cv
  }()

  let closeButton = BlurredButton(systemName: "xmark")

  init(attachments: [MixedAttachment], initialIndex: Int) {
    self.attachments = attachments
    self.initialIndex = initialIndex
    self.currentPageIndex = initialIndex
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .fullScreen
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black

    backgroundView.frame = view.bounds
    backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(backgroundView)

    collectionView.frame = view.bounds
    collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    collectionView.dataSource = self
    collectionView.delegate = self
    view.addSubview(collectionView)

    view.addSubview(closeButton)
    closeButton.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
    }
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let size = collectionView.bounds.size
    guard size.width > 0, size.height > 0 else { return }
    let sizeChanged = size != lastCollectionViewSize
    guard !hasScrolledToInitialPage || sizeChanged else { return }
    hasScrolledToInitialPage = true
    lastCollectionViewSize = size
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.contentOffset = CGPoint(
      x: CGFloat(currentPageIndex) * size.width,
      y: 0
    )
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    applyPlaybackState()
  }

  override var prefersStatusBarHidden: Bool { true }

  @objc private func closeTapped() {
    dismiss(animated: true)
  }

  private func playerContext(forPage index: Int) -> VideoPlayerContext? {
    guard case .video(let attachment) = attachments[index] else { return nil }
    if let context = playerContexts[index] {
      return context
    }
    let context = VideoPlayerContext(url: attachment.url, muted: false)
    playerContexts[index] = context
    return context
  }

  private func applyPlaybackState() {
    for (index, context) in playerContexts {
      if index == currentPageIndex {
        context.setMuted(false)
        context.play()
      } else {
        context.pause()
      }
    }
  }
}

extension MixedPreviewViewController: UICollectionViewDataSource {

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
        withReuseIdentifier: FullScreenMixedImageCell.reuseIdentifier,
        for: indexPath
      ) as! FullScreenMixedImageCell
      cell.configure(with: attachment.url)
      return cell
    case .video:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: FullScreenMixedVideoCell.reuseIdentifier,
        for: indexPath
      ) as! FullScreenMixedVideoCell
      if let context = playerContext(forPage: indexPath.item) {
        cell.configure(with: context)
        if indexPath.item == currentPageIndex {
          cell.play()
        } else {
          cell.pause()
        }
      }
      return cell
    }
  }
}

extension MixedPreviewViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    collectionView.bounds.size
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard indexPath.item != currentPageIndex else { return }
    (cell as? FullScreenMixedVideoCell)?.pause()
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateCurrentPageIfNeeded()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard !decelerate else { return }
    updateCurrentPageIfNeeded()
  }

  private func updateCurrentPageIfNeeded() {
    let newPage = pageForCurrentContentOffset()
    guard newPage != currentPageIndex else { return }
    currentPageIndex = newPage
    applyPlaybackState()
  }

  private func pageForCurrentContentOffset() -> Int {
    guard collectionView.bounds.width > 0 else { return currentPageIndex }
    let rawPage = collectionView.contentOffset.x / collectionView.bounds.width
    let clamped = min(max(Int(round(rawPage)), 0), attachments.count - 1)
    return clamped
  }
}

// MARK: - Full-screen image page

private class FullScreenMixedImageCell: UICollectionViewCell {

  static let reuseIdentifier = "FullScreenMixedImageCell"

  private let lazyImageView = LazyImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    lazyImageView.imageView.contentMode = .scaleAspectFit
    contentView.addSubview(lazyImageView)
    lazyImageView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with url: URL) {
    lazyImageView.url = url
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    lazyImageView.url = nil
  }
}

// MARK: - Full-screen video page

private class FullScreenMixedVideoCell: UICollectionViewCell {

  static let reuseIdentifier = "FullScreenMixedVideoCell"

  private let playerView = VideoPlayerView()
  private var playerContext: VideoPlayerContext?

  override init(frame: CGRect) {
    super.init(frame: frame)
    playerView.backgroundColor = .black
    playerView.playerLayer.videoGravity = .resizeAspect
    contentView.addSubview(playerView)
    playerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with context: VideoPlayerContext) {
    playerContext = context
    playerView.playerLayer.player = context.player
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
  }
}
