//
//  AppCoordinator.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/28/22.
//

import Foundation
import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    
    var navigationController: UINavigationController { get set }
    
    func start()
    
    func showLoadingIndicatorView(toggle: Bool)
}

extension Coordinator {
    func showLoadingIndicatorView(toggle: Bool) {
        toggle ? LoadingIndicatorView.sharedInstance.show(withTitle: "Please wait..") : LoadingIndicatorView.sharedInstance.hide()
    }
}

protocol AppCoordinatorDelegate: AnyObject {
    func didSelectedCurrency(info: CurrencyInfo)
}



class AppCoordinator: NSObject, Coordinator, UINavigationControllerDelegate {
    var childCoordinators: [Coordinator] = []
    
    var navigationController: UINavigationController
    weak var delegate: AppCoordinatorDelegate?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        navigationController.delegate = self
        let vc = CurrencyRateViewController()
        vc.appCoordinator = self
        
        vc.viewModel = CurrencyRateViewModel(networkService: APIServiceImpl(), realmStore: RealmManager.shared, locaStore: CurrencyLocalStore.shared)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func showCurrencySelectionViewController(withBaseCurrencyCode currencyCode: String) {
        let child = SupportedCurrencyCoordinator(navigationController: navigationController, baseCurrency: currencyCode)
        child.parentCoordinator = self
        child.delegate = self
        childCoordinators.append(child)
        child.start()
    }
    
    
    func childDidFinish(_ child: Coordinator?) {
        for (idx, coordinator) in childCoordinators.enumerated() {
            if coordinator === child {
                childCoordinators.remove(at: idx)
                break
            }
        }
    }
    
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        guard let fromViewController = navigationController.transitionCoordinator?.viewController(forKey: .from) else { return }
        if navigationController.viewControllers.contains(fromViewController) {
            return
        }
        if let selectionnViewConroller = fromViewController as? CurrencySelectionViewController {
            childDidFinish(selectionnViewConroller.appCoordinator)
        }
    }
}

extension AppCoordinator: SupportedCurrencyCoordinatorDelegate {
    func didSelectCurrency(info: CurrencyInfo) {
        delegate?.didSelectedCurrency(info: info)
    }
}

protocol SupportedCurrencyCoordinatorDelegate: AnyObject {
    func didSelectCurrency(info: CurrencyInfo)
}

class SupportedCurrencyCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: AppCoordinator?
    weak var delegate: SupportedCurrencyCoordinatorDelegate?
    var navigationController: UINavigationController
    var baseCurrencyCode: String
    
    init(navigationController: UINavigationController, baseCurrency: String) {
        self.navigationController = navigationController
        baseCurrencyCode = baseCurrency
    }
    
    func start() {
        let vc = CurrencySelectionViewController()
        vc.appCoordinator = self
        vc.viewModel = CurrencySelectionViewModel(networkService: APIServiceImpl(), realmStore: RealmManager.shared, locaStore: CurrencyLocalStore.shared, baseCurrencyCode: baseCurrencyCode)
        navigationController.pushViewController(vc, animated: true)
    }
    
    func didFinishSelection() {
        parentCoordinator?.childDidFinish(self)
    }
    
    func didFinishSelection(_ currencyInfo: CurrencyInfo) {
        navigationController.popViewController(animated: true)
        delegate?.didSelectCurrency(info: currencyInfo)
    }
}
