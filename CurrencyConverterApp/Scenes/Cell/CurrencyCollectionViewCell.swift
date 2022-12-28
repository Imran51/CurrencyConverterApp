//
//  CurrencyCollectionViewCell.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import UIKit

class CurrencyCollectionViewCell: UICollectionViewCell {
    static let identifier = "CurrencyCollectionViewCell"
    
    private let currencyCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "USD"
//        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left

        return label
    }()
    
    private let currencyValueLabel: UILabel = {
        let label = UILabel()
        label.text = "0.00"
//        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .right

        return label
    }()
    
    private var containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        stack.spacing = 10
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
    }
    
    func setupUI() {
        contentView.addSubview(containerStackView)
        containerStackView.addArrangedSubview(currencyCodeLabel)
        containerStackView.addArrangedSubview(currencyValueLabel)
        
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        currencyCodeLabel.text = nil
        currencyValueLabel.text = nil
    }
    
    func configure(_ viewData: ExchangeRate) {
        currencyCodeLabel.text = viewData.targetCurrencyCode
        currencyValueLabel.text = viewData.displayedValue
    }
}
