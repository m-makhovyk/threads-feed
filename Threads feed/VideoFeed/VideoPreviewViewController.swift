import UIKit
import SnapKit
import AVFoundation

class VideoPreviewViewController: UIViewController {

  var onPageChange: ((Int) -> Void)?

  private let videoURLs: [URL]
  private let initialIndex: Int
  private var currentPageIndex: Int
  private var hasScrolledToInitialPage = false
  private var lastCollectionViewSize: CGSize = .zero

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.isPagingEnabled = true
    cv.showsHorizontalScrollIndicator = false
    cv.backgroundColor = .clear
    cv.register(
      FullScreenVideoCell.self,
      forCellWithReuseIdentifier: FullScreenVideoCell.reuseIdentifier
    )
    return cv
  }()

  private let closeButton = BlurredButton(systemName: "xmark")

  init(videoURLs: [URL], initialIndex: Int) {
    self.videoURLs = videoURLs
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

    let collectionViewSize = collectionView.bounds.size
    guard collectionViewSize.width > 0, collectionViewSize.height > 0 else { return }

    let sizeChanged = collectionViewSize != lastCollectionViewSize
    guard !hasScrolledToInitialPage || sizeChanged else { return }

    hasScrolledToInitialPage = true
    lastCollectionViewSize = collectionViewSize
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.contentOffset = CGPoint(
      x: CGFloat(currentPageIndex) * collectionViewSize.width,
      y: 0
    )
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    applyPlaybackState()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    for cell in collectionView.visibleCells {
      (cell as? FullScreenVideoCell)?.pause()
    }
  }

  override var prefersStatusBarHidden: Bool {
    true
  }

  @objc private func closeTapped() {
    dismiss(animated: true)
  }

  private func applyPlaybackState() {
    for indexPath in collectionView.indexPathsForVisibleItems {
      guard let cell = collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell else { continue }
      if indexPath.item == currentPageIndex {
        cell.play()
      } else {
        cell.pause()
      }
    }
  }
}

extension VideoPreviewViewController: UICollectionViewDataSource {

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    videoURLs.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: FullScreenVideoCell.reuseIdentifier,
      for: indexPath
    ) as! FullScreenVideoCell
    cell.configure(with: videoURLs[indexPath.item])
    if indexPath.item == currentPageIndex {
      cell.play()
    }
    return cell
  }
}

extension VideoPreviewViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    collectionView.bounds.size
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
    onPageChange?(newPage)
  }

  private func pageForCurrentContentOffset() -> Int {
    guard collectionView.bounds.width > 0 else { return currentPageIndex }
    let rawPage = collectionView.contentOffset.x / collectionView.bounds.width
    let clamped = min(max(Int(round(rawPage)), 0), videoURLs.count - 1)
    return clamped
  }
}

// MARK: - Player View

private class PlayerView: UIView {
  override class var layerClass: AnyClass { AVPlayerLayer.self }
  var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

// MARK: - Full Screen Video Cell

private class FullScreenVideoCell: UICollectionViewCell {

  static let reuseIdentifier = "FullScreenVideoCell"

  private let playerView = PlayerView()
  private var player: AVQueuePlayer?
  private var looper: AVPlayerLooper?

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

  func configure(with url: URL) {
    let item = AVPlayerItem(url: url)
    let queuePlayer = AVQueuePlayer()
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
