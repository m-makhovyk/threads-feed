import UIKit
import SnapKit
import AVFoundation
import NukeUI

class MixedAttachmentsView: UIView {

  private var collectionView: UICollectionView!
  private var attachments: [MixedAttachment] = []

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
      MixedImagePageCell.self,
      forCellWithReuseIdentifier: MixedImagePageCell.reuseIdentifier
    )
    collectionView.register(
      MixedVideoPageCell.self,
      forCellWithReuseIdentifier: MixedVideoPageCell.reuseIdentifier
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

  func configure(with attachments: [MixedAttachment]) {
    self.attachments = attachments
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = attachments.count > 1
  }

  func reset() {
    attachments = []
    collectionView.reloadData()
    collectionView.contentOffset = CGPoint(x: -LayoutConstants.contentLeadingInset, y: 0)
    collectionView.isScrollEnabled = false
  }
}

// MARK: - Data Source

extension MixedAttachmentsView: UICollectionViewDataSource {

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
        withReuseIdentifier: MixedImagePageCell.reuseIdentifier,
        for: indexPath
      ) as! MixedImagePageCell
      cell.configure(with: attachment.url)
      return cell
    case .video(let attachment):
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: MixedVideoPageCell.reuseIdentifier,
        for: indexPath
      ) as! MixedVideoPageCell
      cell.configure(with: attachment.url)
      return cell
    }
  }
}

// MARK: - Delegate

extension MixedAttachmentsView: UICollectionViewDelegateFlowLayout {

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
}

// MARK: - Image page cell

private class MixedImagePageCell: UICollectionViewCell {

  static let reuseIdentifier = "MixedImagePageCell"

  let lazyImageView = LazyImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)

    lazyImageView.imageView.contentMode = .scaleAspectFill
    lazyImageView.clipsToBounds = true
    lazyImageView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
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
    view.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    return view
  }
}

// MARK: - Video page cell

private class MixedVideoPageCell: UICollectionViewCell {

  static let reuseIdentifier = "MixedVideoPageCell"

  let playerView = VideoPlayerView()
  private(set) var playerContext: VideoPlayerContext?

  override init(frame: CGRect) {
    super.init(frame: frame)

    playerView.backgroundColor = .secondarySystemBackground
    playerView.layer.cornerRadius = LayoutConstants.attachmentCornerRadius
    playerView.layer.masksToBounds = true
    playerView.playerLayer.videoGravity = .resizeAspectFill
    contentView.addSubview(playerView)

    playerView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with url: URL) {
    if playerContext?.url == url {
      playerView.playerLayer.player = playerContext?.player
      return
    }
    playerContext?.pause()
    let context = VideoPlayerContext(url: url, muted: true)
    playerContext = context
    playerView.playerLayer.player = context.player
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    playerContext?.pause()
    playerContext = nil
    playerView.playerLayer.player = nil
  }
}
