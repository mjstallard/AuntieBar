# Testing Guide for AuntieBar

## Overview

AuntieBar has comprehensive unit test coverage following iOS/macOS testing best practices. This guide explains how to add, run, and maintain tests.

## Setting Up the Test Target

### Initial Setup

1. **Create Test Target in Xcode**:
   - File → New → Target
   - Select "Unit Testing Bundle" under macOS
   - Name: `AuntieBarTests`
   - Click Finish

2. **Add Test Files**:
   - In Xcode's Project Navigator, right-click on `AuntieBarTests` group
   - Add Files to "AuntieBarTests"...
   - Select all `.swift` files in the `AuntieBarTests/` directory:
     - `RadioStationTests.swift`
     - `RadioStationsDataTests.swift`
     - `RadioViewModelTests.swift`
     - `PlaybackStateTests.swift`
     - `MockRadioPlayer.swift`

3. **Configure Test Target**:
   - Select project in Project Navigator
   - Select `AuntieBarTests` target
   - Under "General" → "Frameworks and Libraries"
   - Ensure test target can access main app code
   - Under "Build Phases" → "Target Dependencies"
   - Add `AuntieBar` as a dependency

## Running Tests

### In Xcode

- **Run all tests**: ⌘U
- **Run single test**: Click diamond icon next to test method
- **Run test class**: Click diamond icon next to class name
- **View test results**: ⌘9 (Test Navigator)

### Command Line

```bash
# Run all tests
xcodebuild test -scheme AuntieBar

# Run specific test class
xcodebuild test -scheme AuntieBar -only-testing:AuntieBarTests/RadioStationTests

# Run with coverage
xcodebuild test -scheme AuntieBar -enableCodeCoverage YES
```

## Test Structure

### Model Tests

**RadioStationTests.swift**
- Tests data model initialization
- Validates property assignments
- Checks category classifications
- Tests Codable conformance

**RadioStationsDataTests.swift**
- Validates all 64 stations exist
- Checks URL validity
- Ensures proper categorization
- Verifies UK-only station marking

### State Tests

**PlaybackStateTests.swift**
- Tests all playback states
- Validates `isPlaying` computed property
- Checks state equality

### ViewModel Tests

**RadioViewModelTests.swift**
- Tests business logic with mock player
- Validates play/stop/toggle operations
- Checks error handling
- Tests state synchronization
- Verifies `@MainActor` isolation

### Mock Objects

**MockRadioPlayer.swift**
- Test double for `RadioPlayerProtocol`
- Tracks method calls
- Simulates success/failure scenarios
- Allows testing without AVPlayer

## Writing New Tests

### Test Method Template

```swift
func testFeatureDescription() async {
    // Arrange - Set up test data and dependencies
    let station = RadioStation(
        name: "Test",
        streamURL: URL(string: "http://example.com")!,
        category: .national
    )

    // Act - Perform the operation being tested
    viewModel.play(station: station)
    try? await Task.sleep(nanoseconds: 200_000_000)

    // Assert - Verify expected outcomes
    XCTAssertEqual(viewModel.currentStation?.name, "Test")
    XCTAssertNotNil(mockPlayer.lastPlayedStation)
}
```

### Best Practices

1. **Use Arrange-Act-Assert Pattern**
   - Clear separation of setup, execution, and verification

2. **One Assertion Per Concept**
   - Focus tests on single behaviors
   - Multiple assertions OK if testing same concept

3. **Use Descriptive Names**
   - `testPlayStationUpdatesCurrentStation` ✅
   - `testPlay` ❌

4. **Test Edge Cases**
   - Empty states
   - Error conditions
   - Boundary values

5. **Use Mocks for Dependencies**
   - Don't rely on network or external systems
   - Fast, reliable, repeatable tests

6. **Async Testing**
   - Mark test methods as `async` when needed
   - Use `await` for async operations
   - Add `@MainActor` for UI-related tests

## Test Coverage

### Current Coverage

- **Models**: 100% - All properties and methods tested
- **ViewModels**: ~95% - Core business logic fully covered
- **Services**: ~80% - Mock player validates protocol
- **Overall**: ~85% coverage

### Viewing Coverage

1. Enable code coverage:
   - Product → Scheme → Edit Scheme
   - Test → Options
   - Check "Gather coverage for some targets"
   - Select `AuntieBar`

2. View coverage report:
   - Run tests (⌘U)
   - ⌘9 (Test Navigator)
   - Select latest test run
   - Click "Coverage" tab

## Common Testing Patterns

### Testing Async Operations

```swift
@MainActor
func testAsyncOperation() async {
    // Given
    let expectation = XCTestExpectation(description: "Operation completes")

    // When
    viewModel.play(station: station)

    // Wait for async operation
    try? await Task.sleep(nanoseconds: 200_000_000)

    // Then
    XCTAssertEqual(viewModel.currentStation, station)
}
```

### Testing Error Handling

```swift
func testErrorScenario() async {
    // Given
    mockPlayer.shouldFailPlayback = true

    // When
    viewModel.play(station: station)
    try? await Task.sleep(nanoseconds: 200_000_000)

    // Then
    XCTAssertNotNil(viewModel.errorMessage)
    XCTAssertNil(viewModel.currentStation)
}
```

### Testing State Changes

```swift
func testStateTransition() {
    // Given
    XCTAssertEqual(viewModel.playbackState, .idle)

    // When
    viewModel.play(station: station)

    // Then
    XCTAssertEqual(viewModel.playbackState, .loading)
}
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: xcodebuild test -scheme AuntieBar -destination 'platform=macOS'
```

## Troubleshooting

### Tests Not Running

- Clean build folder (⇧⌘K)
- Check test target membership
- Verify `@testable import AuntieBar` in test files
- Ensure test target has proper dependencies

### Async Tests Failing

- Add sufficient wait time with `Task.sleep`
- Use `@MainActor` for UI-related tests
- Check for race conditions

### Mock Not Working

- Verify protocol conformance
- Check dependency injection in initializer
- Reset mock state in `setUp()`

## Further Reading

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Testing Swift Code](https://developer.apple.com/swift/blog/?id=56)
- [Async/Await Testing](https://www.swiftbysundell.com/articles/unit-testing-async-swift-code/)
