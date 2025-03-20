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

    @IBOutlet weak var Event_table_view: UITableView!
    
    
    //pole eventov na testovanie
    var events = [
        Event_entry(Title: "Lobogo",Description: "", max_slots: 0, filled_slots: 0, Date: ""),
        Event_entry(Title: "Friday Football",Description: "", max_slots: 15, filled_slots: 12, Date: "10.3.2025 10:00"),
        Event_entry(Title: "Friday Football",Description: "", max_slots: 15, filled_slots: 12, Date: "10.3.2025 10:00"),
        Event_entry(Title: "Friday Football",Description: "", max_slots: 15, filled_slots: 12, Date: "10.3.2025 10:00"),
        Event_entry(Title: "Friday Football",Description: "", max_slots: 15, filled_slots: 12, Date: "10.3.2025 10:00")
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Event_table_view.dataSource = self
        Event_table_view.delegate = self
        //dolna lista setup - nesiel cez storyboard :(
        
        navigationItem.hidesBackButton = true
        
        Event_table_view.register(UINib(nibName: "Event_cell", bundle: nil), forCellReuseIdentifier: "Reusable_cell")

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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Reusable_cell", for: indexPath) as! Event_cell
        if indexPath.row == 0 {
            cell.Logo_image.image = UIImage(named: "top_logo")
            cell.Background_frame.layer.opacity = 0
        }
        else {
            cell.Event_name.text = events [indexPath.row].Title
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 250 // Výška prvej bunky
        } else {
            return 310// Výška ostatných buniek
        }
    }

    
}
extension AllEventsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print (indexPath.row)
    }
}
