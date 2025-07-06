import SwiftUI

struct AddLiquidView: View {
    @EnvironmentObject private var liquidManager: LiquidManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedType: LiquidType = .coffee
    @State private var amount: String = ""
    @State private var caffeine: String = ""
    @State private var calories: String = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Liquid Type")) {
                    Picker("Type", selection: $selectedType) {
                        ForEach(LiquidType.allCases.filter { $0 != .water }, id: \.self) { type in
                            HStack {
                                Image(systemName: icon(for: type))
                                Text(type.displayName)
                            }.tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }
                
                Section(header: Text("Amount")) {
                    TextField("Amount (ml)", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Caffeine (mg)")) {
                    TextField("Caffeine", text: $caffeine)
                        .keyboardType(.numberPad)
                        .onAppear {
                            if caffeine.isEmpty, let def = selectedType.defaultCaffeine {
                                caffeine = "\(def)"
                            }
                        }
                }
                
                Section(header: Text("Calories (optional)")) {
                    TextField("Calories", text: $calories)
                        .keyboardType(.numberPad)
                        .onAppear {
                            if calories.isEmpty, let def = selectedType.defaultCalories {
                                calories = "\(def)"
                            }
                        }
                }
            }
            .navigationTitle("Add Liquid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .alert("Invalid Input", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text("Please enter a valid amount.")
            }
        }
        .onChange(of: selectedType) { _, newType in
            if let def = newType.defaultCaffeine { caffeine = "\(def)" }
            if let def = newType.defaultCalories { calories = "\(def)" }
        }
    }
    
    private var isValid: Bool {
        guard let amt = Double(amount), amt > 0 else { return false }
        return true
    }
    
    private func save() {
        guard let amt = Double(amount), amt > 0 else {
            showError = true
            return
        }
        let caf = Int(caffeine)
        let cal = Int(calories)
        let drink = LiquidDrink(type: selectedType, name: selectedType.displayName, amount: amt, caffeine: caf, calories: cal)
        liquidManager.addDrink(drink)
        dismiss()
    }
    
    private func icon(for type: LiquidType) -> String {
        switch type {
        case .coffee: return "cup.and.saucer.fill"
        case .tea: return "leaf.fill"
        case .soda: return "bubbles.and.sparkles"
        case .energyDrink: return "bolt.fill"
        case .other: return "drop.fill"
        default: return "drop"
        }
    }
}

#Preview {
    AddLiquidView().environmentObject(LiquidManager())
} 