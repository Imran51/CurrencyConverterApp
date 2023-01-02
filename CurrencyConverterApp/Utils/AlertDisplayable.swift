//
//  AlertDisplayable.swift
//  CurrencyConverterApp
//
//  Created by Imran Sayeed on 12/30/22.
//

import UIKit

import UIKit

protocol AlertDisplayable {
    func showAlert(title: String?, message: String?, actions: [UIAlertAction])
}

extension AlertDisplayable where Self: UIViewController {

    func showErrorAlert(_ error: NetworkError, actions: [UIAlertAction] = []) {
        self.showAlert(
            title: "Error",
            message: error.message,
            actions: [UIAlertAction(title: "OK", style: .default)] + actions
        )
    }

    func showAlert(
        title: String?,
        message: String?,
        actions: [UIAlertAction]
    ) {
        dismiss(animated: true) {[weak self] in
            guard let self = self else { return }
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            actions.forEach {
                alert.addAction($0)
            }
            self.present(alert, animated: true, completion: nil)
        }
    }

}

