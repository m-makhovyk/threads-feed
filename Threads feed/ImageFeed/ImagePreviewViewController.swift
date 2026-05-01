import UIKit
import SnapKit

class ImagePreviewViewController: UIViewController {

  private let imageURLs: [URL]
  let initialIndex: Int
  private var hasScrolledToInitialPage = false
  private var lastCollectionViewSize: CGSize = .zero
  private var currentPageIndex: Int
  private var swipeToDismiss: SwipeToDismissInteraction?
  let zoomTransition = ImageZoomTransition()

  var onPageChange: ((Int) -> Void)?
  var onBlackoutIndex: ((Int) -> Void)?
  var onClearBlackout: (() -> Void)?

  var imageCount: Int {
    imageURLs.count
  }

  var currentPage: Int {
    currentPageIndex
  }

  var currentImage: UIImage? {
    currentCell?.imageView.image
  }

  var currentCell: ZoomableImageCell? {
    let indexPath = IndexPath(item: currentPage, section: 0)
    return collectionView.cellForItem(at: indexPath) as? ZoomableImageCell
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
    cv.register(ZoomableImageCell.self, forCellWithReuseIdentifier: ZoomableImageCell.reuseIdentifier)
    return cv
  }()

  let closeButton: UIButton = {
    let button = UIButton(type: .system)
    let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
    let image = UIImage(systemName: "xmark", withConfiguration: config)
    button.setImage(image, for: .normal)
    button.tintColor = .white
    button.backgroundColor = UIColor.white.withAlphaComponent(0.15)
    button.layer.cornerRadius = 20
    return button
  }()

  init(imageURLs: [URL], initialIndex: Int) {
    self.imageURLs = imageURLs
    self.initialIndex = initialIndex
    self.currentPageIndex = initialIndex
    super.init(nibName: nil, bundle: nil)
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
      make.size.equalTo(40)
    }

    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

    swipeToDismiss = SwipeToDismissInteraction(
      viewController: self,
      backgroundView: backgroundView
    )
    swipeToDismiss?.onControlsVisible = { [weak self] visible in
      self?.closeButton.alpha = visible ? 1 : 0
    }
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

  override var prefersStatusBarHidden: Bool {
    true
  }

  @objc private func closeTapped() {
    closeButton.isEnabled = false
    swipeToDismiss?.disable()
    zoomTransition.dismiss(from: self)
  }

}

extension ImagePreviewViewController: UICollectionViewDataSource {

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    imageURLs.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ZoomableImageCell.reuseIdentifier,
      for: indexPath
    ) as! ZoomableImageCell
    cell.configure(with: imageURLs[indexPath.item])
    return cell
  }
}

extension ImagePreviewViewController: UICollectionViewDelegateFlowLayout {

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    collectionView.bounds.size
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    reportCurrentPageIfNeeded()
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard !decelerate else { return }
    reportCurrentPageIfNeeded()
  }

  func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    reportCurrentPageIfNeeded()
  }

  private func reportCurrentPageIfNeeded(_ page: Int? = nil) {
    let resolvedPage = page ?? pageForCurrentContentOffset()
    guard resolvedPage != currentPageIndex else { return }

    currentPageIndex = resolvedPage
    onPageChange?(resolvedPage)
    onBlackoutIndex?(resolvedPage)
  }

  private func pageForCurrentContentOffset() -> Int {
    guard collectionView.bounds.width > 0 else { return currentPageIndex }

    let rawPage = collectionView.contentOffset.x / collectionView.bounds.width
    return clampedPage(Int(round(rawPage)))
  }

  private func clampedPage(_ page: Int) -> Int {
    min(max(page, 0), imageURLs.count - 1)
  }
}

extension ImagePreviewViewController: UIViewControllerTransitioningDelegate {

  func animationController(
    forPresented presented: UIViewController,
    presenting: UIViewController,
    source: UIViewController
  ) -> (any UIViewControllerAnimatedTransitioning)? {
    return zoomTransition
  }

}
