//
//  RegisterViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 01/03/2025.
//

import UIKit
import FirebaseAuth
import Firebase

class RegisterViewController: UIViewController {
    

    @IBOutlet weak var register_button_outlet: UIButton!
    @IBOutlet weak var user_name_text_field: UITextField!
    
    @IBOutlet weak var name_text_field: UITextField!
    
    @IBOutlet weak var surname_text_field: UITextField!
    

    @IBOutlet weak var password_text_field: UITextField!
    
    
    @IBOutlet weak var email_text_field: UITextField!
    
    
    override func viewDidLoad() {
        print("HELLO")
        super.viewDidLoad()
        // Initialization code
    }
    
    @IBAction func register_pressed(_ sender: UIButton) {
        // loading icon
        register_button_outlet.configuration?.showsActivityIndicator = true
        
        // MARK: - is all information provided?
        if self.name_text_field.text == nil || self.surname_text_field.text == nil || self.user_name_text_field.text == nil || self.email_text_field.text == nil {
            showAlert(title: "Provide all information", message: "Some of the information fields is empty")
            // loading icon hide
            self.register_button_outlet.configuration?.showsActivityIndicator = false
        }
        
        
        // MARK: - trying to connect to firebase database and checking the uniqness of password and email
        if let email = self.email_text_field.text, let password = self.password_text_field.text {
            // Register users - firebase database
            Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
                if let e = error {
                    // show iOS native alert
                    self.showAlert(title: "Registration Error", message:  e.localizedDescription)
                    
                    // loading icon hide
                    self.register_button_outlet.configuration?.showsActivityIndicator = false
                    return
                }
                
                // Do we have valid user created right now? If not return
                guard let user = authResult?.user else { return }
                let uid = user.uid
                
                // Additional user data preparing here
                let userData: [String: Any] = [
                    "username": self.user_name_text_field.text ?? "",
                    "name": self.name_text_field.text ?? "",
                    "surname": self.surname_text_field.text ?? "",
                    "email": email
                ]
                
                
                // Reference Firestore database - we have only 1 database divided into collection
                let db = Firestore.firestore()
                
                // Save additional data in "users" collection with document id = uid
                db.collection("users").document(uid).setData(userData) { error in
                    if let error = error {
                        self.showAlert(title: "Database Error", message: error.localizedDescription)
                    } else {
                        // Successfully stored additional user info
                        print("User data saved successfully!")
                        // navigate to the next screen
                        self.performSegue(withIdentifier: "register_to_events", sender: self)
                    }
                }
                // loading icon
                self.register_button_outlet.configuration?.showsActivityIndicator = false
            }
        } else {
            print("User did not give us email or password")
            // loading icon hide
            register_button_outlet.configuration?.showsActivityIndicator = false
        }
        
    }
    
    
}
