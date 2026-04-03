import UIKit
import SnapKit
import NukeUI

class ImageAttachmentsView: UIView {

  // 16 (cell padding) + 40 (avatar) + 10 (gap)
  static let leadingInset: CGFloat = 16 + 40 + 10
  static let imageCornerRadius: CGFloat = 12

  var onImageTapped: ((_ urls: [URL], _ index: Int) -> Void)?

  private var collectionView: UICollectionView!
  private var urls: [URL] = []

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
    layout.minimumLineSpacing = 8

    collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.alwaysBounceHorizontal = true
    collectionView.backgroundColor = .clear
    collectionView.register(
      AttachmentImageCell.self,
      forCellWithReuseIdentifier: AttachmentImageCell.reuseID
    )
    addSubview(collectionView)

    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }

    collectionView.contentInset = UIEdgeInsets(
      top: 0,
      left: Self.leadingInset,
      bottom: 0,
      right: 16
    )
  }

  func configure(with urls: [URL]) {
    self.urls = urls
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -Self.leadingInset, y: 0)
    collectionView.isScrollEnabled = urls.count > 1
  }

  func imageView(at index: Int) -> UIView? {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentImageCell else { return nil }
    return cell.lazyImageView
  }

  func image(at index: Int) -> UIImage? {
    let indexPath = IndexPath(item: index, section: 0)
    guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentImageCell else { return nil }
    return cell.lazyImageView.imageView.image
  }
}

// MARK: - Data Source

extension ImageAttachmentsView: UICollectionViewDataSource {

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    urls.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: AttachmentImageCell.reuseID,
      for: indexPath
    ) as! AttachmentImageCell
    cell.configure(with: urls[indexPath.item])
    return cell
  }
}

// MARK: - Delegate

extension ImageAttachmentsView: UICollectionViewDelegateFlowLayout {

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    CGSize(width: 280, height: collectionView.bounds.height)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    didSelectItemAt indexPath: IndexPath
  ) {
    onImageTapped?(urls, indexPath.item)
  }
}

// MARK: - Attachment Cell

private class AttachmentImageCell: UICollectionViewCell {

  static let reuseID = "AttachmentImageCell"

  let lazyImageView = LazyImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    lazyImageView.imageView.contentMode = .scaleAspectFill
    lazyImageView.clipsToBounds = true
    lazyImageView.layer.cornerRadius = ImageAttachmentsView.imageCornerRadius
    lazyImageView.placeholderView = makePlaceholder()
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

  private func makePlaceholder() -> UIView {
    let view = UIView()
    view.backgroundColor = .secondarySystemBackground
    view.layer.cornerRadius = ImageAttachmentsView.imageCornerRadius
    return view
  }
}
