//
//  DailyWaterTrackerApp.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 09/07/2022.
//

import SwiftUI

@main
struct DailyWaterTrackerApp: App {
    @StateObject var healthStore = HealthStore()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
            .environmentObject(healthStore)
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
