// HermesWatch Watch App
//
// The main entry point for the Hermes Watch app.
// Uses SwiftUI to create a tabbed interface with:
// - Task Queue (approve/deny pending tasks)
// - Petdex (watch Hermes pet animations)
// - Status (Hermes system status)

import SwiftUI

@main
struct HermesWatch_Watch_App: App {
    
    @StateObject private var taskService = HermesTaskService()
    @StateObject private var webSocketService = HermesWebSocketService()
    
    init() {
        // Register custom view types if needed
        // UIHostingController registration for WatchKit compatibility
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                TabView {
                    // Task Queue Tab
                    NavigationStack {
                        TaskQueueView()
                            .environmentObject(taskService)
                            .navigationTitle("Tasks")
                    }
                    .tabItem {
                        Label("Tasks", systemImage: "checklist")
                    }
                    
                    // Petdex Tab
                    NavigationStack {
                        PetdexView()
                    }
                    .tabItem {
                        Label("Petdex", systemImage: "heart")
                    }
                    
                    // Status Tab
                    NavigationStack {
                        StatusView()
                            .environmentObject(webSocketService)
                    }
                    .tabItem {
                        Label("Status", systemImage: "wifi")
                    }
                }
            }
        }
    }
}
