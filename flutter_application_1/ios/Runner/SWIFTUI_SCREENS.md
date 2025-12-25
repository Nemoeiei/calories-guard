# SwiftUI Screens

This document lists the SwiftUI screens that have been added to the iOS project.

## Files Added

### 1. GoalSelectionScreen.swift
- **Purpose**: Screen where users select their fitness goal
- **Features**:
  - Three goal options (Lose Weight, Maintain Weight, Build Muscle)
  - Visual feedback with gradient backgrounds when selected
  - Navigation to GoalDetailsScreen
  - "ถัดไป" (Next) button to proceed

### 2. GoalDetailsScreen.swift
- **Purpose**: Screen to enter goal details (target weight and duration)
- **Features**:
  - Displays selected goal from previous screen
  - Two input fields:
    - Target weight (เป้าหมายนํ้าหนัก)
    - Desired duration (ระยะเวลาที่ต้องการ)
  - Fire icon visual element
  - "ถัดไป" (Next) button to proceed

## Design System

Both screens follow a consistent design:
- **Background Color**: #E8EFCF (light green/cream)
- **Primary Button Color**: #628141 (green)
- **Accent Color**: #D76A3C (orange)
- **Font**: System font with various weights
- **Navigation**: SwiftUI NavigationStack with native back gesture

## Project Integration

The files have been added to:
- `flutter_application_1/ios/Runner/`
- Registered in `project.pbxproj` for Xcode build

## How to Use

1. Open the project in Xcode
2. The files are already registered in the build system
3. Build and run the project (Cmd+R)
4. Navigate through: GoalSelectionScreen → GoalDetailsScreen

## Preview Support

Both screens include `#Preview` for Xcode canvas preview:
```swift
#Preview {
    GoalSelectionScreen()
}
```

```swift
#Preview {
    GoalDetailsScreen()
}
```
