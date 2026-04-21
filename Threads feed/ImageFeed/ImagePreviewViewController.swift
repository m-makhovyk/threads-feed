import UIKit
import SnapKit

class ImagePreviewViewController: UIViewController {

  private let imageURLs: [URL]
  let initialIndex: Int
  private var hasScrolledToInitialPage = false
  private var swipeToDismiss: SwipeToDismissInteraction?
  let zoomTransition = ImageZoomTransition()

  var onPageChange: ((Int) -> Void)?
  private var lastReportedPage: Int

  var imageCount: Int {
    imageURLs.count
  }

  var currentPage: Int {
    guard collectionView.bounds.width > 0 else { return initialIndex }
    let page = Int(round(collectionView.contentOffset.x / collectionView.bounds.width))
    return min(max(page, 0), imageURLs.count - 1)
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
    cv.register(ZoomableImageCell.self, forCellWithReuseIdentifier: ZoomableImageCell.reuseID)
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
    self.lastReportedPage = initialIndex
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
      backgroundView: backgroundView,
      closeButton: closeButton
    )
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard !hasScrolledToInitialPage, initialIndex > 0, collectionView.bounds.width > 0 else { return }
    hasScrolledToInitialPage = true
    let offset = CGFloat(initialIndex) * collectionView.bounds.width
    collectionView.contentOffset = CGPoint(x: offset, y: 0)
  }

  override var prefersStatusBarHidden: Bool {
    true
  }

  @objc private func closeTapped() {
    swipeToDismiss?.disable()

    let image = currentImage
    let sourceInfo = zoomTransition.sourceProvider?(currentPage)

    // Start clip animation on feed (behind preview, not visible yet)
    if let image, let sourceInfo,
       let feedCV = sourceInfo.view.findOutermostCollectionView() {
      let cellFrame = sourceInfo.view.convert(sourceInfo.view.bounds, to: feedCV)
      let visualFrame = feedCV.convert(view.bounds, from: nil)

      let start = ImageZoomTransition.Endpoint(
        frame: visualFrame,
        imageSize: ImageZoomTransition.aspectFitSize(for: image, in: visualFrame.size),
        cornerRadius: 0
      )
      let end = ImageZoomTransition.Endpoint(
        frame: cellFrame,
        imageSize: ImageZoomTransition.aspectFillSize(for: image, in: cellFrame.size),
        cornerRadius: sourceInfo.cornerRadius
      )

      ImageZoomTransition.animateClipTransition(
        image: image,
        from: start,
        to: end,
        in: feedCV,
        completion: {}
      )
    }

    dismiss(animated: false)
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
      withReuseIdentifier: ZoomableImageCell.reuseID,
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
    let page = currentPage
    guard page != lastReportedPage else { return }
    lastReportedPage = page
    onPageChange?(page)
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
