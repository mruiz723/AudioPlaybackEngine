import Foundation
import AVFoundation

public protocol AudioPlaybackDelegate: AnyObject {
    func playbackDidUpdateProgress(_ manager: AudioPlaybackEngine, current: Double, duration: Double)
    func playbackDidChangeState(_ manager: AudioPlaybackEngine, isPlaying: Bool)
    func playbackDidUpdateFavorites(_ manager: AudioPlaybackEngine, favorites: Set<String>)
    func playbackDidUpdatePins(_ manager: AudioPlaybackEngine, pins: [Double])
}

@MainActor
public class AudioPlaybackEngine: NSObject {
    public static let shared = AudioPlaybackEngine()
    public weak var favoritesProvider: FavoritesProvider?
    private var player: AVPlayer?
    nonisolated(unsafe) private var timeObserverToken: Any?
    public weak var delegate: AudioPlaybackDelegate?
    
    public private(set) var favoriteEpisodes: Set<String> = []
    public private(set) var pinnedTimestamps: [Double] = []
    public var episodeID: String?
    
    // Core playback
    public func configure(url: URL, episodeID: String) {
        player = AVPlayer(url: url)
        self.episodeID = episodeID
        addObservers()
        loadFavorites()
        loadPins()
    }
    public func play() {
        player?.play()
        delegate?.playbackDidChangeState(self, isPlaying: true)
    }
    public func pause() {
        player?.pause()
        delegate?.playbackDidChangeState(self, isPlaying: false)
    }
    public func seek(to seconds: Double) {
        let cmTime = CMTime(seconds: seconds, preferredTimescale: 1)
        player?.seek(to: cmTime)
    }
    public func setRate(_ rate: Float) {
        player?.rate = rate
    }
    public func getDuration() -> Double {
        player?.currentItem?.asset.duration.seconds ?? 0
    }
    
    // --- Skip logic ---
    public func skipForward(by seconds: Double = 15) {
        let current = player?.currentTime().seconds ?? 0
        seek(to: min(current + seconds, getDuration()))
    }
    public func skipBackward(by seconds: Double = 15) {
        let current = player?.currentTime().seconds ?? 0
        seek(to: max(current - seconds, 0))
    }
    
    // --- Favorites logic (API) ---
    
    public func isFavorite() -> Bool {
        guard let id = episodeID else { return false }
        return favoriteEpisodes.contains(id)
    }
    
    public func loadFavorites() {
        favoritesProvider?.fetchFavorites { [weak self] favorites in
            guard let self = self else { return }
            self.favoriteEpisodes = favorites
            self.delegate?.playbackDidUpdateFavorites(self, favorites: favorites)
        }
    }
    
    public func toggleFavorite() {
        guard let id = episodeID else { return }
        let add = !favoriteEpisodes.contains(id)
        if add {
            favoritesProvider?.addFavorite(id: id) { [weak self] in
                guard let self = self else { return }
                self.favoriteEpisodes.insert(id)
                self.delegate?.playbackDidUpdateFavorites(self, favorites: self.favoriteEpisodes)
            }
        } else {
            favoritesProvider?.removeFavorite(id: id) { [weak self] in
                guard let self = self else { return }
                self.favoriteEpisodes.remove(id)
                self.delegate?.playbackDidUpdateFavorites(self, favorites: self.favoriteEpisodes)
            }
        }
    }
    
    // --- Local Pins ---
    public func loadPins() {
        guard let id = episodeID else { return }
        pinnedTimestamps = UserDefaults.standard.array(forKey: "pins_\(id)") as? [Double] ?? []
        delegate?.playbackDidUpdatePins(self, pins: pinnedTimestamps)
    }
    
    public func pinCurrentTimestamp() {
        guard let id = episodeID else { return }
        let current = player?.currentTime().seconds ?? 0
        pinnedTimestamps.append(current)
        UserDefaults.standard.set(pinnedTimestamps, forKey: "pins_\(id)")
        delegate?.playbackDidUpdatePins(self, pins: pinnedTimestamps)
    }
    
    public func getPinnedTimestamps() -> [Double] { pinnedTimestamps }
    
    private func addObservers() {
        guard let player = player else { return }
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 1),
            queue: .main
        ) { [weak self] time in
            guard let self = self else { return }
            Task { @MainActor in
                guard let duration = self.player?.currentItem?.duration.seconds,
                      duration > 0 else { return }
                self.delegate?.playbackDidUpdateProgress(self, current: time.seconds, duration: duration)
            }
        }
    }
    
    deinit {
        if let token = timeObserverToken { player?.removeTimeObserver(token) }
    }
}
