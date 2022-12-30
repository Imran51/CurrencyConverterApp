//
//  CurrencySelectionViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import Foundation
import Combine

final class CurrencySelectionViewModel {
    @Published var availableCurrencies = [CurrencyInfo]()
    
    var viewModel: CurrencySelectionViewModel?
    private let networkService: CurrencyService
    private let realmStore: RealmStore
    private let localUserDefaults: CurrencyLocalStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: CurrencyService, realmStore: RealmStore, locaStore: CurrencyLocalStoreProtocol) {
        self.networkService = networkService
        self.realmStore = realmStore
        self.localUserDefaults = locaStore
    }
    
    func fetchAvailableCurrencies() {
        if let date: Date = localUserDefaults.get(for: .fetchedTimestamp), Date() < date + 30 * 60 {
            guard let currencyInfo = realmStore.currencyInfo(), !currencyInfo.isEmpty else {
                return
            }
            availableCurrencies = currencyInfo
        } else {
            networkService.getCurrencies()
                .receive(on: DispatchQueue.main)
                .sink { result in
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                    case .finished:
                        print("Success")
                    }
                } receiveValue: { [weak self] availableCurrencyList in
                    self?.availableCurrencies = availableCurrencyList.compactMap { CurrencyInfo(code: $0.key, name: $0.value) }.sorted(by: { $0.code < $1.code })
                    var currencyList = [Currency]()
                    availableCurrencyList.forEach {
                        let currency = Currency()
                        currency.code = $0.key
                        currency.name = $0.value
                        currencyList.append(currency)
                    }
                    self?.localUserDefaults.set(value: Date(), for: .fetchedTimestamp)
                    self?.realmStore.addorUpdate(currencyList)
                }
                .store(in: &cancellables)
        }
    }
}
