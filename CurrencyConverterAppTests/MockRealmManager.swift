//
//  MockRealmService.swift
//  CurrencyConverterAppTests
//
//  Created by Imran Sayeed on 1/2/23.
//

import Foundation

@testable import CurrencyConverterApp
import RealmSwift

class MockRealmManager: RealmStore {
    var relamObject = [Object]()
    init() {
        
    }
    
    func addOrUpdate(_ object: Object) -> Bool {
        relamObject.append(object)
        return true
    }
    
    func addorUpdate(_ objects: [Object]) -> Bool {
        relamObject.append(contentsOf: objects)
        return true
    }
    
    func currencyInfo() -> [CurrencyInformation]? {
        let c = relamObject.compactMap{ $0 as? Currency }.sorted(by: { $0.code < $1.code })
        return c.map({CurrencyInformation(code: $0.code, name: $0.name)})
    }
    
    func getLatestCurrencyExchangeRate() -> LocalCurrencyExchangeRate? {
        relamObject.compactMap({ $0 as? LocalCurrencyExchangeRate }).sorted(by: { $0.timestamp > $1.timestamp }).first
    }
    
    func getLatestCurrencyExchangeRate(by base: String) -> LocalCurrencyExchangeRate? {
        relamObject.compactMap({ $0 as? LocalCurrencyExchangeRate }).first(where: { $0.base == base })
    }
}
