//
//  WaterView.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 10/07/2022.
//

import SwiftUI
import HealthKit

struct WaterView: View {
    @EnvironmentObject var healthStore: HealthStore

    var body: some View {
        ScrollView {
            VStack {
                if healthStore.isWaterEnabled {
                    Text("Add water")
                        .font(.headline)
                    
                    HStack {
                        LogWaterButton(size: .medium) { logWater(quantity: $0) }
                        LogWaterButton(size: .large) { logWater(quantity: $0) }
                    }
                    .padding(.bottom)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Today:")
                                .font(.headline)
                            Text(healthStore.consumed)
                                .font(.body)
                        }
                    }
                    
                    BarChart(data: healthStore.graphData)
                      .padding()
                    
                } else {
                    // If they don’t grant permissions, display a user-friendly message.
                    Text("Please enable water tracking permissions in Apple Health.")
                        .font(.caption)
                }
            }
        }
        .task {
            try? await healthStore.waterConsumptionGraphData()
        }
    }
    
    private func logWater(quantity: HKQuantity) {
        // The helper wraps the asynchronous call in Task since the SwiftUI button doesn’t know how to call an async.
        Task {
            try await healthStore.logWater(quantity: quantity)
        }
    }
}

struct WaterView_Previews: PreviewProvider {
    static var previews: some View {
        WaterView()
    }
}
