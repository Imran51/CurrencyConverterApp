//
//  RealmManager.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import Foundation
import RealmSwift

protocol RealmStore: AnyObject {
    @discardableResult
    func addOrUpdate(_ object: Object) -> Bool
    
    @discardableResult
    func addorUpdate(_ objects: [Object]) -> Bool
    
    func getLatestCurrencyExchangeRate() -> LocalCurrencyExchangeRate?
    
    func currencyInfo() -> [CurrencyInformation]?
    
    func getLatestCurrencyExchangeRate(by base: String) -> LocalCurrencyExchangeRate?
}

class RealmManager: RealmStore {
    private let realm: Realm?
    
    init(defaultConfig: Realm.Configuration = Realm.Configuration() ) {
        do {
            realm = try Realm(configuration: defaultConfig)
        } catch let error {
            print("coldn't initialize relam with \(error)")
            realm = nil
        }
        print("default realm path: \(String(describing: defaultConfig.fileURL))")
    }
    
    func getLatestCurrencyExchangeRate(by base: String) -> LocalCurrencyExchangeRate? {
        guard let realm = realm else { return nil }
        let localCurrency = realm.object(ofType: LocalCurrencyExchangeRate.self, forPrimaryKey: base)
        return localCurrency
    }
    
    func currencyInfo() -> [CurrencyInformation]? {
        guard let realm = realm else { return nil }
        let currencies = realm.objects(Currency.self).sorted(byKeyPath: "code", ascending: true)
        
        return currencies.compactMap({ CurrencyInformation(code: $0.code, name: $0.name) })
    }
    
    func addOrUpdate(_ object: Object) -> Bool {
        let saved = save(objects: [object])
        print("saved success-> \(saved) with object:\(object.debugDescription)")
        return saved
    }
    
    func addorUpdate(_ objects: [Object]) -> Bool {
        let saved = save(objects: objects)
        print("saved success-> \(saved)")
        return saved
    }
    
    func getLatestCurrencyExchangeRate() -> LocalCurrencyExchangeRate? {
        guard let realm = realm else { return nil }
        let currencies = realm.objects(LocalCurrencyExchangeRate.self).sorted(byKeyPath: "timestamp", ascending: true)
        return currencies.compactMap({ LocalCurrencyExchangeRate(value: $0) }).first
    }
    
    func save(objects: [Object]) -> Bool {
        guard let realm = realm else { return false }
        do {
            try realm.write {
                realm.add(objects, update: .all)
            }
        } catch let error {
            print(error)
        }
        return true
    }
    
    func update(object: Object, with dictionary: [String: Any]) -> Bool {
        guard let realm = realm else { return false }
        do {
            try realm.write {
                for (key, value) in dictionary {
                    object[key] = value
                }
            }
        } catch let error {
            print(error)
            return false
        }
        return true
    }
    
    func delete(object: Object) -> Bool {
        guard let realm = realm else { return false }
        do {
            try realm.write {
                realm.delete(object)
            }
        } catch let error {
            print(error)
            return false
        }
        return true
    }
    
    func fetchAll() -> Results<Object>? {
        guard let realm = realm else { return nil }
        return realm.objects(Object.self)
    }
}
