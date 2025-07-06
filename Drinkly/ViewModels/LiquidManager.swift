import Foundation
import SwiftUI

/// Tüm sıvı takibini yöneten ViewModel
@MainActor
class LiquidManager: ObservableObject {
    // MARK: - Published Properties
    @Published var drinks: [LiquidDrink] = [] // Günlük tüm içecekler (su dahil)
    @Published var showingAddLiquidSheet = false
    
    // MARK: - Private Properties
    private var waterManager: WaterManager?
    
    // MARK: - Computed Properties
    /// Günlük hedef (waterManager'dan al ve ml'ye çevir)
    var dailyGoal: Double {
        guard let waterManager = waterManager else { return 2500 } // ml
        return waterManager.dailyGoal * 1000 // L'den ml'ye çevir
    }
    /// Sadece su içecekleri
    var waterDrinks: [LiquidDrink] {
        drinks.filter { $0.type == .water }
    }
    /// Diğer sıvılar (su hariç)
    var otherDrinks: [LiquidDrink] {
        drinks.filter { $0.type != .water }
    }
    /// Toplam su miktarı (ml)
    var totalWater: Double {
        waterDrinks.reduce(0) { $0 + $1.amount }
    }
    /// Toplam diğer sıvılar (ml)
    var totalOtherLiquids: Double {
        otherDrinks.reduce(0) { $0 + $1.amount }
    }
    /// Toplam sıvı (ml)
    var totalLiquids: Double {
        drinks.reduce(0) { $0 + $1.amount }
    }
    /// Günlük kafein toplamı (mg)
    var totalCaffeine: Int {
        drinks.compactMap { $0.caffeine }.reduce(0, +)
    }
    /// Günlük kalori toplamı (kcal)
    var totalCalories: Int {
        drinks.compactMap { $0.calories }.reduce(0, +)
    }
    /// Hedefe ulaşma yüzdesi (sadece su)
    var waterProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        let progress = totalWater / dailyGoal
        
        // Floating point precision sorunu için hedefe ulaşıldığında %100 döndür
        if progress >= 0.999 || totalWater >= dailyGoal {
            return 1.0
        }
        return min(1.0, progress)
    }
    /// Hedefe ulaşma yüzdesi (tüm sıvılar)
    var totalProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        let progress = totalLiquids / dailyGoal
        
        // Floating point precision sorunu için hedefe ulaşıldığında %100 döndür
        if progress >= 0.999 || totalLiquids >= dailyGoal {
            return 1.0
        }
        return min(1.0, progress)
    }
    /// Son eklenen içecek
    var lastDrink: LiquidDrink? {
        drinks.sorted { $0.date > $1.date }.first
    }
    
    // MARK: - Methods
    /// WaterManager'ı set et
    func setWaterManager(_ manager: WaterManager) {
        waterManager = manager
    }
    
    /// Sıvı ekle
    func addDrink(_ drink: LiquidDrink) {
        objectWillChange.send()
        drinks.append(drink)
        saveDrinks()
    }
    /// Sıvı sil
    func removeDrink(_ drink: LiquidDrink) {
        drinks.removeAll { $0.id == drink.id }
        saveDrinks()
    }
    /// Günlük içecekleri yükle (tarihe göre)
    func loadDrinks(for date: Date = Date()) {
        let key = storageKey(for: date)
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([LiquidDrink].self, from: data) {
            self.drinks = decoded
        } else {
            self.drinks = []
        }
    }
    /// Günlük içecekleri kaydet
    func saveDrinks(for date: Date = Date()) {
        let key = storageKey(for: date)
        if let data = try? JSONEncoder().encode(drinks) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    /// Bugünün anahtarını üret
    private func storageKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "liquids_" + formatter.string(from: date)
    }
    /// Tüm geçmiş günler için toplamları döndür (istatistikler için)
    func getDrinks(forDays days: Int) -> [[LiquidDrink]] {
        let calendar = Calendar.current
        return (0..<days).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: Date()) ?? Date()
            let key = storageKey(for: date)
            if let data = UserDefaults.standard.data(forKey: key),
               let decoded = try? JSONDecoder().decode([LiquidDrink].self, from: data) {
                return decoded
            } else {
                return []
            }
        }
    }
    /// Get daily totals for the last N days
    func getDailyTotals(forDays days: Int) -> [(water: Double, other: Double, total: Double)] {
        let calendar = Calendar.current
        let today = Date()
        var totals: [(water: Double, other: Double, total: Double)] = []
        
        for dayOffset in 0..<days {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let drinksInDay = drinks.filter { drink in
                drink.date >= startOfDay && drink.date < endOfDay
            }
            
            let waterAmount = drinksInDay.filter { $0.type == .water }.reduce(0) { $0 + $1.amount }
            let otherAmount = drinksInDay.filter { $0.type != .water }.reduce(0) { $0 + $1.amount }
            let totalAmount = waterAmount + otherAmount
            
            totals.append((water: waterAmount, other: otherAmount, total: totalAmount))
        }
        
        return totals.reversed()
    }
    /// Günlük kafein toplamları
    func getDailyCaffeine(forDays days: Int) -> [Int] {
        getDrinks(forDays: days).map { drinks in
            drinks.compactMap { $0.caffeine }.reduce(0, +)
        }
    }
    /// Günlük kalori toplamları
    func getDailyCalories(forDays days: Int) -> [Int] {
        getDrinks(forDays: days).map { drinks in
            drinks.compactMap { $0.calories }.reduce(0, +)
        }
    }
    /// Gün başında sıfırla
    func resetToday() {
        drinks = []
        saveDrinks()
    }
    /// Hedefi güncelle
    func updateDailyGoal(_ goal: Double) {
        // Bu fonksiyonun suManager'dan hedef alması gerekiyor
        // Şimdilik sabit bir değer atanıyor
        // dailyGoal = goal
    }
    /// Uygulama başında yükle
    init() {
        loadDrinks()
        
        // Debug modunda sahte veri eklemeyi kaldır
        // #if DEBUG
        // if drinks.isEmpty {
        //     addSampleData()
        // }
        // #endif
    }
    
    // MARK: - Sample Data (Debug Only) - KALDIRILDI
    // private func addSampleData() {
    //     let calendar = Calendar.current
    //     let today = Date()
    //     
    //     // Add some water today
    //     for hour in [8, 10, 12, 14, 16, 18] {
    //         let time = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today
    //         addDrink(LiquidDrink(type: .water, name: "Water", amount: 250, date: time))
    //     }
    //     
    //     // Add some coffee today
    //     for hour in [7, 9, 15] {
    //         let time = calendar.date(bySettingHour: hour, minute: 30, second: 0, of: today) ?? today
    //         addDrink(LiquidDrink(type: .coffee, name: "Coffee", amount: 200, caffeine: 80, date: time))
    //     }
    // }
    
    // MARK: - Time-based Data Methods
    
    /// Get hourly data for today
    func getHourlyData(for type: LiquidType? = nil) -> [HourlyData] {
        let calendar = Calendar.current
        let today = Date()
        var hourlyData: [HourlyData] = []
        
        for hour in 0..<24 {
            let startOfHour = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today) ?? today
            let endOfHour = calendar.date(bySettingHour: hour, minute: 59, second: 59, of: today) ?? today
            
            let drinksInHour = drinks.filter { drink in
                let drinkDate = calendar.startOfDay(for: drink.date)
                let todayStart = calendar.startOfDay(for: today)
                
                return calendar.isDate(drinkDate, inSameDayAs: todayStart) &&
                       drink.date >= startOfHour &&
                       drink.date <= endOfHour &&
                       (type == nil || drink.type == type)
            }
            
            let totalAmount = drinksInHour.reduce(0) { $0 + $1.amount }
            let totalCaffeine = drinksInHour.reduce(0) { $0 + ($1.caffeine ?? 0) }
            
            hourlyData.append(HourlyData(
                hour: hour,
                amount: totalAmount,
                caffeine: totalCaffeine,
                drinkCount: drinksInHour.count
            ))
        }
        
        return hourlyData
    }
    
    /// Get daily data for the last week
    func getWeeklyData(for type: LiquidType? = nil) -> [DailyData] {
        let calendar = Calendar.current
        let today = Date()
        var weeklyData: [DailyData] = []
        
        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let drinksInDay = drinks.filter { drink in
                drink.date >= startOfDay &&
                drink.date < endOfDay &&
                (type == nil || drink.type == type)
            }
            
            let totalAmount = drinksInDay.reduce(0) { $0 + $1.amount }
            let totalCaffeine = drinksInDay.reduce(0) { $0 + ($1.caffeine ?? 0) }
            
            weeklyData.append(DailyData(
                date: date,
                amount: totalAmount,
                caffeine: totalCaffeine,
                drinkCount: drinksInDay.count
            ))
        }
        
        return weeklyData.reversed()
    }
    
    /// Get daily data for the last month
    func getMonthlyData(for type: LiquidType? = nil) -> [DailyData] {
        let calendar = Calendar.current
        let today = Date()
        var monthlyData: [DailyData] = []
        
        for dayOffset in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
            
            let drinksInDay = drinks.filter { drink in
                drink.date >= startOfDay &&
                drink.date < endOfDay &&
                (type == nil || drink.type == type)
            }
            
            let totalAmount = drinksInDay.reduce(0) { $0 + $1.amount }
            let totalCaffeine = drinksInDay.reduce(0) { $0 + ($1.caffeine ?? 0) }
            
            monthlyData.append(DailyData(
                date: date,
                amount: totalAmount,
                caffeine: totalCaffeine,
                drinkCount: drinksInDay.count
            ))
        }
        
        return monthlyData.reversed()
    }
    
    /// Get monthly data for the last year
    func getYearlyData(for type: LiquidType? = nil) -> [MonthlyData] {
        let calendar = Calendar.current
        let today = Date()
        var yearlyData: [MonthlyData] = []
        
        for monthOffset in 0..<12 {
            let date = calendar.date(byAdding: .month, value: -monthOffset, to: today) ?? today
            let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? date
            
            let drinksInMonth = drinks.filter { drink in
                drink.date >= startOfMonth &&
                drink.date < endOfMonth &&
                (type == nil || drink.type == type)
            }
            
            let totalAmount = drinksInMonth.reduce(0) { $0 + $1.amount }
            let totalCaffeine = drinksInMonth.reduce(0) { $0 + ($1.caffeine ?? 0) }
            
            yearlyData.append(MonthlyData(
                date: date,
                amount: totalAmount,
                caffeine: totalCaffeine,
                drinkCount: drinksInMonth.count
            ))
        }
        
        return yearlyData.reversed()
    }
    
    /// Get water-specific time-based data
    func getWaterTimeData(for timeRange: TimeRange) -> [TimeData] {
        switch timeRange {
        case .daily:
            return getHourlyData(for: .water).map { TimeData(from: $0) }
        case .weekly:
            return getWeeklyData(for: .water).map { TimeData(from: $0) }
        case .monthly:
            return getMonthlyData(for: .water).map { TimeData(from: $0) }
        case .yearly:
            return getYearlyData(for: .water).map { TimeData(from: $0) }
        }
    }
    
    /// Get other liquids (non-water) time-based data
    func getOtherLiquidsTimeData(for timeRange: TimeRange) -> [TimeData] {
        switch timeRange {
        case .daily:
            return getHourlyData(for: .other).map { TimeData(from: $0) }
        case .weekly:
            return getWeeklyData(for: .other).map { TimeData(from: $0) }
        case .monthly:
            return getMonthlyData(for: .other).map { TimeData(from: $0) }
        case .yearly:
            return getYearlyData(for: .other).map { TimeData(from: $0) }
        }
    }
    
    /// Tüm içecek verilerini ve istatistikleri sıfırlar
    func resetAllData() {
        objectWillChange.send()
        drinks.removeAll()
        saveDrinks()
        // Gerekirse UserDefaults veya başka storage temizliği
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "drinkly_liquid_drinks")
    }
} 