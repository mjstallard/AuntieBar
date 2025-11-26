# AuntieBar

A modern macOS menu bar application for streaming all 64 BBC Radio stations.

This is a vibe-coded train wreck of a codebase - no warranties given, no pride taken in construction.

Stream info shamelessly stolen from [here](https://gist.github.com/bpsib/67089b959e4fa898af69fea59ad74bc3).

## Legal / Disclaimer

- Unofficial app; not affiliated with or endorsed by the BBC.
- Streams and metadata remain the property of their respective owners.
- Provided for personal use only; review BBC terms for any additional restrictions.

## Features

- 🎵 **All BBC Radio Stations**: 64 stations including national, regional, and nations programming
- 🔍 **Search**: Quickly find stations by name
- 📂 **Organized by Category**: National, Nations & Regions, and Regional stations
- 🎛️ **Simple Controls**: Play, stop, and switch stations with ease
- 🎨 **Native macOS Design**: Clean, modern SwiftUI interface
- ⚡ **High-Quality Streaming**: HLS streams at 96kbps (320kbps for UK-only stations)
- 🧪 **Fully Tested**: Comprehensive unit test coverage

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd AuntieBar
   ```

2. Open `AuntieBar.xcodeproj` in Xcode

3. Build and run (⌘R)

## Usage

1. Click the radio waves icon in your menu bar
2. Browse stations by category 
3. Click any station to start playing
4. Click "Stop" to stop playback
5. The currently playing station is indicated with a green icon

## Station Categories

### National Stations
- Radio 1, 1Xtra, 1Dance, 1 Anthems
- Radio 2, 3, 3 Unwind, 4, 4 Extra
- Radio 5 Live, 5 Live Sports Extra
- Radio 6 Music
- Asian Network
- World Service

### Nations & Regions
- Scotland: Radio Scotland FM/MW, Radio nan Gaidheal, Radio Orkney
- Wales: Radio Wales, Radio Cymru, Radio Cymru 2
- Northern Ireland: Radio Ulster, Radio Foyle

### Regional Stations (England)
40+ local BBC radio stations including London, Manchester, Bristol, Leeds, and more

## Architecture

AuntieBar follows modern Swift best practices:

- **MVVM Architecture**: Clear separation of concerns
- **Protocol-Oriented Design**: Testable, mockable components
- **Observation Framework**: Reactive UI updates with `@Observable`
- **Async/Await**: Modern concurrency for smooth playback
- **Error Handling**: Comprehensive error states and user feedback
- **Unit Tests**: Full test coverage with mock objects

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed documentation.

## Testing

Run tests in Xcode:
```bash
⌘U
```

Or via command line:
```bash
xcodebuild test -scheme AuntieBar
```

### Test Coverage

- Model tests: RadioStation, RadioStationsData
- ViewModel tests: Business logic with mock player
- State tests: PlaybackState, RadioPlayerError
- Mock implementations for testing

## Development

### Project Structure

```
AuntieBar/
├── Models/              # Data models
├── ViewModels/          # Business logic
├── Views/               # SwiftUI views
├── Protocols/           # Service protocols
└── RadioPlayer.swift    # AVPlayer wrapper

AuntieBarTests/          # Unit tests
```

### Adding the Test Target

If the test target isn't already configured:

1. In Xcode, go to **File > New > Target**
2. Select **macOS > Unit Testing Bundle**
3. Name it `AuntieBarTests`
4. Add all test files from the `AuntieBarTests/` directory
5. In test target settings, add `AuntieBar` to "Target Dependencies"
6. Run tests with ⌘U

## Building for Release

1. Set scheme to Release: **Product > Scheme > Edit Scheme > Run > Build Configuration > Release**
2. Archive: **Product > Archive**
3. Export the app

## Credits

- BBC Radio streams courtesy of BBC Sounds
- Station list from [bpsib's BBC Radio HLS gist](https://gist.github.com/bpsib/67089b959e4fa898af69fea59ad74bc3)

## License

MIT. See LICENSE.md

## Contributing

Contributions welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new features
4. Ensure all tests pass
5. Submit a pull request

## Troubleshooting

### Playback Issues

- Check your internet connection
- Some UK-only stations may not be available outside the UK
- Firewall settings may block streaming

### Building Issues

- Ensure you're using macOS 14.0+ and Xcode 15.0+
- Clean build folder: **Product > Clean Build Folder** (⇧⌘K)
- Reset package cache if using SPM dependencies

## Roadmap

Potential future features:

- [ ] Favorite stations
- [ ] Now playing metadata display
- [ ] Sleep timer
- [ ] Keyboard shortcuts
- [ ] Stream quality selection
- [ ] Dark mode customization
- [ ] macOS widget

## Contact

[Add your contact information or leave this section out]
