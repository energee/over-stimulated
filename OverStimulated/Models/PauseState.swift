import Foundation

/// Represents the different states of cursor movement pausing
enum PauseState {
    /// Normal movement state, not paused
    case notPausing
    /// Currently slowing down before pausing
    case slowingDown(startTime: TimeInterval)
    /// Fully paused until the specified end time
    case paused(endTime: TimeInterval)
    
    /// Whether the cursor is currently in a fully paused state
    var isPaused: Bool {
        if case .paused = self {
            return true
        }
        return false
    }
    
    /// Whether the cursor is currently slowing down
    var isSlowingDown: Bool {
        if case .slowingDown = self {
            return true
        }
        return false
    }
} 