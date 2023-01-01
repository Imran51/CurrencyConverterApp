//
//  APIService.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import Combine


protocol Requestable {
    func make<T: Decodable>(request: URLRequest) -> AnyPublisher<T, NetworkError>
}

struct ApiClient: Requestable {
    func make<T: Decodable>(request: URLRequest) -> AnyPublisher<T, NetworkError> {
        return URLSession.shared
            .dataTaskPublisher(for: request)
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

struct CurrencyServiceImpl: CurrencyService {
    let apiClient: Requestable = ApiClient()
    
    func fetchLatestCurrencies(currencyRequest: CurrencyRequestLayer) -> AnyPublisher<LatestCurrencyExchangeRateInfo, NetworkError> {
        guard let urlRequest = try? currencyRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return apiClient.make(request: urlRequest)
    }
    
    func getCurrencies(currencyRequest: CurrencyRequestLayer) -> AnyPublisher<[String : String], NetworkError> {
        guard let urlRequest = try? currencyRequest.asURLRequest() else {
            return Fail(error: NetworkError.invalidURL).eraseToAnyPublisher()
        }
        return apiClient.make(request: urlRequest)
    }
}

