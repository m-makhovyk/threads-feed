import UIKit
import SnapKit
import NukeUI

class PostCell: UICollectionViewCell {

  static let reuseIdentifier = "PostCell"

  private let avatarImageView = LazyImageView()
  private let headerStack = UIStackView()
  private let usernameLabel = UILabel()
  private let dateLabel = UILabel()
  private let contentStack = UIStackView()
  private let postTextLabel = UILabel()
  private let attachmentsView = ImageAttachmentsView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupViews() {
    avatarImageView.contentMode = .scaleAspectFill
    avatarImageView.clipsToBounds = true
    avatarImageView.layer.cornerRadius = 20
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
      make.size.equalTo(40)
    }

    contentStack.snp.makeConstraints { make in
      make.leading.equalTo(avatarImageView.snp.trailing).offset(10)
      make.top.equalTo(avatarImageView)
      make.trailing.equalToSuperview().offset(-16)
    }

    attachmentsView.snp.makeConstraints { make in
      make.leading.trailing.equalToSuperview()
      make.top.equalTo(contentStack.snp.bottom).offset(10)
      make.height.equalTo(350)
      make.bottom.equalToSuperview().offset(-12)
    }
  }

  func configure(with post: Post) {
    avatarImageView.url = post.author.avatarURL
    usernameLabel.text = post.author.username
    dateLabel.text = post.createdAt.relativeFormatted()

    postTextLabel.isHidden = post.text == nil
    postTextLabel.text = post.text

    let hasAttachments = !post.attachments.isEmpty
    attachmentsView.isHidden = !hasAttachments
    attachmentsView.snp.updateConstraints { make in
      make.height.equalTo(hasAttachments ? 350 : 0)
      make.top.equalTo(contentStack.snp.bottom).offset(hasAttachments ? 10 : 0)
    }
    if hasAttachments {
      attachmentsView.configure(with: post.attachments)
    }
  }

  private func makeAvatarPlaceholder() -> UIView {
    let view = UIView()
    view.backgroundColor = .tertiarySystemFill
    view.layer.cornerRadius = 20
    return view
  }
}
