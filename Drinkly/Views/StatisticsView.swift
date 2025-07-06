//
//  StatisticsView.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject private var liquidManager: LiquidManager
    @State private var selectedTab: StatTab = .water
    @State private var selectedTimeRange: TimeRange = .daily
    
    enum StatTab: String, CaseIterable, Identifiable {
        case water = "Water"
        case other = "Other Liquids"
        case total = "Total"
        var id: String { rawValue }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Main tab picker
                Picker("Tab", selection: $selectedTab) {
                    ForEach(StatTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Time range picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases) { timeRange in
                        Text(timeRange.displayName).tag(timeRange)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                TabView(selection: $selectedTab) {
                    waterStats
                        .tag(StatTab.water)
                    otherStats
                        .tag(StatTab.other)
                    totalStats
                        .tag(StatTab.total)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Water Statistics
    private var waterStats: some View {
        VStack(spacing: 24) {
            // Summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatisticsSummaryCard(
                    title: "Total Water",
                    value: String(format: "%.1fL", liquidManager.totalWater / 1000),
                    subtitle: "Today",
                    color: .blue
                )
                StatisticsSummaryCard(
                    title: "Water Progress",
                    value: String(format: "%.0f%%", liquidManager.waterProgress * 100),
                    subtitle: "Goal",
                    color: .blue
                )
            }
            
            // Time-based chart
            TimeBasedChart(
                data: liquidManager.getWaterTimeData(for: selectedTimeRange),
                title: "Water Intake - \(selectedTimeRange.displayName)",
                color: .blue,
                timeRange: selectedTimeRange
            )
            
            Spacer()
        }.padding()
    }
    
    // MARK: - Other Liquids Statistics
    private var otherStats: some View {
        VStack(spacing: 24) {
            // Summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatisticsSummaryCard(
                    title: "Other Liquids",
                    value: String(format: "%.1fL", liquidManager.totalOtherLiquids / 1000),
                    subtitle: "Today",
                    color: .orange
                )
                StatisticsSummaryCard(
                    title: "Caffeine",
                    value: "\(liquidManager.totalCaffeine) mg",
                    subtitle: "Total",
                    color: .purple
                )
            }
            
            // Time-based chart
            TimeBasedChart(
                data: liquidManager.getOtherLiquidsTimeData(for: selectedTimeRange),
                title: "Other Liquids - \(selectedTimeRange.displayName)",
                color: .orange,
                timeRange: selectedTimeRange
            )
            
            Spacer()
        }.padding()
    }
    
    // MARK: - Total Liquids Statistics
    private var totalStats: some View {
        VStack(spacing: 24) {
            // Summary cards
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatisticsSummaryCard(
                    title: "Total Intake",
                    value: String(format: "%.1fL", liquidManager.totalLiquids / 1000),
                    subtitle: "Today",
                    color: .green
                )
                StatisticsSummaryCard(
                    title: "Goal Progress",
                    value: String(format: "%.0f%%", liquidManager.totalProgress * 100),
                    subtitle: "Target",
                    color: .green
                )
            }
            
            // Time-based chart for total (combine water and other liquids)
            let totalData = liquidManager.getWaterTimeData(for: selectedTimeRange).map { waterData in
                let otherData = liquidManager.getOtherLiquidsTimeData(for: selectedTimeRange)
                    .first { $0.label == waterData.label }
                let otherAmount = otherData?.value ?? 0
                return TimeData(
                    id: UUID(),
                    label: waterData.label,
                    value: waterData.value + otherAmount,
                    date: waterData.date,
                    caffeine: waterData.caffeine + (otherData?.caffeine ?? 0),
                    drinkCount: waterData.drinkCount + (otherData?.drinkCount ?? 0)
                )
            }
            
            TimeBasedChart(
                data: totalData,
                title: "Total Liquids - \(selectedTimeRange.displayName)",
                color: .green,
                timeRange: selectedTimeRange
            )
            
            Spacer()
        }.padding()
    }
}

// MARK: - Time-based Chart Component
struct TimeBasedChart: View {
    let data: [TimeData]
    let title: String
    let color: Color
    let timeRange: TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if data.isEmpty {
                EmptyChartView()
            } else if #available(iOS 16.0, *) {
                Chart(data) { item in
                    BarMark(
                        x: .value("Time", item.label),
                        y: .value("Amount", item.value)
                    )
                    .foregroundStyle(color.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            Text("\(String(format: "%.1f", (value.as(Double.self) ?? 0) / 1000))L")
                                .font(.caption)
                        }
                    }
                }
            } else {
                Text("Charts available in iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
            
            // Statistics summary
            if !data.isEmpty {
                ChartSummaryView(data: data, color: color)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Chart Summary View
struct ChartSummaryView: View {
    let data: [TimeData]
    let color: Color
    
    private var totalAmount: Double {
        data.reduce(0) { $0 + $1.value }
    }
    
    private var averageAmount: Double {
        data.isEmpty ? 0 : totalAmount / Double(data.count)
    }
    
    private var maxAmount: Double {
        data.map { $0.value }.max() ?? 0
    }
    
    private var totalCaffeine: Int {
        data.reduce(0) { $0 + $1.caffeine }
    }
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatisticsStatItem(title: "Total", value: String(format: "%.1fL", totalAmount / 1000), color: color)
            StatisticsStatItem(title: "Average", value: String(format: "%.1fL", averageAmount / 1000), color: color)
            StatisticsStatItem(title: "Max", value: String(format: "%.1fL", maxAmount / 1000), color: color)
            StatisticsStatItem(title: "Caffeine", value: "\(totalCaffeine) mg", color: .purple)
        }
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("No Data Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Start drinking to see your statistics")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 200)
    }
}

// MARK: - Statistics Stat Item (renamed to avoid conflict)
struct StatisticsStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Statistics Summary Card (renamed to avoid conflict)
struct StatisticsSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Preview
#Preview {
    StatisticsView().environmentObject(LiquidManager())
}
