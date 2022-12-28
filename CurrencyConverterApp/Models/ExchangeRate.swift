//
//  ExchangeRate.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation

import Foundation

struct ExchangeRate: Hashable {
    let targetCurrencyCode: String
    let value: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(targetCurrencyCode)
        hasher.combine(value)
    }
}

extension ExchangeRate {
    var displayedValue: String {
        return String(format: "%.3f", self.value)
    }
}

extension ExchangeRate: Equatable {
    static func == (lhs: ExchangeRate, rhs: ExchangeRate) -> Bool {
        lhs.targetCurrencyCode == rhs.targetCurrencyCode && lhs.value == rhs.value
    }
}
