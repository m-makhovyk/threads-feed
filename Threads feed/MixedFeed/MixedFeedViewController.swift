import UIKit
import SnapKit

class MixedFeedViewController: UIViewController {

  private var collectionView: UICollectionView!
  private let posts = MockData.mixedPosts

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupCollectionView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    collectionView.contentInset.bottom = 100
  }

  private func setupCollectionView() {
    let itemSize = NSCollectionLayoutSize(
      widthDimension: .fractionalWidth(1),
      heightDimension: .estimated(400)
    )
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let group = NSCollectionLayoutGroup.vertical(
      layoutSize: itemSize,
      subitems: [item]
    )
    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)

    collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: layout
    )
    collectionView.dataSource = self
    collectionView.showsVerticalScrollIndicator = false
    collectionView.register(
      MixedPostCell.self,
      forCellWithReuseIdentifier: MixedPostCell.reuseIdentifier
    )
    view.addSubview(collectionView)

    collectionView.snp.makeConstraints { make in
      make.edges.equalToSuperview()
    }
  }
}

extension MixedFeedViewController: UICollectionViewDataSource {

  func collectionView(
    _ collectionView: UICollectionView,
    numberOfItemsInSection section: Int
  ) -> Int {
    posts.count
  }

  func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: MixedPostCell.reuseIdentifier,
      for: indexPath
    ) as! MixedPostCell
    cell.configure(with: posts[indexPath.item])
    return cell
  }
}
