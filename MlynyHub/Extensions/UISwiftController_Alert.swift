//
//  UISwiftController_Alert.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 01/03/2025.
//

import UIKit


// Added alert extension for whole project
extension UIViewController {
    
    // Function to present an alert with a given title and message
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
}
