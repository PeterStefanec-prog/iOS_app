//
//  Event_entry.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 18/03/2025.
//


// PARAMETRE EVENTU
import Foundation

struct Event_entry {
    var eventId: String      //  Firestore document ID
    var Title: String
    var Description: String
    var max_slots: Int
    var filled_slots: Int
    var Date: String
    var Image_url: String
    var latitude: Double
    var longitude: Double
}
