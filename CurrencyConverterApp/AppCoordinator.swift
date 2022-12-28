//
//  AppCoordinator.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import UIKit

protocol Coordinator {
    var childCoordinator: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }
    
    func start()
}

class AppCoordinator: Coordinator {
    var childCoordinator: [Coordinator] = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let vc = CurrencyRateViewController()
        vc.appCoordinator = self
        vc.viewModel = CurrencyRateViewModel(networkService: APIServiceImpl())
        navigationController.pushViewController(vc, animated: true)
    }
}
