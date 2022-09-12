//
//  HealthStore.swift
//  DailyWaterTracker WatchKit Extension/
//
//  Created by Tiago Henriques on 10/07/2022.
//

import Foundation
import HealthKit

import Foundation
import HealthKit

class HealthStore: NSObject, ObservableObject {

    private var healthStore: HKHealthStore?

    private let waterQuantityType = HKQuantityType.quantityType(forIdentifier: .dietaryWater)!

    private var preferredWaterUnit = HKUnit.fluidOunceUS()

    // Need to know whether the user is currently allowing you to write water-related data.
    var isWaterEnabled: Bool {
        let status = healthStore?.authorizationStatus(for: waterQuantityType)
        return status == .sharingAuthorized
    }

    @Published var consumed = ""
    @Published var graphData: [WaterGraphData]?

    private let consumedFormat: MeasurementFormatter = {
      var fmt = MeasurementFormatter()
      fmt.unitOptions = .naturalScale
      return fmt
    }()

    public override init() {
        // If the device can’t use Apple Health, you quietly exit. If it can, you initialize the HKHealthStore.
        guard HKHealthStore.isHealthDataAvailable() else {
            super.init()
            return
        }

        healthStore = HKHealthStore()
        super.init()
    }
    
    func requestAuthorization() async throws {
        try await healthStore!.requestAuthorization(
          toShare: [waterQuantityType],
          read: [waterQuantityType]
        )

        // As you can see, it’s possible to determine what type of units your user prefers to see their measurements. You initialized the property to HKUnit.fluidOuncesUS() because there must be a value before the initializer ends.
        guard let types = try? await healthStore?.preferredUnits(for: [waterQuantityType]) else { return }
        preferredWaterUnit = types[waterQuantityType]!
    }

    func waterConsumptionGraphData() async throws {
        guard let healthStore = healthStore else {
            throw HKError(.errorHealthDataUnavailable)
        }

        await updateStatus()

        // After verifying you can use HealthKit, you determine the start of the day six days ago and then set up a predicate to query all data from that time forward.
        var start = Calendar.current.date(byAdding: .day, value: -6, to: Date.now)!
        start = Calendar.current.startOfDay(for: start)

        let predicate = HKQuery.predicateForSamples(withStart: start, end: nil, options: .strictStartDate)
        // Then, you construct a query for water consumption, using the predicate, and ask HealthKit to sum up each day for you. You specify that it should perform the summation across day boundaries.
        let query = HKStatisticsCollectionQuery(
            quantityType: waterQuantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: start,
            intervalComponents: .init(day: 1)
        )
        // You call initialResultsHandler the first time the query completes.
        query.initialResultsHandler = { _, results, _ in
            self.updateGraph(start: start, results: results)
        }
        // Then you call statisticsUpdateHandler any time the user adds new data. By not specifying an end date on the predicate, you ensure that updates are captured.
        query.statisticsUpdateHandler = { _, _, results, _ in
            self.updateGraph(start: start, results: results)
        }

        healthStore.execute(query)
    }

    // Since both of the handlers perform the same actions, create a helper method that they'll both call.
    func updateGraph(start: Date, results: HKStatisticsCollection?) {
      // If no results return, then you exit early.
      guard let results = results else { return }
      // You create a dictionary keyed by the last seven days that contains the data to graph.
      var statsForDay: [Date: WaterGraphData] = [:]

      for i in 0 ... 6 {
        let day = Calendar.current.date(byAdding: .day, value: i, to: start)!
        statsForDay[day] = WaterGraphData(for: day)
      }

      // Then, you loop through the computed results.
      results.enumerateStatistics(from: start, to: Date.now) { statistic, _ in
        var value = 0.0
        // If there’s data for the day, you sum the data counts, convert the value to their preferred unit of measurement and round up to the nearest whole number.
        if let sum = statistic.sumQuantity() {
          value = sum.doubleValue(for: self.preferredWaterUnit).rounded(.up)
        }
        // Then, you record the amount of water consumed for the day.
        statsForDay[statistic.startDate]?.value = value
      }
      // You take the values for each day in ascending order.
      let statistics = statsForDay
            .sorted { $0.key < $1.key}
            .map { $0.value }

        DispatchQueue.main.async {
            self.graphData = statistics
        }
    }

    private func drankToday() async throws -> Measurement<UnitVolume> {
      guard let healthStore = healthStore else {
        throw HKError(.errorHealthDataUnavailable)
      }
      // You want to determine all water consumed between the start of the day and now.
      let start = Calendar.current.startOfDay(for: Date.now)

      let predicate = HKQuery.predicateForSamples(withStart: start, end: Date.now, options: .strictStartDate)
      // Once again, you wrap a completion handler method to use it async instead. Notice this time, nothing inside the block will throw an error, so you use withCheckedContinuation instead of withCheckedThrowingContinuation.
      return await withCheckedContinuation{ continuation in
        // Using an HKStatisticsQuery lets you ask HealthKit to add all the values via the .cumulativeSum, so you get a single result.
        let query = HKStatisticsQuery(
          quantityType: waterQuantityType,
          quantitySamplePredicate: predicate,
          options: .cumulativeSum
        ) { _, statistics, _ in
          // If you don’t have read permission or data, you state that the user drank 0 liters.
          guard let quantity = statistics?.sumQuantity() else {
            continuation.resume(returning: .init(value: 0, unit: .liters))
            return
          }
          // Determine both the number of US fluid ounces and the number of liters the user drank.
          let liters = quantity.doubleValue(for: .liter())
          // Return both the number of ounces the user drank as well as the liters.
          continuation.resume(returning: .init(value: liters, unit: .liters))
        }
        // Execute the query.
        healthStore.execute(query)
      }
    }

    private func save(_ sample: HKSample) async throws {
      // If healthStore wasn’t set, you shouldn’t have called this method to begin with, so you throw an appropriate error.
      guard let healthStore = healthStore else {
        throw HKError(.errorHealthDataUnavailable)
      }

      // withCheckedThrowingContinuation takes a body of code and pauses until the provided CheckedContinuation<T, Error> is called.
      let _: Bool = try await withCheckedThrowingContinuation { continuation in
        // Then, you save the sample to Apple Health.
        healthStore.save(sample) { _, error in
          if let error = error {
            // If the asynchronous save fails, you pass the error thrown to resume(throwing:).
            continuation.resume(throwing: error)
            return
          }
          // If the call succeeds, you have to return something. In this case, it’s just a boolean true value.
          continuation.resume(returning: true)
        }
      }
    }

    // Implement an async method to store water consumption as you did for brushing your teeth.
    func logWater(quantity: HKQuantity) async throws {
        guard isWaterEnabled else { return }

        // Generate a sample to save. Notice how you specify an actual quantity this time, and the start and end dates are the current time.
        let sample = HKQuantitySample(
            type: waterQuantityType,
            quantity: quantity,
            start: Date.now,
            end: Date.now
        )
        // Save the data, if you can.
        try await save(sample)

        await updateStatus()
    }

    func updateStatus() async {
      // If you can’t read the current water status, you set a couple of default values.
        guard let measurement = try? await drankToday() else {
          DispatchQueue.main.async {
              self.consumed = "0"
          }
        return
      }
      // If you can read the data, you format the amount of water consumed via a MeasurementFormatter.
        DispatchQueue.main.async {
            self.consumed = self.consumedFormat.string(from: measurement)
        }
    }

}
