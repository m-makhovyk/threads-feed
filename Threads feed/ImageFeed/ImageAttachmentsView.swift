import UIKit
import SnapKit
import NukeUI

class ImageAttachmentsView: UIView {

  var onImageTapped: ((_ urls: [URL], _ index: Int) -> Void)?

  private var collectionView: UICollectionView!
  private var attachments: [ImageAttachment] = []
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
      AttachmentImageCell.self,
      forCellWithReuseIdentifier: AttachmentImageCell.reuseIdentifier
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

  func configure(with attachments: [ImageAttachment]) {
    self.attachments = attachments
    blackedOutIndex = nil
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = attachments.count > 1
  }

  func setBlackedOut(at index: Int) {
    blackedOutIndex = index
    for indexPath in collectionView.indexPathsForVisibleItems {
      guard let cell = collectionView.cellForItem(at: indexPath) as? AttachmentImageCell else { continue }
      cell.setBlackedOut(indexPath.item == index)
    }
  }

  func clearBlackOut() {
    defer {
      blackedOutIndex = nil
    }

    guard let blackedOutIndex else { return }

    let indexPath = IndexPath(item: blackedOutIndex, section: 0)
    if let cell = collectionView.cellForItem(at: indexPath) as? AttachmentImageCell {
      cell.setBlackedOut(false)
    }
  }

  func scrollToImage(at index: Int, animated: Bool) {
    guard attachments.indices.contains(index) else { return }
    let indexPath = IndexPath(item: index, section: 0)
    collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
    if !animated {
      collectionView.layoutIfNeeded()
    }
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
    attachments.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: AttachmentImageCell.reuseIdentifier,
      for: indexPath
    ) as! AttachmentImageCell
    cell.configure(with: attachments[indexPath.item].url)
    cell.setBlackedOut(indexPath.item == blackedOutIndex)
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
    onImageTapped?(urls, indexPath.item)
  }
}

// MARK: - Attachment Cell

private class AttachmentImageCell: UICollectionViewCell {

  static let reuseIdentifier = "AttachmentImageCell"

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
