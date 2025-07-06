//
//  PerformanceMonitor.swift
//  Drinkly
//
//  Created by Yakup ACAR on 5.07.2025.
//

import Foundation
import SwiftUI

/// Performance monitoring utility for tracking app performance
@MainActor
class PerformanceMonitor: ObservableObject {
    
    // MARK: - Singleton
    static let shared = PerformanceMonitor()
    
    // MARK: - Published Properties
    @Published var isEnabled: Bool = false
    @Published var metrics: [String: PerformanceMetric] = [:]
    
    // MARK: - Private Properties
    private var startTimes: [String: Date] = [:]
    private var memoryUsage: [String: UInt64] = [:]
    
    // MARK: - Initialization
    private init() {
        #if DEBUG
        isEnabled = true
        #endif
    }
    
    // MARK: - Public Methods
    
    /// Starts timing a performance metric
    /// - Parameter name: Name of the metric
    func startTiming(_ name: String) {
        guard isEnabled else { return }
        startTimes[name] = Date()
        
        let metric = PerformanceMetric(
            name: name,
            startTime: Date(),
            memoryUsage: getCurrentMemoryUsage()
        )
        metrics[name] = metric
    }
    
    /// Ends timing a performance metric
    /// - Parameter name: Name of the metric
    func endTiming(_ name: String) {
        guard isEnabled, let startTime = startTimes[name] else { return }
        
        let duration = Date().timeIntervalSince(startTime)
        let currentMemory = getCurrentMemoryUsage()
        
        if var metric = metrics[name] {
            metric.duration = duration
            metric.endTime = Date()
            metric.memoryUsage = currentMemory
            metric.memoryDelta = Int64(currentMemory) - Int64(metric.memoryUsage ?? 0)
            metrics[name] = metric
        }
        
        startTimes.removeValue(forKey: name)
    }
    
    /// Measures performance of a closure
    /// - Parameters:
    ///   - name: Name of the metric
    ///   - operation: Operation to measure
    /// - Returns: Result of the operation
    func measure<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        startTiming(name)
        defer { endTiming(name) }
        return try operation()
    }
    
    /// Measures performance of an async operation
    /// - Parameters:
    ///   - name: Name of the metric
    ///   - operation: Async operation to measure
    /// - Returns: Result of the operation
    func measureAsync<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        startTiming(name)
        defer { endTiming(name) }
        return try await operation()
    }
    
    /// Clears all metrics
    func clearMetrics() {
        metrics.removeAll()
        startTimes.removeAll()
    }
    
    /// Gets a summary of all metrics
    /// - Returns: Summary string
    func getSummary() -> String {
        var summary = "Performance Summary:\n"
        
        for (name, metric) in metrics.sorted(by: { $0.key < $1.key }) {
            summary += "\(name): \(String(format: "%.3f", metric.duration))s"
            if let memoryDelta = metric.memoryDelta {
                summary += " (Memory: \(memoryDelta > 0 ? "+" : "")\(memoryDelta) bytes)"
            }
            summary += "\n"
        }
        
        return summary
    }
    
    // MARK: - Private Methods
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}

// MARK: - Performance Metric Model
struct PerformanceMetric {
    let name: String
    let startTime: Date
    var endTime: Date?
    var duration: TimeInterval = 0
    var memoryUsage: UInt64?
    var memoryDelta: Int64?
}

// MARK: - View Extension for Performance Monitoring
extension View {
    /// Measures the performance of a view update
    /// - Parameter name: Name of the performance metric
    /// - Returns: View with performance monitoring
    func measurePerformance(_ name: String) -> some View {
        self.onAppear {
            PerformanceMonitor.shared.startTiming(name)
        }
        .onDisappear {
            PerformanceMonitor.shared.endTiming(name)
        }
    }
} 