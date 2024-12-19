import Foundation

/// Configuration values for cursor movement behavior
struct CursorConfig {
    // MARK: - Base Movement
    /// Base movement speed in points per second
    static let baseSpeed: CGFloat = 150
    /// Maximum distance from screen edges for movement boundaries
    static let maxEdgeMargin: CGFloat = 200
    /// Update frequency in seconds (60 FPS)
    static let updateFrequency: TimeInterval = 1.0/60.0
    
    // MARK: - Speed Control
    /// Maximum random speed variation
    static let maxSpeedVariation: CGFloat = 500
    /// Base chance of direction change per update
    static let directionChangeBaseChance: Double = 0.02
    /// How much time affects direction change probability
    static let directionChangeTimeFactor: Double = 0.5
    /// Smoothing factor for velocity changes (0-1)
    static let smoothingFactor: CGFloat = 0.15
    /// Minimum speed multiplier
    static let minSpeedMultiplier: CGFloat = 0.3
    /// Maximum speed multiplier
    static let maxSpeedMultiplier: CGFloat = 2.5
    /// Chance of speed change per update
    static let speedChangeChance: Double = 0.03
    
    // MARK: - Auto-Pause
    /// Chance of random pause per update
    static let pauseChance: Double = 0.0009
    /// Minimum duration for random pauses
    static let minPauseDuration: TimeInterval = 5.1
    /// Maximum duration for random pauses
    static let maxPauseDuration: TimeInterval = 15.432
    /// Duration of slowing down before pause
    static let pauseSlowingDuration: TimeInterval = 2
    
    // MARK: - Focus Points
    /// Chance of changing focus point per update
    static let focusChangeChance: Double = 0.001
    
    // MARK: - Movement Noise
    /// Frequency of X-axis noise
    static let noiseFrequencyX: Double = 0.02
    /// Frequency of Y-axis noise
    static let noiseFrequencyY: Double = 0.02
    /// Amplitude of X-axis noise
    static let noiseAmplitudeX: CGFloat = 40.0
    /// Amplitude of Y-axis noise
    static let noiseAmplitudeY: CGFloat = 40.0
    
    // MARK: - Micro Movements
    /// Amplitude of micro-jitter movement
    static let microJitterAmplitude: CGFloat = 1.5
    /// Frequency of micro-jitter movement
    static let microJitterFrequency: CGFloat = 1.1
    
    // MARK: - Movement Limits
    /// Maximum movement per frame to prevent jumps
    static let maxDeltaPerFrame: CGFloat = 8.0
    /// Maximum turn rate in radians per update
    static let maxTurnRate: CGFloat = 0.05
} 