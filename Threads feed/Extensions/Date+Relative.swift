import Foundation

extension Date {

  func relativeFormatted() -> String {
    let interval = Date().timeIntervalSince(self)
    let minutes = Int(interval / 60)
    let hours = Int(interval / 3600)
    let days = Int(interval / 86400)

    if minutes < 1 {
      return "now"
    } else if minutes < 60 {
      return "\(minutes)m"
    } else if hours < 24 {
      return "\(hours)h"
    } else {
      return "\(days)d"
    }
  }
}
