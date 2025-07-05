# Drinkly - Your Daily Water Companion

A modern, modular SwiftUI iOS app for tracking daily water intake with smart goal calculation based on location and weather.

## 🏗️ Architecture

The app follows **MVVM (Model-View-ViewModel)** architecture with clean separation of concerns:

### 📁 Project Structure

```
Drinkly/
├── App/
│   └── DrinklyApp.swift          # App entry point with dependency injection
├── Models/
│   ├── WaterDrink.swift          # Water intake data model
│   ├── WaterManager.swift        # Main business logic (ViewModel)
│   └── LocationManager.swift     # Location services
├── Views/
│   ├── MainView.swift            # Main app view
│   ├── SettingsView.swift        # Settings screen
│   ├── DrinkOptionsView.swift    # Water intake options
│   ├── CelebrationView.swift     # Goal achievement celebration
│   └── Components/               # Reusable UI components
│       ├── HeaderView.swift
│       ├── ProgressCircleView.swift
│       ├── AddWaterButton.swift
│       ├── TodayLogView.swift
│       └── MotivationView.swift
├── Services/
│   ├── WeatherManager.swift      # Weather API integration
│   ├── SmartWaterCalculator.swift # Smart goal calculation
│   └── NotificationManager.swift # Local notifications
├── Extensions/
│   ├── Color+Extensions.swift    # App theming
│   └── View+Extensions.swift     # Common UI patterns
└── Utils/
    └── Constants.swift           # App-wide constants
```

## 🎯 Key Features

### ✅ Implemented
- **Daily Water Tracking**: Log water intake with quick amounts or custom values
- **Progress Visualization**: Animated circular progress indicator
- **Smart Goal Calculation**: Adjusts daily goal based on temperature
- **Location Services**: Automatic city detection
- **Local Notifications**: Daily reminders
- **Data Persistence**: UserDefaults for local storage
- **Accessibility**: Full VoiceOver support
- **Modern UI**: Clean, blue-themed design with animations

### 🔧 Technical Highlights

#### **Clean Architecture**
- **MVVM Pattern**: Clear separation between data, business logic, and UI
- **Dependency Injection**: Environment objects for shared state
- **Single Responsibility**: Each class has one clear purpose
- **Protocol-Oriented**: Extensible and testable design

#### **SwiftUI Best Practices**
- **@MainActor**: Ensures UI updates on main thread
- **Environment Objects**: Proper state management
- **Composable Views**: Reusable components
- **Accessibility**: Full VoiceOver and Dynamic Type support

#### **Performance Optimizations**
- **LazyVStack**: Efficient list rendering
- **Proper Memory Management**: Weak references and cleanup
- **Optimized Animations**: Smooth, performant transitions

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 18.5+
- Swift 5.9+

### Installation
1. Clone the repository
2. Open `Drinkly.xcodeproj` in Xcode
3. Select your target device/simulator
4. Build and run (⌘+R)

### Configuration
- **Location Permission**: Required for city detection
- **Notification Permission**: Optional for daily reminders
- **Info.plist**: Configured with proper usage descriptions

## 📱 User Experience

### Main Screen
- **Progress Circle**: Visual representation of daily goal progress
- **Quick Add**: One-tap water intake logging
- **Today's Log**: Chronological list of water intake
- **Location Display**: Shows current city
- **Motivation**: Daily hydration tips

### Settings
- **Daily Goal**: Adjust target water intake (1.0L - 5.0L)
- **Smart Goal**: Weather-based automatic adjustment
- **Notifications**: Configure daily reminders
- **Statistics**: View today's progress
- **Reset**: Clear today's data

## 🛠️ Development

### Adding New Features
1. **Models**: Add data models in `Models/`
2. **Services**: Add business logic in `Services/`
3. **Views**: Create UI components in `Views/`
4. **Extensions**: Add utilities in `Extensions/`

### Code Style
- **Documentation**: All public methods documented
- **Naming**: Clear, descriptive names
- **Organization**: MARK comments for sections
- **Constants**: Centralized in `Constants.swift`

### Testing
- **Unit Tests**: Business logic in `DrinklyTests/`
- **UI Tests**: User interactions in `DrinklyUITests/`
- **Accessibility**: VoiceOver testing included

## 🔄 State Management

### Environment Objects
```swift
@EnvironmentObject private var waterManager: WaterManager
@EnvironmentObject private var locationManager: LocationManager
@EnvironmentObject private var notificationManager: NotificationManager
```

### Published Properties
- **Reactive Updates**: UI automatically updates with data changes
- **Type Safety**: Strong typing throughout
- **Error Handling**: Proper error states and user feedback

## 🎨 UI/UX Design

### Design Principles
- **Consistency**: Unified color scheme and typography
- **Accessibility**: Full VoiceOver support
- **Responsiveness**: Adapts to different screen sizes
- **Animations**: Smooth, purposeful transitions

### Color Scheme
- **Primary**: Blue (#007AFF)
- **Success**: Green (#34C759)
- **Warning**: Orange (#FF9500)
- **Error**: Red (#FF3B30)

## 📊 Data Flow

```
User Action → View → ViewModel → Model → Persistence
     ↑                                    ↓
     └────────── UI Update ←──────────────┘
```

## 🔧 Configuration

### Info.plist Requirements
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Drinkly needs your location to show your city and personalize your water goal.</string>
```

### Build Settings
- **GENERATE_INFOPLIST_FILE**: NO
- **INFOPLIST_FILE**: Drinkly/Info.plist

## 🚀 Deployment

### App Store Preparation
- ✅ Proper app icons
- ✅ Privacy descriptions
- ✅ Accessibility compliance
- ✅ Error handling
- ✅ Data persistence

### Version Control
- **Git**: Proper commit messages
- **Branches**: Feature-based workflow
- **Documentation**: Updated README

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the existing code style
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **SwiftUI**: Modern declarative UI framework
- **CoreLocation**: Location services
- **UserNotifications**: Local notifications
- **Apple Human Interface Guidelines**: Design principles

---

**Drinkly** - Stay hydrated, stay healthy! 💧 