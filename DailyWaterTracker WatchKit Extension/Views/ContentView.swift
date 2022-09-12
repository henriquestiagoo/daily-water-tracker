//
//  ContentView.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 09/07/2022.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var healthStore: HealthStore
    @State private var wantsToDrink: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button {
                    wantsToDrink.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Text("Drink")
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .sheet(isPresented: $wantsToDrink) {
                WaterView()
            }
            .task {
                try? await healthStore.requestAuthorization()
            }
        }
        .navigationTitle("Daily Water Tracker")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ContentView()
        }
    }
}
