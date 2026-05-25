import UIKit
import SnapKit
import AVFoundation

class VideoPreviewViewController: UIViewController {

  var onPageChange: ((Int) -> Void)?
  var onBlackoutIndex: ((Int) -> Void)?
  var onClearBlackout: (() -> Void)?
  var onPlayerContextReadyForFeed: ((_ index: Int, _ context: VideoPlayerContext) -> Void)?

  private let attachments: [VideoAttachment]
  let initialIndex: Int
  private var currentPageIndex: Int
  private var hasScrolledToInitialPage = false
  private var lastCollectionViewSize: CGSize = .zero
  private var playerContexts: [Int: VideoPlayerContext] = [:]
  let zoomTransition = VideoZoomTransition()

  var currentPage: Int {
    currentPageIndex
  }

  var currentCell: FullScreenVideoCell? {
    let indexPath = IndexPath(item: currentPage, section: 0)
    return collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell
  }

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
      FullScreenVideoCell.self,
      forCellWithReuseIdentifier: FullScreenVideoCell.reuseIdentifier
    )
    return cv
  }()

  let closeButton = BlurredButton(systemName: "xmark")

  init(
    attachments: [VideoAttachment],
    initialIndex: Int,
    initialPlayerContext: VideoPlayerContext?
  ) {
    self.attachments = attachments
    self.initialIndex = initialIndex
    self.currentPageIndex = initialIndex
    super.init(nibName: nil, bundle: nil)
    if let initialPlayerContext {
      initialPlayerContext.setMuted(false)
      playerContexts[initialIndex] = initialPlayerContext
    }
    modalPresentationStyle = .overFullScreen
    transitioningDelegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear

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

  override var prefersStatusBarHidden: Bool {
    true
  }

  @objc private func closeTapped() {
    closeButton.isEnabled = false
    zoomTransition.dismiss(from: self)
  }

  func playerContext(forPage index: Int) -> VideoPlayerContext {
    if let context = playerContexts[index] {
      context.setMuted(false)
      return context
    }

    let context = VideoPlayerContext(url: attachments[index].url, muted: false)
    playerContexts[index] = context
    return context
  }

  func currentPlayerContext() -> VideoPlayerContext? {
    playerContexts[currentPage]
  }

  func attachment(at index: Int) -> VideoAttachment {
    attachments[index]
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

    for indexPath in collectionView.indexPathsForVisibleItems {
      guard let cell = collectionView.cellForItem(at: indexPath) as? FullScreenVideoCell else { continue }
      cell.refreshPlayerLayer()
    }
  }
}

extension VideoPreviewViewController: UICollectionViewDataSource {

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
      withReuseIdentifier: FullScreenVideoCell.reuseIdentifier,
      for: indexPath
    ) as! FullScreenVideoCell
    cell.configure(with: playerContext(forPage: indexPath.item))
    if indexPath.item == currentPageIndex {
      cell.play()
    } else {
      cell.pause()
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

  func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    guard indexPath.item != currentPageIndex else { return }
    (cell as? FullScreenVideoCell)?.pause()
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
    onBlackoutIndex?(newPage)
  }

  private func pageForCurrentContentOffset() -> Int {
    guard collectionView.bounds.width > 0 else { return currentPageIndex }
    let rawPage = collectionView.contentOffset.x / collectionView.bounds.width
    let clamped = min(max(Int(round(rawPage)), 0), attachments.count - 1)
    return clamped
  }
}

extension VideoPreviewViewController: UIViewControllerTransitioningDelegate {

  func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> (any UIViewControllerAnimatedTransitioning)? {
    zoomTransition
  }
}

class VideoZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

  struct SourceInfo {
    let view: UIView
    let contentSize: CGSize
    let cornerRadius: CGFloat
  }

  struct Endpoint {
    let frame: CGRect
    let mediaFrame: CGRect
    let cornerRadius: CGFloat

    static func centered(
      frame: CGRect,
      mediaSize: CGSize,
      cornerRadius: CGFloat
    ) -> Self {
      Endpoint(
        frame: frame,
        mediaFrame: AspectGeometry.centeredRect(size: mediaSize, in: frame.size),
        cornerRadius: cornerRadius
      )
    }
  }

  static let animationDuration: TimeInterval = 0.45

  var sourceProvider: ((_ pageIndex: Int) -> SourceInfo?)?

  func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
    Self.animationDuration
  }

  func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    animatePresentation(using: transitionContext)
  }

  private func animatePresentation(using context: UIViewControllerContextTransitioning) {
    guard
      let toVC = context.viewController(forKey: .to) as? VideoPreviewViewController,
      let sourceInfo = sourceProvider?(toVC.initialIndex)
    else {
      if let toVC = context.viewController(forKey: .to) {
        context.containerView.addSubview(toVC.view)
        toVC.view.frame = context.finalFrame(for: toVC)
      }
      context.completeTransition(true)
      return
    }

    let containerView = context.containerView
    let playerContext = toVC.playerContext(forPage: toVC.initialIndex)
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: containerView)

    toVC.view.frame = context.finalFrame(for: toVC)
    containerView.addSubview(toVC.view)
    toVC.view.layoutIfNeeded()

    let previewBounds = toVC.view.bounds
    toVC.backgroundView.alpha = 0
    toVC.collectionView.alpha = 0
    toVC.closeButton.alpha = 0
    sourceInfo.view.alpha = 0
    toVC.onBlackoutIndex?(toVC.initialIndex)

    let start = Endpoint.centered(
      frame: cellFrame,
      mediaSize: AspectGeometry.aspectFillSize(contentSize: sourceInfo.contentSize, boundingSize: cellFrame.size),
      cornerRadius: sourceInfo.cornerRadius
    )
    let end = Endpoint.centered(
      frame: previewBounds,
      mediaSize: AspectGeometry.aspectFitSize(contentSize: sourceInfo.contentSize, boundingSize: previewBounds.size),
      cornerRadius: sourceInfo.cornerRadius
    )

    Self.animateClipTransition(
      playerContext: playerContext,
      from: start,
      to: end,
      in: containerView,
      duration: transitionDuration(using: context),
      alongside: {
        toVC.backgroundView.alpha = 1
      },
      completion: {
        let completed = !context.transitionWasCancelled
        if completed {
          toVC.currentCell?.refreshPlayerLayer()
          toVC.collectionView.alpha = 1
          UIView.animate(withDuration: 0.1, delay: 0) {
            toVC.closeButton.alpha = 1
          }
        }
        sourceInfo.view.alpha = 1
        context.completeTransition(completed)
      }
    )
  }

  func dismiss(from viewController: VideoPreviewViewController) {
    let page = viewController.currentPage
    let clearBlackout = viewController.onClearBlackout

    guard let playerContext = viewController.currentPlayerContext() else {
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    guard let sourceInfo = sourceProvider?(page),
          let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      playerContext.setMuted(true)
      viewController.onPlayerContextReadyForFeed?(page, playerContext)
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    viewController.currentCell?.detachPlayerLayer()

    runDismissClipAnimation(
      playerContext: playerContext,
      sourceInfo: sourceInfo,
      feedCollectionView: feedCollectionView,
      visualFrameInPreview: viewController.view.bounds,
      cornerRadius: 0,
      in: viewController.view,
      completion: {
        playerContext.setMuted(true)
        viewController.onPlayerContextReadyForFeed?(page, playerContext)
        clearBlackout?()
      }
    )

    viewController.dismiss(animated: false)
  }

  private func runDismissClipAnimation(
    playerContext: VideoPlayerContext,
    sourceInfo: SourceInfo,
    feedCollectionView: UICollectionView,
    visualFrameInPreview: CGRect,
    cornerRadius: CGFloat,
    in previewView: UIView,
    completion: @escaping () -> Void
  ) {
    let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCollectionView)
    let visualFrame = feedCollectionView.convert(visualFrameInPreview, from: previewView)

    let start = Endpoint.centered(
      frame: visualFrame,
      mediaSize: AspectGeometry.aspectFitSize(contentSize: sourceInfo.contentSize, boundingSize: visualFrame.size),
      cornerRadius: cornerRadius
    )
    let end = Endpoint.centered(
      frame: cellFrame,
      mediaSize: AspectGeometry.aspectFillSize(contentSize: sourceInfo.contentSize, boundingSize: cellFrame.size),
      cornerRadius: sourceInfo.cornerRadius
    )

    Self.animateClipTransition(
      playerContext: playerContext,
      from: start,
      to: end,
      in: feedCollectionView,
      completion: completion
    )
  }

  static func animateClipTransition(
    playerContext: VideoPlayerContext,
    from start: Endpoint,
    to end: Endpoint,
    in containerView: UIView,
    duration: TimeInterval = VideoZoomTransition.animationDuration,
    alongside: @escaping () -> Void = {},
    completion: @escaping () -> Void = {}
  ) {
    let clipView = UIView(frame: start.frame)
    clipView.clipsToBounds = true
    clipView.layer.cornerRadius = start.cornerRadius
    clipView.layer.cornerCurve = .continuous
    clipView.backgroundColor = .black
    containerView.addSubview(clipView)

    let playerView = VideoPlayerView(frame: start.mediaFrame)
    playerView.playerLayer.videoGravity = .resizeAspect
    playerView.playerLayer.player = playerContext.player
    clipView.addSubview(playerView)

    UIView.animate(
      withDuration: duration,
      delay: 0,
      usingSpringWithDamping: 0.85,
      initialSpringVelocity: 0
    ) {
      clipView.frame = end.frame
      clipView.layer.cornerRadius = end.cornerRadius
      playerView.frame = end.mediaFrame
      alongside()
    } completion: { _ in
      // Install the destination layer while the transition layer is still covering it.
      // AVPlayerLayer can briefly render black right after attaching an existing player;
      // keeping this mirror alive until the next run-loop frame hides that handoff.
      completion()

      DispatchQueue.main.async {
        UIView.animate(withDuration: 0.05, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
          clipView.alpha = 0
        } completion: { _ in
          playerView.playerLayer.player = nil
          clipView.removeFromSuperview()
        }
      }
    }
  }
}

class FullScreenVideoCell: UICollectionViewCell {

  static let reuseIdentifier = "FullScreenVideoCell"

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
    refreshPlayerLayer()
  }

  func refreshPlayerLayer() {
    playerView.playerLayer.player = playerContext?.player
  }

  func detachPlayerLayer() {
    playerView.playerLayer.player = nil
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
