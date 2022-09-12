//
//  LogWaterButton.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 10/07/2022.
//

import SwiftUI
import HealthKit

enum Glass {
    case small
    case medium
    case large

    var title: String {
        switch self {
        case .small: return "330ml"
        case .medium: return "500ml"
        case .large: return "1500ml"
        }
    }

    var value: Double {
        switch self {
        case .small: return 330
        case .medium: return 500
        case .large: return 1500
        }
    }
}

struct LogWaterButton: View {
    private let title: String
    private let size: Glass
    private let onTap: (HKQuantity) -> Void

    init(
        size: Glass,
        onTap: @escaping (HKQuantity) -> Void
    ) {
        self.title = size.title
        self.size = size
        self.onTap = onTap
    }

    var body: some View {
        Button(title, action: tapped)
    }

    private func tapped() {
        // HealthKit uses an HKUnit to identity the unit type for the value you'll store.
        let unit: HKUnit
        let value: Double

        unit = .literUnit(with: .milli)
        value = size.value

        // Using unit and value, you create an HKQuantity, which you can later convert to an HKSample for saving
        let quantity = HKQuantity(unit: unit, doubleValue: value)
        // You pass that quantity to the completion handler.
        onTap(quantity)
    }
}

struct LogWaterButton_Previews: PreviewProvider {
    static var previews: some View {
        LogWaterButton(size: .small) { _ in }
    }
}
