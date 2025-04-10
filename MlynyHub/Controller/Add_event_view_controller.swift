//
//  Add_event_view_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 19/03/2025.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import MapKit

class Add_event_view_controller: UIViewController {

    @IBOutlet weak var Participant_slots_input: UILabel!
    @IBOutlet weak var Event_title_input: UITextField!
    @IBOutlet weak var Description_title_input: UITextField!
    @IBOutlet weak var Event_participants_stepper: UIStepper!
    @IBOutlet weak var Event_date_input: UIDatePicker!
    
    // outlet pre image pri vytvarani eventu
    @IBOutlet weak var eventImageView: UIImageView!
    
    
    var selectedLatitude: Double?
    var selectedLongitude: Double?
    
    // Keep the selected image in a variable
    var selectedImage: UIImage?
    
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
    
    // MARK: - User clicked on select image
    @IBAction func select_image(_ sender: UIButton) {
        // Create and present the image picker object
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary  // or camera maybe ?
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    // MARK: - Create Event Action - ending this screen - event created - maybe / maybe not succesfully
    @IBAction func Create_event_button(_ sender: UIButton) {
        // Validate required fields
        guard let title = Event_title_input.text, !title.isEmpty,
              let description = Description_title_input.text, !description.isEmpty,
              let participantSlotsText = Participant_slots_input.text, !participantSlotsText.isEmpty,
              let participantSlots = Int(participantSlotsText),
              let longitude = selectedLongitude,
              let latitude = selectedLatitude,
              let image = selectedImage
        else {
            showAlert(title: "Chýbajúce vlastnosti eventu",
                      message: "Doplň vlastnosti eventu. Musí obsahovať názov, popis, počet účastníkov, dátum, miesto a fotografiu!")
            return
        }
        
        let eventDate = Event_date_input.date
        
        // Debug prints
        print("Title: \(title)")
        print("Description: \(description)")
        print("Participants: \(participantSlots)")
        print("Date: \(eventDate)")
        
        // Upload image if selected, then create event in Firestore
        if let image = selectedImage {
            uploadImage(image) { [weak self] imageUrl in    // closure ktory sa zavola po uspesnom nahrati
                self?.uploadEvent(title: title,
                                  description: description,
                                  participantSlots: participantSlots,
                                  eventDate: eventDate,
                                  latitude: latitude,
                                  longitude: longitude,
                                  imageUrl: imageUrl)
            }
        }
    }
    
    // Function to upload event data to Firestore
    private func uploadEvent(title: String,
                             description: String,
                             participantSlots: Int,
                             eventDate: Date,
                             latitude: Double,
                             longitude: Double,
                             imageUrl: String?) {
        let db = Firestore.firestore()
        
        var eventData: [String: Any] = [
            "Title": title,
            "Description": description,
            "Participant slots": participantSlots,
            "Filled slots": 0,
            "Date": Timestamp(date: eventDate),
            "Location": [latitude, longitude]
        ]
        
        // Add the image URL if available
        if let imageUrl = imageUrl {
            eventData["ImageURL"] = imageUrl
        }
        
        db.collection("Events").addDocument(data: eventData) { error in
            if let error = error {
                print("Error adding document: \(error.localizedDescription)")
            } else {
                print("Event successfully added!")
            }
        }
    }
    
    // Function to upload an image to Firebase Storage
    private func uploadImage(_ image: UIImage, completion: @escaping (_ imageUrl: String?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.6) else {    // prevedenie obrazku na jpeg
            print("Error compressing image.")
            completion(nil)
            return
        }
        
        // Create a unique image name using a UUID
        let imageName = UUID().uuidString
        let storageRef = Storage.storage().reference().child("event_images/\(imageName).jpg")   // referencia na obrazok ktory sa prida
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { (_, error) in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                completion(nil)
                return
            }
            // Retrieve the download URL for the uploaded image
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                guard let downloadURL = url else {
                    completion(nil)
                    return
                }
                completion(downloadURL.absoluteString)
            }
        }
    }
    
    // MARK: - Opens map to choose location
    @IBAction func Open_map(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //segue
        if let locationVC = storyboard.instantiateViewController(withIdentifier: "Choose_map_location") as? Pick_location_controller {
                locationVC.delegate = self //delegat
                present(locationVC, animated: true)
        }
    }
    
}



// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
// I tell system that i can react to UIIMagePickerController when it does something - it calls these functions
extension Add_event_view_controller: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Called when an image is selected
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.originalImage] as? UIImage {   // info[.originImage] - gets image from gallery
            selectedImage = image   // just setting variable in my class
            eventImageView.image = image  // updatne image view
            print("Image selected")
        }
    }
    
    // Handle cancellation - instancia UIImageController ktory bol zobrazeny
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - LocationPickerDelegate
extension Add_event_view_controller: LocationPickerDelegate {
    func didSelectLocation(latitude: Double, longitude: Double, address: String) {
        self.selectedLatitude = latitude
        self.selectedLongitude = longitude
        print("Vybraná lokácia: \(latitude), \(longitude) - Adresa: \(address)")
    }
}
