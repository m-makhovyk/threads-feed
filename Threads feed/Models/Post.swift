import Foundation

struct Post {
  let author: Author
  let text: String?
  let attachments: [URL]
  let createdAt: Date
}
