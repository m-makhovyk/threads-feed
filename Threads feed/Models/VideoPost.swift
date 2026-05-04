import Foundation

struct VideoPost {
  let author: Author
  let text: String?
  let attachments: [VideoAttachment]
  let createdAt: Date
}
