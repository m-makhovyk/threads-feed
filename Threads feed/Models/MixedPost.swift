import Foundation

struct MixedPost {
  let author: Author
  let text: String?
  let attachments: [MixedAttachment]
  let createdAt: Date
}
