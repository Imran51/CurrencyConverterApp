//
//  LocalCurrencies.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import Foundation
import RealmSwift

class LocalCurrencyExchangeRate: Object {
    @objc dynamic var timestamp: Double = 0.0
    @objc dynamic var base: String = ""
    let rates = List<RatesDictionary>()
    
    override class func primaryKey() -> String? {
        return "base"
    }
    
    func appendToList(rateDictionary: [ExchangeRate]){
        rateDictionary.forEach{
            let entry = RatesDictionary()
            entry.key = $0.targetCurrencyCode
            entry.val = $0.value
            rates.append(entry)
        }
    }
}

class RatesDictionary: Object {
    @objc dynamic var key = ""
    @objc dynamic var val: Double = 0.0
}
