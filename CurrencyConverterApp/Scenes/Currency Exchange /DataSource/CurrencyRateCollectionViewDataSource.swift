//
//  CurrencyRateCollectionViewDataSource.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/30/22.
//

import Foundation
import UIKit

final class CurrencyRateExchangeCollectionDataSource: UICollectionViewDiffableDataSource<Int, ExchangeRate> {
    init(_ collectionView: UICollectionView) {
        super.init(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: String(describing: CurrencyCollectionViewCell.self),
                for: indexPath
            ) as! CurrencyCollectionViewCell
            cell.configure(item)
            
            return cell
        }
    }
    
    func update(_ items: [ExchangeRate], animated: Bool = false) {
        var snapShot = snapshot()
        snapShot.deleteAllItems()
        snapShot.appendSections([0])
        snapShot.appendItems(items, toSection: 0)
        apply(snapShot, animatingDifferences: animated)
    }
}
