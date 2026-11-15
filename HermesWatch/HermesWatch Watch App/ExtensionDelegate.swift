// ExtensionDelegate.swift
//
// The extension delegate for the Hermes Watch app.
// Manages app lifecycle events for the WatchKit extension.

import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of the app
        // The WebSocket connection will be established
        // when the app becomes active
        print("Hermes Watch Extension: App finished launching")
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused while the app was inactive
        // Connect WebSocket when app becomes active
        print("Hermes Watch Extension: App became active")
    }
    
    func applicationWillResignActive() {
        // Sent when the app is about to move from active to inactive state
        print("Hermes Watch Extension: App will resign active")
    }
    
    // MARK: - Deep Link Handling
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Handle background tasks (notifications, etc.)
        for task in backgroundTasks {
            switch task {
            case let notification as WKApplicationRefreshBackgroundTask:
                handleNotification(notification)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                handleURLSessionTask(urlSessionTask)
            default:
                break
            }
        }
    }
    
    private func handleNotification(_ task: WKApplicationRefreshBackgroundTask) {
        // Handle notification-based wakeups
        // Could trigger a WebSocket reconnect or status check
        task.setTaskCompletedWithSnapshot(false)
    }
    
    private func handleURLSessionTask(_ task: WKURLSessionRefreshBackgroundTask) {
        // Handle URL session-based wakeups
        task.setTaskCompletedWithSnapshot(false)
    }
}
