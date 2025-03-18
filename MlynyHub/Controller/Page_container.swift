//
//  Page_container.swift
//  MlynyHub
//
//  Created by Andrej Kazimir on 18/03/2025.
//

import UIKit

class Page_container: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    lazy var pages: [UIViewController] = {
        return [
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Settings_page"),
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "All_events_page"),
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Add_event_page"),
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "My_events_page"),
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "My_profile_page")
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dataSource = self
        self.delegate = self


        // 🌟 Nastavíme ako prvú obrazovku druhý Page (All_events_page)
        let startIndex = 1 // Toto znamená, že začíname na druhom page (index 1)
            
        if pages.indices.contains(startIndex) {
            setViewControllers([pages[startIndex]], direction: .forward, animated: false, completion: nil)
        }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil}
        return (index > 0) ? pages[index - 1] : nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController) else { return nil }
        return (index < pages.count - 1) ? pages[index + 1] : nil
    }
    

    // UIPageControl indikátor (malé bodky pod stránkami)
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return pages.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        guard let currentVC = viewControllers?.first, let index = pages.firstIndex(where: { type(of: $0) == type(of: currentVC) }) else { return 1 }
        return index
    }
}
