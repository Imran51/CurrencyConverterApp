//
//  CurrencyRateViewModel.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

final class CurrencyRateViewModel {
    @Published var exchangeRate: [ExchangeRate] = []
    private let networkService: CurrencyService
    private var cancellables = Set<AnyCancellable>()
    
    init(networkService: CurrencyService) {
        self.networkService = networkService
    }
    
    func fetchLatestCurrencies() {
        networkService.fetchLatestCurrencies()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                case .finished:
                    print("Success")
                }
                
            }) { [weak self] latestCurrencies in
                var exchangeList = latestCurrencies.rates.compactMap({ ExchangeRate(targetCurrencyCode: $0.key, value: $0.value) })
                exchangeList = exchangeList.sorted(by: { $0.targetCurrencyCode < $1.targetCurrencyCode })
                self?.exchangeRate = exchangeList
            }
            .store(in: &cancellables)
    }
}
