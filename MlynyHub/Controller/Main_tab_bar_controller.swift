//
//  Main_tab_bar_controller.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 18/03/2025.
//

import UIKit

class Main_tab_bar_controller: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        // 1 tab
        let pageController = Page_container(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        let tab2 = UINavigationController(rootViewController: pageController)
        tab2.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "All_events_logo"), selectedImage: UIImage(named: "All_events_logo"))
        tab2.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        // 2 tab
        let allEventsVC = storyboard.instantiateViewController(withIdentifier: "Settings_page")
        let tab1 = UINavigationController(rootViewController: allEventsVC)
        tab1.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "Settings_logo"), selectedImage: UIImage(named: "Settings_logo"))
        tab1.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        // 3 tab
        let addEventVC = storyboard.instantiateViewController(withIdentifier: "Add_event_page")
        let tab3 = UINavigationController(rootViewController: addEventVC)
        tab3.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "Add_event_logo"), selectedImage: UIImage(named: "Add_event_logo"))
        tab3.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        // 4 tab
        let myEventsVC = storyboard.instantiateViewController(withIdentifier: "My_events_page")
        let tab4 = UINavigationController(rootViewController: myEventsVC)
        tab4.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "My_events_logo"), selectedImage: UIImage(named: "My_events_logo"))
        tab4.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        // 5 tab
        let profileVC = storyboard.instantiateViewController(withIdentifier: "My_profile_page")
        let tab5 = UINavigationController(rootViewController: profileVC)
        tab5.tabBarItem = UITabBarItem(title: "", image: UIImage(named: "My_profile_logo"), selectedImage: UIImage(named: "My_profile_logo"))
        tab5.tabBarItem.imageInsets = UIEdgeInsets(top: 6, left: 0, bottom: -6, right: 0)

        self.viewControllers = [tab1, tab2, tab3, tab4, tab5]

        self.selectedIndex = 1
    }

        
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
