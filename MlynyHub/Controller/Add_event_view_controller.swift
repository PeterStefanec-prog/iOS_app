//
//  Add_event_view_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 19/03/2025.
//

import UIKit
import FirebaseFirestore

class Add_event_view_controller: UIViewController {

    @IBOutlet weak var Participant_slots_input: UILabel!
    @IBOutlet weak var Event_title_input: UITextField!
    @IBOutlet weak var Description_title_input: UITextField!
    @IBOutlet weak var Event_participants_stepper: UIStepper!
    @IBOutlet weak var Event_date_input: UIDatePicker!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Event_participants_stepper.minimumValue = 1
        Event_participants_stepper.maximumValue = 100
        Event_participants_stepper.stepValue = 1
        Event_participants_stepper.value = 5
        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func Steppet_value_changed(_ sender: UIStepper) {
        Participant_slots_input.text = "\(Int(sender.value))"
    }
    
    @IBAction func Create_event_button(_ sender: UIButton) {
        // 1️⃣ Skontroluj, či vstupy nie sú prázdne
        guard let title = Event_title_input.text, !title.isEmpty,
              let description = Description_title_input.text, !description.isEmpty,
              let participantSlotsText = Participant_slots_input.text, !participantSlotsText.isEmpty,
              let participantSlots = Int(participantSlotsText) else {
            showAlert(title: "Invalid input", message: "Error: Missing required fields")
            return
        }
        
        // 2️⃣ Získanie dátumu z UIDatePicker
        let eventDate = Event_date_input.date
        
        // Debug printy pre kontrolu
        print("Title: \(title)")
        print("Description: \(description)")
        print("Participants: \(participantSlots)")
        print("Date: \(eventDate)")
        
        // 3️⃣ Uloženie do Firestore
        let db = Firestore.firestore()
        db.collection("Events").addDocument(data: [
            "Title": title,
            "Description": description,
            "Participant slots": participantSlots,
            "Filled slots": 0,  // Predvolene 0 účastníkov
            "Date": Timestamp(date: eventDate),
            "Location": [0, 0]  // Predvolené súradnice, môžeš ich neskôr aktualizovať
        ]) { error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
            } else {
                print("Event successfully added!")
            }
        }
    }
}
