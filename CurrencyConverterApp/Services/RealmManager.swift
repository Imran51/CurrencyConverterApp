//
//  RealmManager.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import Foundation
import RealmSwift

protocol RealmStore: AnyObject {
   func addOrUpdate(_ object: Object)
   
   func addorUpdate(_ objects: [Object])
   
   func getLatestCurrencyExchangeRate() -> LocalCurrencyExchangeRate?
   
   func currencyInfo() -> [CurrencyInfo]?
   
   func getLatestCurrencyExchangeRate(by base: String) -> LocalCurrencyExchangeRate?
}

class RealmManager: RealmStore {
   func getLatestCurrencyExchangeRate(by base: String) -> LocalCurrencyExchangeRate? {
      guard let realm = realm else { return nil }
      let localCurrency = realm.object(ofType: LocalCurrencyExchangeRate.self, forPrimaryKey: base)
      return localCurrency
   }
   
   func currencyInfo() -> [CurrencyInfo]? {
      guard let realm = realm else { return nil }
      let currencies = realm.objects(Currency.self).sorted(byKeyPath: "code", ascending: true)
      
      return currencies.compactMap({ CurrencyInfo(code: $0.code, name: $0.name) })
   }
   
   func addOrUpdate(_ object: Object) {
      let saved = save(objects: [object])
      print("saved success-> \(saved)")
   }
   
   func addorUpdate(_ objects: [Object]) {
      let saved = save(objects: objects)
      print("saved success-> \(saved)")
   }
   
   func getLatestCurrencyExchangeRate() -> LocalCurrencyExchangeRate? {
      guard let realm = realm else { return nil }
      let currencies = realm.objects(LocalCurrencyExchangeRate.self).sorted(byKeyPath: "timestamp", ascending: true)
      return currencies.compactMap({ LocalCurrencyExchangeRate(value: $0) }).first
   }
   
   
   static let shared = RealmManager()
   private let realm: Realm?
   
   private init() {
      let defaultConfig = Realm.Configuration()
      do {
         realm = try Realm(configuration: defaultConfig)
      } catch let error {
         print("coldn't initialize relam with \(error)")
         realm = nil
      }
      print("default realm path: \(String(describing: defaultConfig.fileURL))")
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
