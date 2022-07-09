//
//  DailyWaterTrackerApp.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 09/07/2022.
//

import SwiftUI

@main
struct DailyWaterTrackerApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
