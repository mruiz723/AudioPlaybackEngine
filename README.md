# AudioPlaybackEngine

A modular Swift framework for podcast and audio playback, featuring favorites management and timestamp pinning.

## Features

- Play, pause, seek, and change playback rate
- Skip forward and backward by 15 seconds
- Manage favorites through an API
- Pin timestamps locally
- Delegate callbacks for UI updates and integration

## Installation

Add AudioPlaybackEngine to your Xcode project using Swift Package Manager:

1. In Xcode, go to **File > Add Packages...**
2. Enter the repository URL: `https://github.com/mruiz723/AudioPlaybackEngine`
3. Select the latest version or a specific version tag.
4. Click **Add Package**

Alternatively, add the package in your `Package.swift` dependencies:

```swift
dependencies: [
.package(url: "https://github.com/mruiz723/AudioPlaybackEngine.git", from: "1.0.0")
]
```

Then import the framework where you want to use it:

import AudioPlaybackEngine


## Usage

Configure the player and use key functions:

```swift
AudioPlaybackEngine.shared.configure(url: myURL, episodeID: "ep123")
AudioPlaybackEngine.shared.skipForward()
AudioPlaybackEngine.shared.skipBackward()
AudioPlaybackEngine.shared.toggleFavorite()
AudioPlaybackEngine.shared.pinCurrentTimestamp()
```

### Inject the Provider Into the Manager

To sync favorites correctly, assign your custom provider implementation to the shared instance during your app initialization or before using favorites functionality:

```swift
AudioPlaybackEngine.shared.favoritesProvider = MyFavoritesService()
```

### Favorites Management Example

To manage favorites, implement the FavoritesProvider protocol. Below is an example class using API/network logic to fetch, add, and remove favorites:

```swift
class MyFavoritesService: FavoritesProvider {
    func fetchFavorites(completion: @escaping (Set<String>) -> Void) {
        // Your API/network/coredata logic, call completion with results
    }
    func addFavorite(id: String, completion: (() -> Void)?) {
        // Your API POST logic then call completion
    }
    func removeFavorite(id: String, completion: (() -> Void)?) {
        // Your API DELETE logic then call completion
    }
}
```

Implementing this provider allows AudioPlaybackEngine to sync favorites through your backend or local storage.

### Timestamp Pinning

You can pin the current playback position locally for quick access later. This allows users to mark important moments in the episode.

pinCurrentTimestamp() saves the current playback time locally.

loadPins() loads saved pinned timestamps for the current episode.

getPinnedTimestamps() returns an array of pinned timestamps as Double values representing seconds.

Use pinning like this:

```swift
// Pin current position
AudioPlaybackEngine.shared.pinCurrentTimestamp()

// Retrieve pinned timestamps
let pins = AudioPlaybackEngine.shared.getPinnedTimestamps()

```

## Configuration

- Provide a valid audio stream URL and episodeID for favorites management.
- Implement the delegate `AudioPlaybackEngineDelegate` for playback updates and UI integration.

## Requirements

- Swift 5.0 or later
- iOS 15.0 or later

## License

Distributed under the MIT License. See `LICENSE` for details.

---
Developed by Marlon Ruiz - mruiz723@gmail..com
