//
//  CurrencySelectionViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/29/22.
//

import Foundation
import Combine

final class CurrencySelectionViewModel {
    var supportedCountryCurrencies = CurrentValueSubject<[CurrencyInformation], Never>([])
    var fetchingError = CurrentValueSubject<NetworkError?, Never>(nil)
    var isDataProcessing = CurrentValueSubject<Bool?, Never>(nil)
    
    var viewModel: CurrencySelectionViewModel?
    private let networkService: CurrencyService
    private let realmStore: RealmStore
    private let currencyLocalPreference: CurrencyLocalStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    var baseCurrency: String
    
    init(networkService: CurrencyService, realmStore: RealmStore, localStore: CurrencyLocalStoreProtocol, baseCurrencyCode: String) {
        self.networkService = networkService
        self.realmStore = realmStore
        self.currencyLocalPreference = localStore
        baseCurrency = baseCurrencyCode
    }
    
    func fetchSupportedCurrencies() {
        isDataProcessing.send(true)
        if let date: Date = currencyLocalPreference.get(for: .supportedCurrencyFetched), Date() < date + 30 * 60 {
            isDataProcessing.send(false)
            guard let currencyInfo = realmStore.currencyInfo(), !currencyInfo.isEmpty else {
                fetchingError.send(.unknown("Couldn't fetch data from local relam store"))
                return
            }
            supportedCountryCurrencies.send(currencyInfo)
        } else {
            networkService.getSupportedCurrencies(currencyRequest: .currencies)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] result in
                    guard let self = self else { return }
                    self.isDataProcessing.send(false)
                    switch result {
                    case .failure(let error):
                        self.fetchingError.send(error)
                    case .finished:
                        print("Success")
                    }
                } receiveValue: { [weak self] availableCurrencyList in
                    guard let self = self else { return }
                    self.supportedCountryCurrencies.send(
                        availableCurrencyList
                            .compactMap { CurrencyInformation(code: $0.key, name: $0.value) }
                            .sorted(by: { $0.code < $1.code })
                    )
                    var currencyList = [Currency]()
                    availableCurrencyList.forEach {
                        let currency = Currency()
                        currency.code = $0.key
                        currency.name = $0.value
                        currencyList.append(currency)
                    }
                    self.currencyLocalPreference.set(value: Date(), for: .supportedCurrencyFetched)
                    self.realmStore.addorUpdate(currencyList)
                }
                .store(in: &cancellables)
        }
    }
}
