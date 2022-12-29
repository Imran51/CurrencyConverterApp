//
//  CurrencySelectionViewController.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import UIKit
import Combine

class CurrencySelectionViewController: UIViewController {
    var appCoordinator: Coordinator?
    var viewModel: CurrencySelectionViewModel?
    
    private let selectionTableview: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 50
        tableView.tableFooterView = UIView()
        tableView.register(CurrencySelectionTableViewCell.self, forCellReuseIdentifier: String(describing: CurrencySelectionTableViewCell.self))
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
       
        return tableView
    }()
    
    private var dataSource: TableDataSource?
    private var cancellables = Set<AnyCancellable>()
    
    override func loadView() {
        super.loadView()
        
        view.addSubview(selectionTableview)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        dataSource = TableDataSource(selectionTableview)
        dataSource?.defaultRowAnimation = .fade
        
        selectionTableview.dataSource = dataSource
        selectionTableview.delegate = self
        
        setupUIAndConstraint()
        
        viewModel?.$availableCurrencies
            .sink(receiveValue: {[weak self] listInfo in
                if !listInfo.isEmpty {
                    self?.dataSource?.reload(listInfo)
                }
        })
        .store(in: &cancellables)
        
        viewModel?.fetchAvailableCurrencies()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
    }
    
    func setupUIAndConstraint() {
        NSLayoutConstraint.activate([
            selectionTableview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            selectionTableview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            selectionTableview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            selectionTableview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        ])
    }
}

extension CurrencySelectionViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let items = dataSource?.itemIdentifier(for: indexPath) else { return }
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        50
    }
}


final class TableDataSource: UITableViewDiffableDataSource<Int, CurrencyInfo> {
    init(_ tableView: UITableView) {
        super.init(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: CurrencySelectionTableViewCell.self),
                for: indexPath
            ) as! CurrencySelectionTableViewCell
            cell.selectionStyle = .none
            cell.configure(currencyInfo: item)
            
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
