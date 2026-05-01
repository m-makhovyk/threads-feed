import UIKit

extension UIView {

  func findOutermostCollectionView() -> UICollectionView? {
    var result: UICollectionView?
    var current: UIView? = superview
    while let v = current {
      if let cv = v as? UICollectionView {
        result = cv
      }
      current = v.superview
    }
    return result
  }
}
