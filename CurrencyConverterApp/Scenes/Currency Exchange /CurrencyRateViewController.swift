//
//  ViewController.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import UIKit
import Combine

class CurrencyRateViewController: UIViewController {
    weak var appCoordinator: AppCoordinator?
    var viewModel: CurrencyRateViewModel?
    
    private lazy var collectionView: UICollectionView = {
        let layout = createCollectionViewLayout()
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.register(CurrencyCollectionViewCell.self, forCellWithReuseIdentifier: String(describing: CurrencyCollectionViewCell.self))
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.backgroundColor = .clear
        collection.dataSource = dataSource
        
        return collection
    }()
    
    private let currenncyInputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter currency amount"
        textField.keyboardType = .decimalPad
        textField.returnKeyType = .done
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: textField.frame.height))
        textField.rightViewMode = .always
        
        textField.layer.masksToBounds = true
        textField.layer.borderColor = UIColor.quaternaryLabel.cgColor
        textField.layer.borderWidth = 1
        textField.layer.cornerRadius = 20
        
        return textField
    }()
    
    private let currentCurrencyLabel: UILabel = {
        let label = UILabel()
        label.text = "U.S. dollar-based currency"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right
        
        return label
    }()
    
    private let currencyPickerButton: UIButton = {
        let button = UIButton(type: .system)
        var buttonConfig: UIButton.Configuration = .bordered()
        buttonConfig.cornerStyle = .capsule
        button.configuration = buttonConfig
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        button.setTitle("USD", for: .normal)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = .label
        
        return button
    }()
    
    private let horizontalCurrencyPickerContainer: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 10
        
        return stack
    }()
    
    private let currencyConatinerStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.spacing = 15
        
        return stack
    }()
    
    private var dataSource: CurrencyRateCollectionDataSource?
    private var cancellables = Set<AnyCancellable>()
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let fraction: CGFloat = 1 / 3.1
        
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(70))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(5)
        // Section
        let section = NSCollectionLayoutSection(group: group)
        let inset: CGFloat = 2.5
        
        // after item declaration…
        item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        
        // after section delcaration…
        section.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        section.interGroupSpacing = 5
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        
        dataSource = CurrencyRateCollectionDataSource(collectionView)
        
        viewModel?.$exchangeRate
            .sink { [weak self] data in
                self?.dataSource?.update(data)
            }
            .store(in: &cancellables)
        
        viewModel?.$currencyFetchingError.sink(receiveValue: { [weak self] error in
            guard let self = self, let error = error else { return }
            self.showErrorAlert(error)
        })
        .store(in: &cancellables)
        
        viewModel?.$baseCurrency.sink(receiveValue: { [weak self] text in
            guard let self = self else { return }
            self.currencyPickerButton.setTitle(text, for: .normal)
        }).store(in: &cancellables)
        
        viewModel?.$isProcessingData.sink(receiveValue: {[weak self] toggle in
            self?.appCoordinator?.showLoadingIndicatorView(toggle: toggle ?? true)
        }).store(in: &cancellables)
        
        viewModel?.fetchLatestCurrencyRate()
        appCoordinator?.delegate = self
    }
    
    private func setupUI() {
        title = "Currency Exchange Rate"
        view.addSubview(currencyConatinerStackView)
        view.addSubview(collectionView)
        
        currencyConatinerStackView.addArrangedSubview(currenncyInputTextField)
        currencyConatinerStackView.addArrangedSubview(horizontalCurrencyPickerContainer)
        horizontalCurrencyPickerContainer.addArrangedSubview(currentCurrencyLabel)
        horizontalCurrencyPickerContainer.addArrangedSubview(currencyPickerButton)
        currenncyInputTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)
        setupConstraint()
        currencyPickerButton.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func buttonTapped(_ sender: UIButton) {
        appCoordinator?.showCurrencySelectionViewController(withBaseCurrencyCode: viewModel?.baseCurrency ?? "USD")
    }
    
    @objc func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        currenncyInputTextField.resignFirstResponder()
    }
    
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            currencyConatinerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            currencyConatinerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            currencyConatinerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            currencyConatinerStackView.heightAnchor.constraint(equalToConstant: 90),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            collectionView.topAnchor.constraint(equalTo: currencyConatinerStackView.bottomAnchor, constant: 20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
}

extension CurrencyRateViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        viewModel?.changeCurrentRate(for: textField.text ?? "1")
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
}

extension CurrencyRateViewController: AlertDisplayable {  }

extension CurrencyRateViewController {
    final class CurrencyRateCollectionDataSource: UICollectionViewDiffableDataSource<Int, ExchangeRate> {
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
}

extension CurrencyRateViewController: AppCoordinatorDelegate {
    func didSelectedCurrency(info: CurrencyInfo) {
        currencyPickerButton.setTitle(info.code, for: .normal)
        viewModel?.exchangeCurrency(forAmount: Double(currenncyInputTextField.text ?? "1") ?? 1, andBase: info.code)
    }
}
