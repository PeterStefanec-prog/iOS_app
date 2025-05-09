//
//  ProfileController.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 09/05/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

class ProfileController: UIViewController {
    //outlets
    @IBOutlet weak var FacultyLabel: UILabel!
    @IBOutlet weak var UniversityLabel: UILabel!
    @IBOutlet weak var AboutMeLabel: UILabel!
    @IBOutlet weak var FirstNameLastNameLabel: UILabel!
    @IBOutlet weak var Profile_picture_image: UIImageView!
    @IBOutlet weak var UsernameLabel: UILabel!
    // Stub outlet to match storyboard connection
    @IBOutlet weak var Change_Username_Button: UIButton!

    private let db = Firestore.firestore()
    private var userRef: DocumentReference? {
        guard let uid = Auth.auth().currentUser?.uid else { return nil }
        return db.collection("users").document(uid)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileImageView()
        loadProfile()
    }
    //to be changed
    private func setupProfileImageView() {
        Profile_picture_image.layer.cornerRadius = Profile_picture_image.frame.width / 2
        Profile_picture_image.clipsToBounds = true
        Profile_picture_image.isUserInteractionEnabled = true
    }
    //loading profile from db
    private func loadProfile() {
        guard let ref = userRef else { return }
        ref.getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data(), error == nil else { return }
            self.UsernameLabel.text = data["username"] as? String
            if let name = data["name"] as? String,
               let surname = data["surname"] as? String {
                self.FirstNameLastNameLabel.text = "\(name) \(surname)"
            }
            self.AboutMeLabel.text = data["aboutMe"] as? String ?? ""
            self.UniversityLabel.text = data["university"] as? String ?? ""
            self.FacultyLabel.text = data["faculty"] as? String ?? ""
            if let urlString = data["profileImageURL"] as? String,
               let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data = data, let img = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        self.Profile_picture_image.image = img
                    }
                }.resume()
            }
        }
    }
    //changing profile picture
    @IBAction func ChangeProfilePicturePressed(_ sender: UIButton) {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    //changing username
    @IBAction func ChangeUsernamePressed(_ sender: Any) {
        promptForField("username", title: "Zmeniť užívateľské meno", placeholder: "Nové užívateľské meno")
    }
    //changing aboutme
    @IBAction func ChangeAboutMePressed(_ sender: Any) {
        promptForField("aboutMe", title: "Zmeniť About Me", placeholder: "O mne...")
    }
    //changing uni
    @IBAction func ChangeUniversityPressed(_ sender: Any) {
        promptForField("university", title: "Zmeniť univerzitu", placeholder: "Univerzita")
    }
    //changing faculty
    @IBAction func ChangeFacultyPressed(_ sender: Any) {
        promptForField("faculty", title: "Zmeniť fakultu", placeholder: "Fakulta")
    }
    //function that reads text, changes db
    private func promptForField(_ key: String, title: String, placeholder: String) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { tf in tf.placeholder = placeholder }
        alert.addAction(UIAlertAction(title: "Zrušiť", style: .cancel))
        alert.addAction(UIAlertAction(title: "Uložiť", style: .default) { _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty,
                  let ref = self.userRef else { return }
            ref.updateData([key: text]) { error in
                if let e = error {
                    // Use existing UIViewController.showAlert extension
                    self.showAlert(title: "Chyba", message: e.localizedDescription)
                } else {
                    DispatchQueue.main.async {
                        switch key {
                        case "username": self.UsernameLabel.text = text
                        case "aboutMe": self.AboutMeLabel.text = text
                        case "university": self.UniversityLabel.text = text
                        case "faculty": self.FacultyLabel.text = text
                        default: break
                        }
                    }
                }
            }
        })
        present(alert, animated: true)
    }
    //uploading pfp
    private func uploadProfileImage(_ image: UIImage) {
        guard let uid = Auth.auth().currentUser?.uid,
              let data = image.jpegData(compressionQuality: 0.5) else { return }
        let name = "profile_\(uid).jpg"
        let ref = Storage.storage().reference().child("profile_images/\(name)")
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        ref.putData(data, metadata: meta) { _, error in
            if let e = error {
                self.showAlert(title: "Chyba", message: e.localizedDescription)
                return
            }
            ref.downloadURL { url, _ in
                if let url = url, let r = self.userRef {
                    r.updateData(["profileImageURL": url.absoluteString])
                }
            }
        }
    }
}

// MARK: - PHPickerViewControllerDelegate
extension ProfileController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first,
              item.itemProvider.canLoadObject(ofClass: UIImage.self) else { return }
        item.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] img, _ in
            guard let self = self, let image = img as? UIImage else { return }
            DispatchQueue.main.async {
                self.Profile_picture_image.image = image
            }
            self.uploadProfileImage(image)
        }
    }
}
