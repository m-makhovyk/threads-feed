import Foundation

struct ImagePost {
  let author: Author
  let text: String?
  let attachments: [ImageAttachment]
  let createdAt: Date
}
