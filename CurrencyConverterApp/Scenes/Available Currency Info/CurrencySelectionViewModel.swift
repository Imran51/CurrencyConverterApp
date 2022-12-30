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
    @Published var currencyFetchingError: NetworkError? = nil
    @Published var isProcessingData: Bool = false
    
    var viewModel: CurrencySelectionViewModel?
    private let networkService: CurrencyService
    private let realmStore: RealmStore
    private let localUserDefaults: CurrencyLocalStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    var baseCurrency: String
    
    init(networkService: CurrencyService, realmStore: RealmStore, locaStore: CurrencyLocalStoreProtocol, baseCurrencyCode: String) {
        self.networkService = networkService
        self.realmStore = realmStore
        self.localUserDefaults = locaStore
        baseCurrency = baseCurrencyCode
    }
    
    func fetchAvailableCurrencies() {
        isProcessingData = true
        if let date: Date = localUserDefaults.get(for: .fetchedTimestamp), Date() < date + 30 * 60 {
            isProcessingData = false
            guard let currencyInfo = realmStore.currencyInfo(), !currencyInfo.isEmpty else {
                currencyFetchingError = .unknown("Couldn't fetch data from local relam store")
                return
            }
            availableCurrencies = currencyInfo
        } else {
            networkService.getCurrencies()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    guard let self = self else { return }
                    self.isProcessingData = false
                    switch result {
                    case .failure(let error):
                        self.currencyFetchingError = error
                    case .finished:
                        print("Success")
                    }
                } receiveValue: { [weak self] availableCurrencyList in
                    guard let self = self else { return }
                    self.availableCurrencies = availableCurrencyList.compactMap { CurrencyInfo(code: $0.key, name: $0.value) }.sorted(by: { $0.code < $1.code })
                    var currencyList = [Currency]()
                    availableCurrencyList.forEach {
                        let currency = Currency()
                        currency.code = $0.key
                        currency.name = $0.value
                        currencyList.append(currency)
                    }
                    self.localUserDefaults.set(value: Date(), for: .fetchedTimestamp)
                    self.realmStore.addorUpdate(currencyList)
                }
                .store(in: &cancellables)
        }
    }
}
