# Zoomable

A SwiftUI view modifier that provides pinch to zoom, double tap to zoom, and drag to pan functionalities.



https://github.com/ryohey/Zoomable/assets/5355966/d88a9290-ee1d-4dd9-ac2c-b1e68548d256



## Features

- Pinch to zoom
- Double tap to zoom in and out
- Drag to pan

## Installation

### Swift Package Manager

Please add the following URL in the `Package Dependencies` screen in Xcode.

```
https://github.com/ryohey/Zoomable.git
```

## Usage

To use the `Zoomable` modifier in your SwiftUI view:

```swift
import YourLibraryName

struct ContentView: View {
    var body: some View {
        Image("your-image-name")
            .zoomable()
    }
}
```

## Requirements

- iOS 16.0 or later
- SwiftUI

## Caveats

- **iOS 16**: Due to limitations with `MagnificationGesture`, during pinch-in actions, the zoom location is fixed to the top-left corner.
- **iOS 17 and later**: This issue has been addressed and improved with the introduction of `MagnifyGesture`.

## Contribution

Contributions are welcome! Please open an issue or submit a pull request.

## License

MIT License
