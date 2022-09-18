//
//  BarChart.swift
//  DailyWaterTracker WatchKit Extension
//
//  Created by Tiago Henriques on 10/07/2022.
//

import SwiftUI
import SwiftUICharts

struct BarChart: View {
  private let legend = Legend(color: .blue, label: "Water Consumption (ml)")
  private let points: [DataPoint]?
  private let style = BarChartStyle(barMinHeight: 100, showAxis: true, axisLeadingPadding: 0, showLabels: true, labelCount: nil, showLegends: true)
    
  init(data: [WaterGraphData]?) {
      guard let data = data else {
          points = nil
          return
      }
      
      var points: [DataPoint] = []

      for element in data {
          let point = DataPoint(
            value: element.value,
            label: LocalizedStringKey(element.symbol),
            legend: legend
          )
          points.append(point)
      }
      self.points = points
  }

  var body: some View {
      if let points = points {
          BarChartView(dataPoints: points, limit: nil)
              .chartStyle(style)
      } else {
          EmptyView()
      }
  }
}

struct BarChart_Previews: PreviewProvider {
    let limit = DataPoint(value: 130, label: "5", legend: Legend(color: .green, label: "Fat burning", order: 3))

    static var previews: some View {
        BarChart(data: [
            WaterGraphData(value: 104, symbol: "1"),
            WaterGraphData(value: 105, symbol: "2"),
            WaterGraphData(value: 300, symbol: "3"),
            WaterGraphData(value: 400, symbol: "4"),
            WaterGraphData(value: 500, symbol: "5"),
            WaterGraphData(value: 600, symbol: "6"),
            WaterGraphData(value: 700, symbol: "7")
        ])
    }
}
