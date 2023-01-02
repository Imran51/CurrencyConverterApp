//
//  CurrencySelectionTableViewCell.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import UIKit

class CurrencySelectionTableViewCell: UITableViewCell {
    private let currencyCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "USD"
        label.textAlignment = .left
        label.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        return label
    }()
    
    private let currencyCountryNameLabel: UILabel = {
        let label = UILabel()
        label.text = "0.00"
//        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .left
        label.numberOfLines = 0

        return label
    }()
    
    private var containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 5
        stack.backgroundColor = .quaternaryLabel
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 5)
        stack.layer.masksToBounds = true
        stack.layer.cornerRadius = 13
        
        return stack
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setupUI() {
        contentView.addSubview(containerStackView)
        containerStackView.addArrangedSubview(currencyCodeLabel)
        containerStackView.addArrangedSubview(currencyCountryNameLabel)
        NSLayoutConstraint.activate([
            containerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -5)
        ])
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        currencyCodeLabel.text = nil
        currencyCountryNameLabel.text = nil
    }
    
    func configure(currencyInfo: CurrencyInformation) {
        currencyCodeLabel.text = currencyInfo.code
        currencyCountryNameLabel.text = currencyInfo.name
        currencyCountryNameLabel.sizeToFit()
    }

}
