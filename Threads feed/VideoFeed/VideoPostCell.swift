import UIKit
import SnapKit
import NukeUI

class VideoPostCell: UICollectionViewCell {

  static let reuseIdentifier = "VideoPostCell"

  var onVideoTapped: ((_ urls: [URL], _ index: Int) -> Void)? {
    get { attachmentsView.onVideoTapped }
    set { attachmentsView.onVideoTapped = newValue }
  }

  private let avatarImageView = LazyImageView()
  private let headerStack = UIStackView()
  private let usernameLabel = UILabel()
  private let dateLabel = UILabel()
  private let contentStack = UIStackView()
  private let postTextLabel = UILabel()
  private let attachmentsView = VideoAttachmentsView()

  private var contentStackTopConstraint: Constraint?
  private var contentStackCenterYConstraint: Constraint?
  private var attachmentsTopToContentConstraint: Constraint?
  private var attachmentsTopToAvatarConstraint: Constraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    avatarImageView.url = nil
    usernameLabel.text = nil
    dateLabel.text = nil
    postTextLabel.text = nil
    postTextLabel.isHidden = false

    attachmentsView.isHidden = true
    attachmentsView.reset()
    attachmentsView.onVideoTapped = nil
  }

  func setActive(_ active: Bool) {
    attachmentsView.setActive(active)
  }

  private func setupViews() {
    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.clipsToBounds = true
    avatarImageView.layer.cornerRadius = LayoutConstants.avatarCornerRadius
    avatarImageView.placeholderView = makeAvatarPlaceholder()
    contentView.addSubview(avatarImageView)

    usernameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
    dateLabel.font = .systemFont(ofSize: 14)
    dateLabel.textColor = .secondaryLabel

    headerStack.axis = .horizontal
    headerStack.spacing = 6
    headerStack.addArrangedSubview(usernameLabel)
    headerStack.addArrangedSubview(dateLabel)
    dateLabel.setContentHuggingPriority(.required, for: .horizontal)
    usernameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

    postTextLabel.font = .systemFont(ofSize: 15)
    postTextLabel.numberOfLines = 0

    contentStack.axis = .vertical
    contentStack.spacing = 4
    contentStack.addArrangedSubview(headerStack)
    contentStack.addArrangedSubview(postTextLabel)
    contentView.addSubview(contentStack)
    contentView.addSubview(attachmentsView)

    avatarImageView.snp.makeConstraints { make in
      make.leading.equalToSuperview().offset(16)
      make.top.equalToSuperview().offset(12)
      make.size.equalTo(LayoutConstants.avatarSize)
    }

    contentStack.snp.makeConstraints { make in
      make.leading.equalTo(avatarImageView.snp.trailing).offset(LayoutConstants.avatarToContentSpacing)
      make.trailing.equalToSuperview().offset(-16)
      contentStackTopConstraint = make.top.equalTo(avatarImageView).constraint
      contentStackCenterYConstraint = make.centerY.equalTo(avatarImageView).constraint
    }
    contentStackCenterYConstraint?.deactivate()

    attachmentsView.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.height.equalTo(LayoutConstants.attachmentHeight)
      make.bottom.equalToSuperview().offset(-12).priority(999)
      attachmentsTopToContentConstraint = make.top.equalTo(contentStack.snp.bottom).constraint
      attachmentsTopToAvatarConstraint = make.top.equalTo(avatarImageView.snp.bottom).constraint
    }
    attachmentsTopToAvatarConstraint?.deactivate()
  }

  func configure(with post: VideoPost) {
    avatarImageView.url = post.author.avatarURL
    usernameLabel.text = post.author.username
    dateLabel.text = post.createdAt.relativeFormatted()

    let hasText = post.text?.isEmpty == false
    postTextLabel.isHidden = !hasText
    postTextLabel.text = post.text

    contentStackTopConstraint?.isActive = hasText
    contentStackCenterYConstraint?.isActive = !hasText

    let attachmentHeight = attachmentHeight(for: post.attachments)
    let hasAttachments = attachmentHeight > 0
    attachmentsView.isHidden = !hasAttachments
    attachmentsTopToContentConstraint?.isActive = hasText
    attachmentsTopToAvatarConstraint?.isActive = !hasText
    let topOffset = hasAttachments ? 10 : 0
    attachmentsTopToContentConstraint?.update(offset: topOffset)
    attachmentsTopToAvatarConstraint?.update(offset: topOffset)
    attachmentsView.snp.updateConstraints { make in
      make.height.equalTo(attachmentHeight)
    }
    if hasAttachments {
      attachmentsView.configure(with: post.attachments)
    } else {
      attachmentsView.reset()
    }
  }

  private func attachmentHeight(for attachments: [VideoAttachment]) -> CGFloat {
    guard !attachments.isEmpty else { return 0 }
    guard attachments.count == 1 else { return LayoutConstants.attachmentHeight }

    let availableWidth = contentView.bounds.width - LayoutConstants.contentLeadingInset - 16
    let rawHeight = availableWidth / attachments[0].aspectRatio
    return min(max(rawHeight, LayoutConstants.attachmentMinHeight), LayoutConstants.attachmentMaxHeight)
  }

  private func makeAvatarPlaceholder() -> UIView {
    let view = UIView()
    view.backgroundColor = .tertiarySystemFill
    view.layer.cornerRadius = LayoutConstants.avatarCornerRadius
    return view
  }
}
