//
//  ExchangeRate.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation

import Foundation

struct ExchangeRate {
    let targetCurrencyCode: String
    let value: Double
}

extension ExchangeRate {
    var displayedValue: String {
        return String(format: "%.3f", self.value)
    }
}

extension ExchangeRate: Equatable {}
