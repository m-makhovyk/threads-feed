import UIKit
import SnapKit
import AVFoundation
import NukeUI

class MixedPreviewViewController: UIViewController {

  var onPageChange: ((Int) -> Void)?
  var onBlackoutIndex: ((Int) -> Void)?
  var onClearBlackout: (() -> Void)?
  var onPlayerContextReadyForFeed: ((_ index: Int, _ context: VideoPlayerContext) -> Void)?

  private let attachments: [MixedAttachment]
  let initialIndex: Int
  private var currentPageIndex: Int
  private var hasScrolledToInitialPage = false
  private var lastCollectionViewSize: CGSize = .zero
  private var playerContexts: [Int: VideoPlayerContext] = [:]
  private var swipeToDismiss: MixedSwipeToDismissInteraction?
  private var areControlsHidden = false
  let zoomTransition = MixedZoomTransition()

  var currentImageCell: FullScreenMixedImageCell? {
    let indexPath = IndexPath(item: currentPageIndex, section: 0)
    return collectionView.cellForItem(at: indexPath) as? FullScreenMixedImageCell
  }

  var currentVideoCell: FullScreenMixedVideoCell? {
    let indexPath = IndexPath(item: currentPageIndex, section: 0)
    return collectionView.cellForItem(at: indexPath) as? FullScreenMixedVideoCell
  }

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

  init(
    attachments: [MixedAttachment],
    initialIndex: Int,
    initialPlayerContext: VideoPlayerContext? = nil
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

    swipeToDismiss = MixedSwipeToDismissInteraction(
      viewController: self,
      backgroundView: backgroundView
    )
    swipeToDismiss?.onControlsVisible = { [weak self] visible in
      self?.setControlsHidden(!visible, animated: false)
    }

    let tap = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
    view.addGestureRecognizer(tap)
  }

  @objc private func viewTapped() {
    setControlsHidden(!areControlsHidden, animated: true)
  }

  private var controls: [UIView] {
    [closeButton]
  }

  private func setControlsHidden(_ hidden: Bool, animated: Bool) {
    areControlsHidden = hidden
    let targetAlpha: CGFloat = hidden ? 0 : 1
    let apply = { self.controls.forEach { $0.alpha = targetAlpha } }
    if animated {
      UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
        apply()
      }
    } else {
      apply()
    }
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
    closeButton.isEnabled = false
    swipeToDismiss?.disable()
    zoomTransition.dismiss(from: self)
  }

  func playerContext(forPage index: Int) -> VideoPlayerContext? {
    guard case .video(let attachment) = attachments[index] else { return nil }
    if let context = playerContexts[index] {
      context.setMuted(false)
      return context
    }
    let context = VideoPlayerContext(url: attachment.url, muted: false)
    playerContexts[index] = context
    return context
  }

  func currentPlayerContext() -> VideoPlayerContext? {
    playerContexts[currentPageIndex]
  }

  func attachment(at index: Int) -> MixedAttachment {
    attachments[index]
  }

  func currentImage(at pageIndex: Int) -> UIImage? {
    let indexPath = IndexPath(item: pageIndex, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? FullScreenMixedImageCell else { return nil }
    return cell.currentImage
  }

  func refreshCurrentPagePlayerLayer() {
    let indexPath = IndexPath(item: currentPageIndex, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? FullScreenMixedVideoCell else { return }
    cell.refreshPlayerLayer()
  }

  func detachCurrentPagePlayerLayer() {
    let indexPath = IndexPath(item: currentPageIndex, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? FullScreenMixedVideoCell else { return }
    cell.detachPlayerLayer()
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

extension MixedPreviewViewController: UIViewControllerTransitioningDelegate {

  func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> (any UIViewControllerAnimatedTransitioning)? {
    zoomTransition
  }
}

// MARK: - Zoom Transition

class MixedZoomTransition: NSObject, UIViewControllerAnimatedTransitioning {

  enum Media {
    case image(UIImage)
    case video(VideoPlayerContext)
  }

  struct SourceInfo {
    let view: UIView
    let contentSize: CGSize
    let cornerRadius: CGFloat
    let media: Media
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

  // MARK: - Present

  private func animatePresentation(using context: UIViewControllerContextTransitioning) {
    guard
      let toVC = context.viewController(forKey: .to) as? MixedPreviewViewController,
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

    let alongside = { toVC.backgroundView.alpha = 1 }

    switch sourceInfo.media {
    case .image(let image):
      Self.animateImageClipTransition(
        image: image,
        from: start,
        to: end,
        in: containerView,
        duration: transitionDuration(using: context),
        alongside: alongside,
        completion: {
          let completed = !context.transitionWasCancelled
          if completed {
            toVC.collectionView.alpha = 1
            UIView.animate(withDuration: 0.1, delay: 0) {
              toVC.closeButton.alpha = 1
            }
          }
          sourceInfo.view.alpha = 1
          context.completeTransition(completed)
        }
      )
    case .video(let playerContext):
      Self.animateVideoClipTransition(
        playerContext: playerContext,
        from: start,
        to: end,
        in: containerView,
        duration: transitionDuration(using: context),
        alongside: alongside,
        completion: {
          let completed = !context.transitionWasCancelled
          if completed {
            toVC.refreshCurrentPagePlayerLayer()
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
  }

  // MARK: - Dismiss

  func dismiss(from viewController: MixedPreviewViewController) {
    let page = viewController.currentPage
    let clearBlackout = viewController.onClearBlackout

    guard let sourceInfo = sourceProvider?(page),
          let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      if case .video(let playerContext) = sourceProvider?(page)?.media {
        playerContext.setMuted(true)
        viewController.onPlayerContextReadyForFeed?(page, playerContext)
      }
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    switch sourceInfo.media {
    case .image(let image):
      runImageDismissClipAnimation(
        image: image,
        sourceInfo: sourceInfo,
        feedCollectionView: feedCollectionView,
        visualFrameInPreview: viewController.view.bounds,
        cornerRadius: 0,
        in: viewController.view,
        completion: { clearBlackout?() }
      )
    case .video(let playerContext):
      viewController.detachCurrentPagePlayerLayer()
      runVideoDismissClipAnimation(
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
    }

    viewController.dismiss(animated: false)
  }

  func finishInteractiveDismiss(
    image: UIImage,
    sourceInfo: SourceInfo,
    visualFrameInPreview: CGRect,
    cornerRadius: CGFloat,
    viewController: MixedPreviewViewController
  ) {
    let clearBlackout = viewController.onClearBlackout

    guard let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    runImageDismissClipAnimation(
      image: image,
      sourceInfo: sourceInfo,
      feedCollectionView: feedCollectionView,
      visualFrameInPreview: visualFrameInPreview,
      cornerRadius: cornerRadius,
      in: viewController.view,
      completion: { clearBlackout?() }
    )

    viewController.dismiss(animated: false)
  }

  func finishInteractiveDismiss(
    playerContext: VideoPlayerContext,
    sourceInfo: SourceInfo,
    visualFrameInPreview: CGRect,
    cornerRadius: CGFloat,
    viewController: MixedPreviewViewController
  ) {
    let page = viewController.currentPage
    let clearBlackout = viewController.onClearBlackout

    guard let feedCollectionView = sourceInfo.view.findOutermostCollectionView() else {
      playerContext.setMuted(true)
      viewController.onPlayerContextReadyForFeed?(page, playerContext)
      clearBlackout?()
      viewController.dismiss(animated: false)
      return
    }

    runVideoDismissClipAnimation(
      playerContext: playerContext,
      sourceInfo: sourceInfo,
      feedCollectionView: feedCollectionView,
      visualFrameInPreview: visualFrameInPreview,
      cornerRadius: cornerRadius,
      in: viewController.view,
      completion: {
        playerContext.setMuted(true)
        viewController.onPlayerContextReadyForFeed?(page, playerContext)
        clearBlackout?()
      }
    )

    viewController.dismiss(animated: false)
  }

  private func runImageDismissClipAnimation(
    image: UIImage,
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

    Self.animateImageClipTransition(
      image: image,
      from: start,
      to: end,
      in: feedCollectionView,
      completion: completion
    )
  }

  private func runVideoDismissClipAnimation(
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

    Self.animateVideoClipTransition(
      playerContext: playerContext,
      from: start,
      to: end,
      in: feedCollectionView,
      completion: completion
    )
  }

  // MARK: - Shared Animation

  static func animateImageClipTransition(
    image: UIImage,
    from start: Endpoint,
    to end: Endpoint,
    in containerView: UIView,
    duration: TimeInterval = MixedZoomTransition.animationDuration,
    alongside: @escaping () -> Void = {},
    completion: @escaping () -> Void = {}
  ) {
    let clipView = UIView(frame: start.frame)
    clipView.clipsToBounds = true
    clipView.layer.cornerRadius = start.cornerRadius
    clipView.layer.cornerCurve = .continuous
    containerView.addSubview(clipView)

    let imageView = UIImageView(image: image)
    imageView.frame = start.mediaFrame
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = end.cornerRadius
    clipView.addSubview(imageView)

    UIView.animate(
      withDuration: duration,
      delay: 0,
      usingSpringWithDamping: 0.85,
      initialSpringVelocity: 0
    ) {
      clipView.frame = end.frame
      clipView.layer.cornerRadius = end.cornerRadius
      imageView.frame = end.mediaFrame
      imageView.layer.cornerRadius = 0
      alongside()
    } completion: { _ in
      clipView.removeFromSuperview()
      completion()
    }
  }

  static func animateVideoClipTransition(
    playerContext: VideoPlayerContext,
    from start: Endpoint,
    to end: Endpoint,
    in containerView: UIView,
    duration: TimeInterval = MixedZoomTransition.animationDuration,
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

// MARK: - Full-screen image page

class FullScreenMixedImageCell: UICollectionViewCell {

  static let reuseIdentifier = "FullScreenMixedImageCell"

  let lazyImageView = LazyImageView()

  var currentImage: UIImage? {
    lazyImageView.imageView.image
  }

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

class FullScreenMixedVideoCell: UICollectionViewCell {

  static let reuseIdentifier = "FullScreenMixedVideoCell"

  let playerView = VideoPlayerView()
  private(set) var playerContext: VideoPlayerContext?

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

  func refreshPlayerLayer() {
    playerView.playerLayer.player = playerContext?.player
  }

  func detachPlayerLayer() {
    playerView.playerLayer.player = nil
  }

  // Reparenting the playerView (not just its player) keeps the same AVPlayerLayer
  // rendering, avoiding the brief black flash that comes from assigning the same
  // player to a freshly-created layer.
  func extractPlayerView() -> VideoPlayerView {
    playerView.snp.removeConstraints()
    playerView.removeFromSuperview()
    playerView.translatesAutoresizingMaskIntoConstraints = true
    return playerView
  }

  func restorePlayerView() {
    playerView.transform = .identity
    playerView.layer.cornerRadius = 0
    playerView.layer.masksToBounds = false
    playerView.backgroundColor = .black
    playerView.playerLayer.videoGravity = .resizeAspect
    guard playerView.superview !== contentView else { return }
    playerView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(playerView)
    playerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
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
