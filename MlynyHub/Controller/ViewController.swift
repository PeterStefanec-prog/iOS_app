//
//  ViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 28/02/2025.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var login_button_outlet: UIButton!
    @IBOutlet weak var password_text_field: UITextField!
    @IBOutlet weak var email_text_field: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func login_pressed(_ sender: UIButton) {
        if let email = email_text_field.text, let password =
            password_text_field.text {
            // loading icon
            login_button_outlet.configuration?.showsActivityIndicator = true
            // Logging in using firebase
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
              guard let self = self else { return }
                if let e = error {
                    showAlert(title: "Login error", message: e.localizedDescription)
                    // loading icon
                    login_button_outlet.configuration?.showsActivityIndicator = false
                } else {
                    self.performSegue(withIdentifier: "log_in_to_events", sender: self)
                    // loading icon
                    login_button_outlet.configuration?.showsActivityIndicator = false
                }
            }
        } else {
            print("User did not provide email or password")
        }
        

    }
    
}

