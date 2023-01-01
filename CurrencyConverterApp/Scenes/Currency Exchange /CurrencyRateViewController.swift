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
    
    func getLabel() -> UILabel {
        let label = UILabel()
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        
        return label
    }
    
    private lazy var currentCurrencyFromLabel: UILabel = {
        let label = getLabel()
        label.text = "1 USD"
        return label
    }()
    
    private lazy var currentCurrencyToLabel: UILabel = {
        let label = getLabel()
        label.text = "102.33 BDT"
        return label
    }()
    
    private func getButton() -> UIButton {
        let button = UIButton(type: .system)
        var buttonConfig: UIButton.Configuration = .bordered()
        buttonConfig.cornerStyle = .capsule
        button.configuration = buttonConfig
        button.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.semanticContentAttribute = .forceRightToLeft
        button.tintColor = .label
        
        return button
    }
    
    private lazy var currencyPickerFromButton: UIButton = {
       let button = getButton()
        button.setTitle("USD", for: .normal)
        return button
    }()
    
    private lazy var currencyPickerToButton: UIButton = {
       let button = getButton()
        button.setTitle("BDT", for: .normal)
        return button
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
    
    private let currencyConatinerFromStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 5
        
        return stack
    }()
    
    private let currencyConatinerToStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 5
        
        return stack
    }()
    
    private var dataSource: CurrencyRateCollectionDataSource?
    private var cancellables = Set<AnyCancellable>()
    private var isFromButtonTapped = false
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let fraction: CGFloat = 1 / 2.1
        
        // Item
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        // Group
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90))
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
        
        viewModel?.exchangeRate.sink(receiveCompletion: { [weak self] res in
            guard let self = self else { return }
            switch res {
            case .failure(let error):
                self.showErrorAlert(error)
            case .finished:
                print("finished.")
            }
        }, receiveValue: { [weak self] exchangeRates in
            guard let self = self else { return }
            self.dataSource?.update(exchangeRates)
        })
        .store(in: &cancellables)
        
        viewModel?.fromBaseCurrency.sink(receiveValue: { [weak self] text in
            guard let self = self else { return }
            self.currencyPickerFromButton.setTitle(text, for: .normal)
        }).store(in: &cancellables)
        
        viewModel?.toBaseCurrency.sink(receiveValue: { [weak self] text in
            guard let self = self else { return }
            self.currencyPickerToButton.setTitle(text, for: .normal)
        }).store(in: &cancellables)
        
        viewModel?.fromExchangeRate.sink(receiveValue: { [weak self] text in
            guard let self = self else { return }
            self.currentCurrencyFromLabel.text = text
        }).store(in: &cancellables)
        
        viewModel?.toExchangeRate.sink(receiveValue: { [weak self] text in
            guard let self = self else { return }
            self.currentCurrencyToLabel.text = text
        }).store(in: &cancellables)
        
        viewModel?.isProcessingData.sink(receiveValue: {[weak self] toggle in
            self?.appCoordinator?.showLoadingIndicatorView(toggle: toggle)
        }).store(in: &cancellables)
        
        viewModel?.fetchLatestCurrencyRate()
        appCoordinator?.delegate = self
    }
    
    private func setupUI() {
        title = "Currency Exchange Rate"
        view.addSubview(currencyConatinerStackView)
        view.addSubview(collectionView)
        
        currencyConatinerStackView.addArrangedSubview(currenncyInputTextField)
        currencyConatinerStackView.addArrangedSubview(currencyConatinerFromStackView)
        currencyConatinerStackView.addArrangedSubview(currencyConatinerToStackView)
        
        currencyConatinerFromStackView.addArrangedSubview(currentCurrencyFromLabel)
        currencyConatinerFromStackView.addArrangedSubview(currencyPickerFromButton)
        currencyConatinerToStackView.addArrangedSubview(currentCurrencyToLabel)
        currencyConatinerToStackView.addArrangedSubview(currencyPickerToButton)
        
        currenncyInputTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)
        setupConstraint()
        currencyPickerFromButton.addTarget(self, action: #selector(fromButtonTapped(_:)), for: .touchUpInside)
        currencyPickerToButton.addTarget(self, action: #selector(toButtonTapped(_:)), for: .touchUpInside)
    }
    
    @objc func fromButtonTapped(_ sender: UIButton) {
        isFromButtonTapped = true
        appCoordinator?.showCurrencySelectionViewController(withBaseCurrencyCode: viewModel?.fromBaseCurrency.value ?? "USD")
    }
    
    @objc func toButtonTapped(_ sender: UIButton) {
        isFromButtonTapped = false
        appCoordinator?.showCurrencySelectionViewController(withBaseCurrencyCode: viewModel?.toBaseCurrency.value ?? "BDT")
    }
    
    @objc func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        currenncyInputTextField.resignFirstResponder()
    }
    
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            currencyConatinerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            currencyConatinerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            currencyConatinerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            currencyConatinerStackView.heightAnchor.constraint(equalToConstant: 135),
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

extension CurrencyRateViewController: AppCoordinatorDelegate {
    func didSelectedCurrency(info: CurrencyInfo) {
        guard let viewModel = viewModel else {
            return
        }
        if isFromButtonTapped {
            viewModel.exchangeCurrency(forAmount: Double(currenncyInputTextField.text ?? "1") ?? 1, fromBase: info.code, toBase: viewModel.toBaseCurrency.value)
        } else {
            viewModel.exchangeCurrency(forAmount: Double(currenncyInputTextField.text ?? "1") ?? 1, fromBase: viewModel.fromBaseCurrency.value, toBase: info.code)
        }
        
    }
}
