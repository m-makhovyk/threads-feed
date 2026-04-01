import UIKit
import SnapKit

class ImagePreviewViewController: UIViewController {

  private let imageURLs: [URL]
  private let initialIndex: Int
  private var hasScrolledToInitialPage = false

  private lazy var collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
    cv.isPagingEnabled = true
    cv.showsHorizontalScrollIndicator = false
    cv.backgroundColor = .black
    cv.register(ZoomableImageCell.self, forCellWithReuseIdentifier: ZoomableImageCell.reuseID)
    return cv
  }()

  private let closeButton: UIButton = {
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
      make.size.equalTo(40)
    }

    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
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
    dismiss(animated: true)
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
}
