//
//  MainViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 01/03/2025.
//




import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainViewController: UIViewController {

    @IBOutlet weak var len_tak: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.hidesBackButton = true
        
        // just for testinggggg
        let db = Firestore.firestore()
        if let uid = Auth.auth().currentUser?.uid {
            db.collection("users").document(uid).getDocument { documentSnapshot, error in
                if let error = error {
                    print("Error fetching document: \(error)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists else {
                    print("User document does not exist")
                    return
                }
                
                // Extract fields from the document
                let data = document.data()
                let name = data?["name"] as? String ?? ""
                let username = data?["username"] as? String ?? ""
                let surname = data?["surname"] as? String ?? ""
                let email = data?["email"] as? String ?? ""
                
                print("Username: \(username)")
                print("Surname: \(surname)")
                print("Email: \(email)")
                self.len_tak.text = "Hello \(name) \(surname) as \(username)"
            }
        } else {
            print("Oops problem")
        }


    }
    
    
    
    // Logging out via firebase
    @IBAction func log_out_button_pressed(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
          try firebaseAuth.signOut()
            // Go to the starting screen after logging out
            navigationController?.popToRootViewController(animated: true)
        } catch let signOutError as NSError {
            showAlert(title: "Error signing out", message: NSError.description())
            print("Error signing out: %@", signOutError)
        }
    }
    
}
