//
//  Add_event_view_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 19/03/2025.
//

import UIKit
import FirebaseFirestore
import MapKit

class Add_event_view_controller: UIViewController {

    @IBOutlet weak var Participant_slots_input: UILabel!
    @IBOutlet weak var Event_title_input: UITextField!
    @IBOutlet weak var Description_title_input: UITextField!
    @IBOutlet weak var Event_participants_stepper: UIStepper!
    @IBOutlet weak var Event_date_input: UIDatePicker!
    
    var selectedLatitude: Double?
    var selectedLongitude: Double?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //restrikcie pre pocet ucastnikov
        Event_participants_stepper.minimumValue = 3
        Event_participants_stepper.maximumValue = 100
        Event_participants_stepper.stepValue = 1
        Event_participants_stepper.value = 5
    }
    
    //pocet sa meni
    @IBAction func Stepper_value_changed(_ sender: UIStepper) {
        Participant_slots_input.text = "\(Int(sender.value))"
    }
    
    @IBAction func Create_event_button(_ sender: UIButton) {
        // kontrola ci su vsetky atributy eventu zadane
        guard let title = Event_title_input.text, !title.isEmpty,
              let description = Description_title_input.text, !description.isEmpty,
              let participantSlotsText = Participant_slots_input.text, !participantSlotsText.isEmpty,
              let participantSlots = Int(participantSlotsText),
              let longitude = selectedLongitude,
              let latitude = selectedLatitude
        else {
            showAlert(title: "Chýbajúce vlastnosti eventu",
                      message: "Doplň vlastnosti eventu. Musí obsahovať názov, popis, počet účastníkov, dátum a miesto!")
            return
        }
        
        // datum
        let eventDate = Event_date_input.date
        
        // Debug printy pre kontrolu
        print("Title: \(title)")
        print("Description: \(description)")
        print("Participants: \(participantSlots)")
        print("Date: \(eventDate)")
        
        // upload event do firestore
        let db = Firestore.firestore()
        db.collection("Events").addDocument(data: [
            "Title": title,
            "Description": description,
            "Participant slots": participantSlots,
            "Filled slots": 0,  // Predvolene 0 účastníkov
            "Date": Timestamp(date: eventDate),
            "Location": [latitude,longitude]
        ]) { error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
            } else {
                print("Event successfully added!")
            }
        }
    }
    
    @IBAction func Open_map(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //segue
        if let locationVC = storyboard.instantiateViewController(withIdentifier: "Choose_map_location") as? Pick_location_controller {
                locationVC.delegate = self //delegat
                present(locationVC, animated: true)
        }
    }
    
}

extension Add_event_view_controller: LocationPickerDelegate {
    func didSelectLocation(latitude: Double, longitude: Double, address: String) {
        self.selectedLatitude = latitude
        self.selectedLongitude = longitude
        print("Vybraná lokácia: \(latitude), \(longitude) - Adresa: \(address)")
    }
}

