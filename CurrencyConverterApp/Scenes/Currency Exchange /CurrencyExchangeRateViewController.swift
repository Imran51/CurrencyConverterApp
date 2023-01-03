//
//  ViewController.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import UIKit
import Combine

class CurrencyExchangeRateViewController: UIViewController {
    weak var appCoordinator: AppCoordinator?
    var viewModel: CurrencyExchangeRateViewModel?
    
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
        textField.layer.cornerRadius = 18
        
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
    
    private var dataSource: CurrencyRateExchangeCollectionDataSource?
    private var cancellables = Set<AnyCancellable>()
    private var isFromButtonTapped = false
    let nc = NotificationCenter.default
    
    private func createCollectionViewLayout() -> UICollectionViewLayout {
        let fraction: CGFloat = 1 / 2.1
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(fraction), heightDimension: .fractionalHeight(1))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(90))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        group.interItemSpacing = .fixed(5)
        
        let section = NSCollectionLayoutSection(group: group)
        let inset: CGFloat = 2.5
        
        item.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        
        section.contentInsets = NSDirectionalEdgeInsets(top: inset, leading: inset, bottom: inset, trailing: inset)
        section.interGroupSpacing = 5
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        
        dataSource = CurrencyRateExchangeCollectionDataSource(collectionView)
        
        observeViewModelDataChanges()
        viewModel?.fetchLatestCurrencyRate()
        
        appCoordinator?.delegate = self
        
        
        nc.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .current) {[weak self] _ in
            self?.viewModel?.fetchLatestCurrencyRate()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        nc.removeObserver(self)
    }
    
    private func observeViewModelDataChanges() {
        viewModel?.exchangeRateList.sink(receiveCompletion: { _ in }, receiveValue: { [weak self] exchangeRates in
            guard let self = self else { return }
            self.dataSource?.update(exchangeRates)
        })
        .store(in: &cancellables)
        
        viewModel?.dataFetchingError.sink(receiveValue: {[weak self] error in
            guard let self = self, let error = error else { return  }
            let retryAction = UIAlertAction(title: "Retry", style: .default) {_ in
                self.viewModel?.fetchLatestCurrencyRate()
            }
            self.showErrorAlert(error, actions: [retryAction])
        })
        .store(in: &cancellables)
        
        viewModel?.baseCurrency.sink(receiveValue: { [weak self] value in
            guard let self = self else { return }
            self.currencyPickerFromButton.setTitle(value.from, for: .normal)
            self.currencyPickerToButton.setTitle(value.to, for: .normal)
        }).store(in: &cancellables)
        
        viewModel?.fromToExchangeRate.sink(receiveValue: { [weak self] value in
            guard let self = self else { return }
            self.currentCurrencyFromLabel.text = value.from
            self.currentCurrencyToLabel.text = value.to
        }).store(in: &cancellables)
        
        viewModel?.isProcessingData.sink(receiveValue: {[weak self] toggle in
            guard let self = self else {
                return
            }
            self.appCoordinator?.showLoadingIndicatorView(toggle: toggle ?? true)
        }).store(in: &cancellables)
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
        appCoordinator?.showCurrencySelectionViewController(withBaseCurrencyCode: viewModel?.baseCurrency.value.from ?? "USD")
    }
    
    @objc func toButtonTapped(_ sender: UIButton) {
        isFromButtonTapped = false
        appCoordinator?.showCurrencySelectionViewController(withBaseCurrencyCode: viewModel?.baseCurrency.value.to ?? "BDT")
    }
    
    @objc func dismissKeyboard(_ gesture: UITapGestureRecognizer) {
        currenncyInputTextField.resignFirstResponder()
    }
    
    private func setupConstraint() {
        NSLayoutConstraint.activate([
            currencyConatinerStackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            currencyConatinerStackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            currencyConatinerStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            currencyConatinerStackView.heightAnchor.constraint(equalToConstant: 140),
            collectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15),
            collectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15),
            collectionView.topAnchor.constraint(equalTo: currencyConatinerStackView.bottomAnchor, constant: 20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
}


extension CurrencyExchangeRateViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        viewModel?.calculateCurrentExchangeRate(for: textField.text ?? "1")
    }
}

extension CurrencyExchangeRateViewController: AlertDisplayable {  }


extension CurrencyExchangeRateViewController: AppCoordinatorDelegate {
    func didSelectedCurrency(info: CurrencyInformation) {
        guard let viewModel = viewModel else {
            return
        }
        if isFromButtonTapped {
            viewModel.exchangeCurrency(
                forAmount: Double(currenncyInputTextField.text ?? "1") ?? 1,
                fromBase: info.code,
                toBase: viewModel.baseCurrency.value.to
            )
        } else {
            viewModel.exchangeCurrency(
                forAmount: Double(currenncyInputTextField.text ?? "1") ?? 1,
                fromBase: viewModel.baseCurrency.value.from,
                toBase: info.code
            )
        }
    }
}
