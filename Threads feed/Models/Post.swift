import Foundation

struct Post {
  let author: Author
  let text: String?
  let attachments: [ImageAttachment]
  let createdAt: Date
}
