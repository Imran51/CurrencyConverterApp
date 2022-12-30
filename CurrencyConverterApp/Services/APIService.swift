//
//  APIService.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine

class APIServiceImpl: CurrencyService {
    func fetchLatestCurrencies(base: String?) -> AnyPublisher<LatestCurrencyExchangeRateInfo, NetworkError> {
        request(urlRequest: CurrencyRequestLayer.latestCurrencies(base: base))
    }
    
    func getCurrencies() -> AnyPublisher<[String:String], NetworkError> {
        request(urlRequest: CurrencyRequestLayer.currencies)
    }
    
    private func request<T: Decodable>(urlRequest: DataRequest) -> AnyPublisher<T, NetworkError> {
        guard let urlRequest = try? urlRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        print(urlRequest)
        return URLSession.shared
            .dataTaskPublisher(for: urlRequest)
            .tryMap { response in
                guard let httpResponse = response.response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    throw NetworkError.invalidResponse(response.response.debugDescription)
                }
                return response.data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error in
                switch error {
                case is DecodingError:
                    return NetworkError.decodingError
                default:
                    return NetworkError.invalidResponse(error.localizedDescription)
                }
            }
            .eraseToAnyPublisher()
    }
}
