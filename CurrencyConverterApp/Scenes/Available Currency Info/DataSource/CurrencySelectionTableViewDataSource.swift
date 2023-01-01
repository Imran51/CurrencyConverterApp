//
//  CurrencySelectionTableViewDataSource.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/30/22.
//

import Foundation
import UIKit

final class TableDataSource: UITableViewDiffableDataSource<Int, CurrencyInfo> {
    init(_ tableView: UITableView, baseCurrency: String) {
        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: CurrencySelectionTableViewCell.self),
                for: indexPath
            ) as! CurrencySelectionTableViewCell
            cell.configure(currencyInfo: item)
            cell.accessoryType = baseCurrency == item.code ? .checkmark : .none
            return cell
        }
    }
    
    func reload(_ data: [CurrencyInfo], animated: Bool = false) {
        var snapShot = snapshot()
        snapShot.deleteAllItems()
        snapShot.appendSections([0])
        snapShot.appendItems(data, toSection: 0)
        apply(snapShot, animatingDifferences: animated)
    }
}
