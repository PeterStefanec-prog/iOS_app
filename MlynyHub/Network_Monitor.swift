//
//  Network_Monitor.swift
//  MlynyHub
//
//  Created by Peter Štefanec on 09/05/2025.
//

import Foundation
import Network

final class NetworkMonitor {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")
    private(set) var isConnected: Bool = false

    /// Notification name pre zmenu stavu
    static let statusChangedNotification = Notification.Name("NetworkStatusChanged")
    
    private var isStarted = false
    private var didPostInitial  = false
    
    private init() {}
    
    /// startuje sa monitor az po zavolani tejto funkcie
    func start() {
        guard !isStarted else { return }
        isStarted = true
        
        monitor.pathUpdateHandler = { [weak self] path in
              guard let self = self else { return }
              let newStatus = (path.status == .satisfied)
        
        // Post if it’s the very first callback _or_ if the status actually changed
        if !self.didPostInitial || self.isConnected != newStatus {
            self.isConnected     = newStatus
            self.didPostInitial  = true
            NotificationCenter.default.post(
                name: Self.statusChangedNotification,
                object: newStatus
            )
        }
    }
        
        // 2) az teraz spustame monitoring
        monitor.start(queue: queue)
    }
}
