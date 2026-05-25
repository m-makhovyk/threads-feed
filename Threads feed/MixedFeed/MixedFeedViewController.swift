import UIKit
import SnapKit

class MixedFeedViewController: UIViewController {

  private var collectionView: UICollectionView!
  private let posts = MockData.mixedPosts
  private var activeIndexPath: IndexPath?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupCollectionView()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updateActiveCell()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.contentInset.bottom = 100
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    guard !(presentedViewController is VideoPreviewViewController) else { return }
    setActive(false, at: activeIndexPath)
    activeIndexPath = nil
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
    collectionView.delegate = self
    collectionView.showsVerticalScrollIndicator = false
    collectionView.register(
      MixedPostCell.self,
      forCellWithReuseIdentifier: MixedPostCell.reuseIdentifier
    )
    view.addSubview(collectionView)

    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  private func updateActiveCell() {
    let viewportCenterY = collectionView.bounds.midY
    var bestIndexPath: IndexPath?
    var bestDistance: CGFloat = .greatestFiniteMagnitude
    for indexPath in collectionView.indexPathsForVisibleItems {
      guard postContainsVideo(at: indexPath) else { continue }
      guard let cell = collectionView.cellForItem(at: indexPath) else { continue }
      let distance = abs(cell.frame.midY - viewportCenterY)
      if distance < bestDistance {
        bestDistance = distance
        bestIndexPath = indexPath
      }
    }
    guard bestIndexPath != activeIndexPath else { return }
    setActive(false, at: activeIndexPath)
    activeIndexPath = bestIndexPath
    setActive(true, at: bestIndexPath)
  }

  private func setActive(_ active: Bool, at indexPath: IndexPath?) {
    guard let indexPath else { return }
    (collectionView.cellForItem(at: indexPath) as? MixedPostCell)?.setActive(active)
  }

  private func postContainsVideo(at indexPath: IndexPath) -> Bool {
    posts[indexPath.item].attachments.contains {
      if case .video = $0 { return true }
      return false
    }
  }
}

extension MixedFeedViewController: UICollectionViewDataSource {

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
      withReuseIdentifier: MixedPostCell.reuseIdentifier,
      for: indexPath
    ) as! MixedPostCell
    cell.configure(with: posts[indexPath.item])
    cell.onAttachmentTapped = { [weak self, weak cell] attachments, index in
      guard let self else { return }
      let pausedActivePath: IndexPath? = (self.activeIndexPath != indexPath) ? self.activeIndexPath : nil
      if let pausedActivePath {
        self.setActive(false, at: pausedActivePath)
      }
      let initialPlayerContext: VideoPlayerContext? = {
        guard case .video = attachments[index] else { return nil }
        return cell?.playerContext(forAttachmentAt: index)
      }()
      let preview = MixedPreviewViewController(
        attachments: attachments,
        initialIndex: index,
        initialPlayerContext: initialPlayerContext
      )
      preview.zoomTransition.sourceProvider = { [weak self, weak preview] pageIndex in
        guard let self else { return nil }
        return self.sourceInfo(forPage: pageIndex, at: indexPath, preview: preview)
      }
      preview.onPageChange = { [weak cell] page in
        cell?.scrollToAttachment(at: page, animated: false)
      }
      preview.onBlackoutIndex = { [weak cell, weak preview] index in
        cell?.setBlackedOutAttachment(at: index, preserving: preview?.currentPlayerContext())
      }
      preview.onClearBlackout = { [weak self, weak cell] in
        cell?.clearBlackoutAttachment()
        if let pausedActivePath {
          self?.setActive(true, at: pausedActivePath)
        }
      }
      preview.onPlayerContextReadyForFeed = { [weak cell] index, context in
        cell?.replacePlayerContext(context, forAttachmentAt: index)
      }
      self.present(preview, animated: true)
    }
    return cell
  }
}

// MARK: - Transition Source

extension MixedFeedViewController {

  private func sourceInfo(
    forPage pageIndex: Int,
    at indexPath: IndexPath,
    preview: MixedPreviewViewController?
  ) -> MixedZoomTransition.SourceInfo? {
    guard let cell = collectionView.cellForItem(at: indexPath) as? MixedPostCell else { return nil }
    guard let sourceView = cell.attachmentView(forAttachmentAt: pageIndex) else { return nil }
    guard posts[indexPath.item].attachments.indices.contains(pageIndex) else { return nil }

    let attachment = posts[indexPath.item].attachments[pageIndex]
    let contentSize = CGSize(width: attachment.width, height: attachment.height)

    switch attachment {
    case .image:
      guard let image = preview?.currentImage(at: pageIndex) ?? cell.image(forAttachmentAt: pageIndex) else { return nil }
      return MixedZoomTransition.SourceInfo(
        view: sourceView,
        contentSize: contentSize,
        cornerRadius: LayoutConstants.attachmentCornerRadius,
        media: .image(image)
      )
    case .video:
      let context = preview?.playerContext(forPage: pageIndex) ?? cell.playerContext(forAttachmentAt: pageIndex)
      guard let context else { return nil }
      return MixedZoomTransition.SourceInfo(
        view: sourceView,
        contentSize: contentSize,
        cornerRadius: LayoutConstants.attachmentCornerRadius,
        media: .video(context)
      )
    }
  }
}

extension MixedFeedViewController: UICollectionViewDelegate {

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    updateActiveCell()
  }

  func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    updateActiveCell()
  }
}
