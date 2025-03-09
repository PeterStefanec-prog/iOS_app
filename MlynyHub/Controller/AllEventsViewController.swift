//
//  MainViewController.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 01/03/2025.
//




import UIKit
import FirebaseAuth
import FirebaseFirestore

class AllEventsViewController: UIViewController {

    @IBOutlet weak var len_tak: UILabel!
    @IBOutlet weak var bottom_panel: UIView!
    @IBOutlet weak var Event_table_view: UITableView!
    
    
    //pole eventov na testovanie
    var events = [
        Event(Title: "Friday Football", max_slots: 15, filled_slots: 12, Date: "10.3.2025 10:00")
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //dolna lista setup - nesiel cez storyboard :(
        bottom_panel.layer.borderWidth = 2.0 // Hrúbka borderu
        bottom_panel.layer.borderColor = UIColor(hex: "#6C76EF")?.cgColor //specialny prikaz cez hex_to_code
        bottom_panel.layer.cornerRadius = 25.0
        bottom_panel.clipsToBounds = true
        
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
//            navigationController?.popToRootViewController(animated: true)
            self.performSegue(withIdentifier: "log_out_segue", sender: self)

        } catch let signOutError as NSError {
            showAlert(title: "Error signing out", message: NSError.description())
            print("Error signing out: %@", signOutError)
        }
    }
    
}
extension AllEventsViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Reusable_cell", for: indexPath)
        cell.textLabel?.text = "lessgo"
        return cell
    }
    
    
}
