# AuntieBar Architecture

## Overview

AuntieBar is a macOS menu bar application for streaming BBC Radio stations. It follows modern Swift best practices with MVVM architecture, protocol-oriented design, and comprehensive testing.

## Architecture Pattern: MVVM

### Models (`Models/`)
- **RadioStation.swift**: Core data model representing a BBC radio station
  - `RadioStation`: Codable struct with station metadata
  - `RadioStationCategory`: Enum for categorizing stations (National, Nations & Regions, Regional)

- **RadioStationsData.swift**: Central data source containing all 64 BBC Radio stations
  - Organized by category
  - Provides helper methods for filtering and sorting

### Views (`Views/`)
- **MenuBarView.swift**: Primary UI shown in the menu bar dropdown
  - Search functionality for stations
  - Categorized station list with sections
  - Playback controls and status display
  - Built with SwiftUI and `@Bindable` property wrapper

- **MainView.swift**: Optional window view for app information
  - Shows current playback status
  - Displays station information

### ViewModels (`ViewModels/`)
- **RadioViewModel.swift**: Business logic layer using `@Observable` macro
  - Manages playback state
  - Handles user interactions
  - Provides reactive UI updates via Observation framework
  - Testable through protocol injection

### Services (`RadioPlayer.swift`)
- **RadioPlayer**: AVPlayer wrapper implementing `RadioPlayerProtocol`
  - Handles HLS stream playback
  - State management with Combine publishers
  - Error handling and recovery
  - KVO observation for player status

### Protocols (`Protocols/`)
- **RadioPlayerProtocol.swift**: Abstraction for radio playback
  - Enables dependency injection for testing
  - Defines `PlaybackState` enum for state management
  - Defines `RadioPlayerError` for comprehensive error handling

## Key Design Patterns

### 1. Protocol-Oriented Programming
All services implement protocols to enable:
- Dependency injection
- Unit testing with mocks
- Loose coupling between components

### 2. Observation Framework
Using Swift's modern `@Observable` macro for:
- Automatic UI updates
- Type-safe property observation
- Cleaner syntax than Combine's `@Published`

### 3. Async/Await
Modern concurrency for:
- Non-blocking playback operations
- Clean error handling
- Main actor isolation for UI updates

### 4. Single Responsibility
Each component has a clear, focused purpose:
- Models: Data structures only
- ViewModels: Business logic
- Views: UI presentation
- Services: External integrations

### 5. Error Handling
Comprehensive error handling with:
- Custom error types (`RadioPlayerError`)
- Descriptive error messages
- User-facing error display
- Graceful degradation

## Testing Strategy

### Unit Tests (`AuntieBarTests/`)
- **RadioStationTests**: Model validation
- **RadioStationsDataTests**: Data integrity checks
- **PlaybackStateTests**: State machine logic
- **RadioViewModelTests**: Business logic testing with mocks
- **MockRadioPlayer**: Test double for player protocol

### Testing Best Practices
1. **Arrange-Act-Assert** pattern in all tests
2. **Mocks over real implementations** for isolation
3. **MainActor testing** for async ViewModel tests
4. **Comprehensive coverage** of edge cases and error states

## Data Flow

```
User Interaction (View)
    ↓
ViewModel (Business Logic)
    ↓
RadioPlayer (Service)
    ↓
AVPlayer (System Framework)
    ↓
State Updates via Observation
    ↓
View Refresh
```

## File Organization

```
AuntieBar/
├── AuntieBarApp.swift           # App entry point
├── Models/
│   ├── RadioStation.swift       # Data models
│   └── RadioStationsData.swift  # Station database
├── ViewModels/
│   └── RadioViewModel.swift     # Business logic
├── Views/
│   ├── MenuBarView.swift        # Menu bar UI
│   └── MainView.swift           # Window UI
├── Protocols/
│   └── RadioPlayerProtocol.swift # Service contracts
├── RadioPlayer.swift            # Playback service
└── AuntieWindowController.swift # Window management

AuntieBarTests/
├── RadioStationTests.swift
├── RadioStationsDataTests.swift
├── RadioViewModelTests.swift
├── PlaybackStateTests.swift
└── MockRadioPlayer.swift
```

## Dependencies

- **SwiftUI**: Modern declarative UI framework
- **AVFoundation**: Audio playback via `AVPlayer`
- **Combine**: Reactive state management
- **Observation**: Swift 5.9+ property observation
- **XCTest**: Unit testing framework

## Best Practices Implemented

1. **No Force Unwrapping**: All optionals handled safely
2. **Access Control**: Proper use of `private`, `fileprivate`, `internal`, `public`
3. **Value Types**: Structs for models, classes for reference semantics
4. **Immutability**: Use of `let` over `var` where possible
5. **Weak References**: Prevent retain cycles in closures
6. **Error Propagation**: Use of `throws` for error handling
7. **Documentation**: Clear comments on complex logic
8. **Type Safety**: Strong typing throughout
9. **Testability**: Protocol-based design enables mocking
10. **Separation of Concerns**: Clear boundaries between layers

## Future Enhancements

Potential improvements to consider:
- Persistence layer for favorites
- Now playing metadata display
- Volume control
- Sleep timer
- Dark mode customization
- Keyboard shortcuts
- Stream quality selection
