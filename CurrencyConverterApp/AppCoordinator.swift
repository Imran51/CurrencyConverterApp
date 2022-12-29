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
    
    func showCurrencySelectionViewController()
    
    func dismissCurrencySelectionView()
}

protocol Coordinating {
    var coordinator: Coordinator? { get set }
}

class AppCoordinator: Coordinator {
    var childCoordinator: [Coordinator] = [Coordinator]()
    
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        var vc = CurrencyRateViewController()
        vc.appCoordinator = self
        
        vc.viewModel = CurrencyRateViewModel(networkService: APIServiceImpl(), realmStore: RealmManager.shared, locaStore: CurrencyLocalStore.shared)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showCurrencySelectionViewController() {
        let vc = CurrencySelectionViewController()
        vc.appCoordinator = self
        vc.viewModel = CurrencySelectionViewModel(networkService: APIServiceImpl(), realmStore: RealmManager.shared, locaStore: CurrencyLocalStore.shared)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func dismissCurrencySelectionView() {
        
    }
}
