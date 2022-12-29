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
   
   func getLatestCurrencies() -> LocalCurrencies?
   
   func currencyInfo() -> [CurrencyInfo]?
}

class RealmManager: RealmStore {
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
   
   func getLatestCurrencies() -> LocalCurrencies? {
      guard let realm = realm else { return nil }
      let currencies = realm.objects(LocalCurrencies.self).sorted(byKeyPath: "timestamp", ascending: false)
      return currencies.compactMap({ LocalCurrencies(value: $0) }).first
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
