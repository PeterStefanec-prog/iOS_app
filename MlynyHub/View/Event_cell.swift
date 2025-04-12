//
//  Event_cell.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 18/03/2025.
//

import UIKit

class Event_cell: UITableViewCell {

    @IBOutlet weak var Background_frame: UIView!
    @IBOutlet weak var Event_image: UIImageView!
    @IBOutlet weak var Event_name: UILabel!
    @IBOutlet weak var Event_slots: UILabel!
    
    @IBOutlet weak var Logo_image: UIImageView!
    @IBOutlet weak var Event_location: UILabel!
    @IBOutlet weak var Event_date: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        //Zaoblenie pozadia a obrazka
        Background_frame.layer.cornerRadius = Event_image.frame.size.height / 10
        Event_image.layer.cornerRadius = Event_image.frame.size.height / 10
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
