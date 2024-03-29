//
//  LatestCurrencies.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation

struct LatestCurrencyExchangeRateInfo: Decodable {
    var timestamp: Double
    var base: String
    var rates: [String: Double]
}
