//
//  WaterGraphData.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 10/07/2022.
//

import Foundation

struct WaterGraphData: Identifiable {
    let id = UUID()
    var value = 0.0
    let symbol: String
    
    init(
        value: Double,
        symbol: String
    ) {
        self.value = value
        self.symbol = symbol
    }
    
    init(for day: Date) {
        let dayNumber = Calendar.current.component(.weekday, from: day) - 1
        self.symbol = Calendar.current.veryShortStandaloneWeekdaySymbols[dayNumber]
    }
}
