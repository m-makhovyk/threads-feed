import UIKit
import SnapKit

class ImageFeedViewController: UIViewController {

  private var collectionView: UICollectionView!
  private let posts = MockData.imagePosts

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupCollectionView()
  }

  private func setupCollectionView() {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(400)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: itemSize,
      subitems: [item]
    )
    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)

    collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.dataSource = self
    collectionView.showsVerticalScrollIndicator = false
    collectionView.register(
      ImagePostCell.self,
      forCellWithReuseIdentifier: ImagePostCell.reuseIdentifier
    )
    view.addSubview(collectionView)

    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}

extension ImageFeedViewController: UICollectionViewDataSource {

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    posts.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: ImagePostCell.reuseIdentifier,
      for: indexPath
    ) as! ImagePostCell
    cell.configure(with: posts[indexPath.item])
    cell.onImageTapped = { [weak self] urls, index in
      guard let self else { return }
      let preview = ImagePreviewViewController(imageURLs: urls, initialIndex: index)
      preview.zoomTransition.sourceProvider = { [weak self, weak preview] pageIndex in
        guard let self else { return nil }
        return self.sourceInfo(forPage: pageIndex, at: indexPath, previewImage: preview?.currentImage)
      }
      preview.onPageChange = { [weak cell] page in
        cell?.scrollToAttachment(at: page, animated: false)
      }
      preview.onBlackoutIndex = { [weak cell] index in
        cell?.setBlackedOutAttachment(at: index)
      }
      preview.onClearBlackout = { [weak cell] in
        cell?.clearBlackoutAttachment()
      }
      self.present(preview, animated: true)
    }
    return cell
  }
}

// MARK: - Transition Source

extension ImageFeedViewController {

  private func sourceInfo(
    forPage pageIndex: Int,
    at indexPath: IndexPath,
    previewImage: UIImage?
  ) -> ImageZoomTransition.SourceInfo? {
    guard let cell = collectionView.cellForItem(at: indexPath) as? ImagePostCell else { return nil }
    guard let sourceView = cell.imageView(forAttachmentAt: pageIndex) else { return nil }
    guard let image = previewImage ?? cell.image(forAttachmentAt: pageIndex) else { return nil }
    return ImageZoomTransition.SourceInfo(
      view: sourceView,
      image: image,
      cornerRadius: LayoutConstants.attachmentCornerRadius
    )
  }
}
