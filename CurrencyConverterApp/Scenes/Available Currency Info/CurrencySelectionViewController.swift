//
//  CurrencySelectionViewController.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import UIKit
import Combine

class CurrencySelectionViewController: UIViewController {
    weak var appCoordinator: SupportedCurrencyCoordinator?
    var viewModel: CurrencySelectionViewModel?
    
    private let selectionTableview: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.estimatedRowHeight = 80
        tableView.rowHeight = UITableView.automaticDimension
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
        dataSource = TableDataSource(selectionTableview, baseCurrency: viewModel?.baseCurrency ?? "USD")
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
        
        viewModel?.$currencyFetchingError.sink(receiveValue: { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showErrorAlert(error)
        })
        .store(in: &cancellables)
        
        viewModel?.$isProcessingData.sink(receiveValue: {[weak self] toggle in
            self?.appCoordinator?.showLoadingIndicatorView(toggle: toggle)
        }).store(in: &cancellables)
        
        viewModel?.fetchAvailableCurrencies()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        appCoordinator?.didFinishSelection()
    }
    
    func setupUIAndConstraint() {
        self.title = "Supported Currencies"
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
        guard let item = dataSource?.itemIdentifier(for: indexPath) else { return }
        appCoordinator?.didFinishSelection(CurrencyInfo(code: item.code, name: item.name))
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
}

extension CurrencySelectionViewController: AlertDisplayable {}


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
