import SwiftUI
import AppKit

struct CursorConfig {
    static let baseSpeed: CGFloat = 150
    static let maxEdgeMargin: CGFloat = 200
    static let updateFrequency: TimeInterval = 1.0/60.0
    
    static let maxSpeedVariation: CGFloat = 500
    static let directionChangeBaseChance: Double = 0.02
    static let directionChangeTimeFactor: Double = 0.5
    
    static let smoothingFactor: CGFloat = 0.15
    static let minSpeedMultiplier: CGFloat = 0.3
    static let maxSpeedMultiplier: CGFloat = 2.5
    static let speedChangeChance: Double = 0.03
    
    static let pauseChance: Double = 0.0009
    static let minPauseDuration: TimeInterval = 5.1
    static let maxPauseDuration: TimeInterval = 15.432
    static let pauseSlowingDuration: TimeInterval = 2
    
    static let focusChangeChance: Double = 0.001
    
    static let noiseFrequencyX: Double = 0.02
    static let noiseFrequencyY: Double = 0.02
    static let noiseAmplitudeX: CGFloat = 40.0
    static let noiseAmplitudeY: CGFloat = 40.0
    
    static let microJitterAmplitude: CGFloat = 1.5
    static let microJitterFrequency: CGFloat = 1.1
    
    // Maximum movement per frame in each axis to avoid very large jumps
    // Keep it higher than before to allow more fluid movement.
    static let maxDeltaPerFrame: CGFloat = 8.0
    
    // How fast we can turn angle per update (in radians per update)
    static let maxTurnRate: CGFloat = 0.05
}

enum PauseState {
    case notPausing
    case slowingDown(startTime: TimeInterval)
    case paused(endTime: TimeInterval)
}

class CursorController: ObservableObject {
    @Published private(set) var position: CGPoint = .zero
    
    private var currentVelocity: CGPoint = .zero
    private var targetVelocity: CGPoint = .zero
    
    // Instead of a simple boolean, use a heading angle
    // 0 radians = moving to the right, PI/2 = up, etc.
    private var headingAngle: CGFloat = 0.0
    
    private var movementTimer: Timer?
    private var keyMonitor: Any?
    
    private var currentSpeed: CGFloat = CursorConfig.baseSpeed
    private var speedMultiplier: CGFloat = 1.0
    
    private var leftMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    private var rightMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    private var topMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    private var bottomMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    
    private var lastDirectionChangeTime: TimeInterval = 0
    
    private var pauseState: PauseState = .notPausing
    private var desiredPauseEndTime: TimeInterval = 0
    
    private var focusPoint: CGPoint?
    private var lastFocusChangeTime: TimeInterval = 0
    
    private var time: Double = 0
    
    init() {
        setupInitialPosition()
        setupKeyboardMonitoring()
        startMovement()
    }
    
    deinit {
        cleanup()
    }
    
    private func setupInitialPosition() {
        guard let screen = NSScreen.main else { return }
        position = CGPoint(x: screen.frame.width / 2, y: screen.frame.height / 2)
        CGWarpMouseCursorPosition(position)
        randomizeMargins()
        lastDirectionChangeTime = Date().timeIntervalSinceReferenceDate
        
        // Initial heading angle random
        headingAngle = CGFloat.random(in: 0...(2*CGFloat.pi))
    }
    
    private func setupKeyboardMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyPress(event)
            return event
        }
    }
    
    private func handleKeyPress(_ event: NSEvent) {
        if event.charactersIgnoringModifiers == "q" {
            cleanup()
            NSApplication.shared.terminate(nil)
        }
    }
    
    private func startMovement() {
        movementTimer = Timer.scheduledTimer(withTimeInterval: CursorConfig.updateFrequency,
                                             repeats: true) { [weak self] _ in
            self?.updatePosition()
        }
        RunLoop.current.add(movementTimer!, forMode: .common)
    }
    
    private func randomizeMargins() {
        leftMargin = CGFloat.random(in: 0...CursorConfig.maxEdgeMargin)
        rightMargin = CGFloat.random(in: 0...CursorConfig.maxEdgeMargin)
        topMargin = CGFloat.random(in: 0...CursorConfig.maxEdgeMargin)
        bottomMargin = CGFloat.random(in: 0...CursorConfig.maxEdgeMargin)
    }
    
    private func checkForRandomPause() {
        guard case .notPausing = pauseState else { return }
        
        if Double.random(in: 0...1) < CursorConfig.pauseChance {
            let pauseDuration = TimeInterval.random(in: CursorConfig.minPauseDuration...CursorConfig.maxPauseDuration)
            let now = Date().timeIntervalSinceReferenceDate
            pauseState = .slowingDown(startTime: now)
            desiredPauseEndTime = now + CursorConfig.pauseSlowingDuration + pauseDuration
            print("Starting to slow down for pause, then pausing for \(Int(pauseDuration))s")
        }
    }
    
    private func updatePauseState() {
        let currentTime = Date().timeIntervalSinceReferenceDate
        switch pauseState {
        case .notPausing:
            break
        case .slowingDown(let startTime):
            let elapsed = currentTime - startTime
            if elapsed >= CursorConfig.pauseSlowingDuration {
                // Fully paused
                let endTime = desiredPauseEndTime
                pauseState = .paused(endTime: endTime)
                print("Now fully paused until \(endTime - currentTime) seconds have passed")
            }
        case .paused(let endTime):
            if currentTime >= endTime {
                // Resume
                pauseState = .notPausing
                print("Resuming movement")
                speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
                // Slightly adjust heading angle on resume for variety
                headingAngle += CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
                randomizeMargins()
            }
        }
    }
    
    private func updateSpeedMultiplier() {
        if Double.random(in: 0...1) < CursorConfig.speedChangeChance {
            speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
        } else {
            let variation = CGFloat.random(in: -0.05...0.05)
            speedMultiplier = min(max(speedMultiplier + variation, CursorConfig.minSpeedMultiplier), CursorConfig.maxSpeedMultiplier)
        }
    }
    
    private func shouldChangeDirection() -> Bool {
        let currentTime = Date().timeIntervalSinceReferenceDate
        let timeSinceLastChange = currentTime - lastDirectionChangeTime
        let chance = CursorConfig.directionChangeBaseChance + (timeSinceLastChange * CursorConfig.directionChangeTimeFactor * 0.01)
        return Double.random(in: 0...1) < chance
    }
    
    private func maybeChangeFocusPoint(screen: NSScreen) {
        let currentTime = Date().timeIntervalSinceReferenceDate
        if focusPoint == nil || Double.random(in: 0...1) < CursorConfig.focusChangeChance || currentTime - lastFocusChangeTime > 30 {
            let fx = CGFloat.random(in: screen.frame.width*0.25...screen.frame.width*0.75)
            let fy = CGFloat.random(in: screen.frame.height*0.25...screen.frame.height*0.75)
            focusPoint = CGPoint(x: fx, y: fy)
            lastFocusChangeTime = currentTime
            print("New focus point at: \(focusPoint!)")
        }
    }
    
    private func noiseValue(_ t: Double, freq: Double) -> Double {
        return sin(t * freq) * cos(t * freq * 1.3)
    }
    
    private func humanLikeYDrift(_ x: CGFloat) -> CGFloat {
        let nx = noiseValue(time, freq: CursorConfig.noiseFrequencyY)
        return CGFloat(nx) * CursorConfig.noiseAmplitudeY
    }
    
    private func humanLikeXNoise() -> CGFloat {
        let nx = noiseValue(time, freq: CursorConfig.noiseFrequencyX)
        return CGFloat(nx) * CursorConfig.noiseAmplitudeX
    }
    
    private func applyHeadingChanges() {
        // If conditions suggest a direction change, rotate the heading angle slightly
        if shouldChangeDirection() {
            lastDirectionChangeTime = Date().timeIntervalSinceReferenceDate
            // Instead of toggling a direction, nudge the angle
            let angleChange = CGFloat.random(in: -CGFloat.pi/2...CGFloat.pi/2) * 0.2
            headingAngle += angleChange
        }
        
        // Slight random drift in heading angle to create curves
        let smallAngleDrift = CGFloat.random(in: -0.01...0.01)
        headingAngle += smallAngleDrift
        
        // If we have a focus point, gently steer towards it
        if let focus = focusPoint {
            let dx = focus.x - position.x
            let dy = focus.y - position.y
            let angleToFocus = atan2(dy, dx)
            // Steer heading angle a bit towards angleToFocus
            let angleDiff = angleToFocus - headingAngle
            let wrappedAngleDiff = atan2(sin(angleDiff), cos(angleDiff)) // normalize angle difference
            let steer = max(min(wrappedAngleDiff, CursorConfig.maxTurnRate), -CursorConfig.maxTurnRate)
            headingAngle += steer * 0.5 // steer half as strongly to avoid too sharp turns
        }
        
        // Normalize heading angle
        while headingAngle < 0 {
            headingAngle += 2*CGFloat.pi
        }
        while headingAngle > 2*CGFloat.pi {
            headingAngle -= 2*CGFloat.pi
        }
    }
    
    private func updatePosition() {
        time += CursorConfig.updateFrequency
        
        checkForRandomPause()
        updatePauseState()
        
        // If fully paused, do not move
        if case .paused = pauseState {
            return
        }
        
        guard let screen = NSScreen.main else { return }
        
        updateSpeedMultiplier()
        maybeChangeFocusPoint(screen: screen)
        
        // Adjust heading angle for more organic curves
        applyHeadingChanges()
        
        currentSpeed = CursorConfig.baseSpeed * speedMultiplier +
            CGFloat.random(in: -CursorConfig.maxSpeedVariation...CursorConfig.maxSpeedVariation) * 0.1
        
        // Base target velocity based on heading angle
        targetVelocity.x = cos(headingAngle) * currentSpeed * CGFloat(CursorConfig.updateFrequency)
        targetVelocity.y = sin(headingAngle) * currentSpeed * CGFloat(CursorConfig.updateFrequency)
        
        // Add human-like drift from noise
        let xNoise = humanLikeXNoise() * 0.1
        let yDrift = humanLikeYDrift(position.x) * 0.1 * CGFloat(CursorConfig.updateFrequency)
        
        targetVelocity.x += xNoise
        targetVelocity.y += yDrift
        
        // Smooth velocities
        currentVelocity.x += (targetVelocity.x - currentVelocity.x) * CursorConfig.smoothingFactor
        currentVelocity.y += (targetVelocity.y - currentVelocity.y) * CursorConfig.smoothingFactor
        
        if case .notPausing = pauseState {
            // Micro jitter
            let microJitterX = CGFloat.random(in: -CursorConfig.microJitterAmplitude...CursorConfig.microJitterAmplitude) * CursorConfig.microJitterFrequency
            let microJitterY = CGFloat.random(in: -CursorConfig.microJitterAmplitude...CursorConfig.microJitterAmplitude) * CursorConfig.microJitterFrequency
            currentVelocity.x += microJitterX
            currentVelocity.y += microJitterY
        }
        
        // If slowing down, reduce velocity magnitude
        var moveFactor: CGFloat = 1.0
        if case .slowingDown(let startTime) = pauseState {
            let elapsed = Date().timeIntervalSinceReferenceDate - startTime
            let fraction = min(elapsed / CursorConfig.pauseSlowingDuration, 1.0)
            moveFactor = 1.0 - CGFloat(fraction)
        }
        
        var dx = currentVelocity.x * moveFactor
        var dy = currentVelocity.y * moveFactor
        
        // Clamp per-frame movement to prevent large jumps
        dx = max(min(dx, CursorConfig.maxDeltaPerFrame), -CursorConfig.maxDeltaPerFrame)
        dy = max(min(dy, CursorConfig.maxDeltaPerFrame), -CursorConfig.maxDeltaPerFrame)
        
        var newPosition = position
        newPosition.x += dx
        newPosition.y += dy
        
        // Check boundaries
        if newPosition.x > screen.frame.width - rightMargin {
            newPosition.x = screen.frame.width - rightMargin
            // Nudge angle away from the edge
            headingAngle += CGFloat.pi * CGFloat.random(in: 0.2...0.8)
            randomizeMargins()
            speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
        } else if newPosition.x < leftMargin {
            newPosition.x = leftMargin
            headingAngle += CGFloat.pi * CGFloat.random(in: 0.2...0.8)
            randomizeMargins()
            speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
        }
        
        if newPosition.y < bottomMargin {
            newPosition.y = bottomMargin
            headingAngle += CGFloat.pi * CGFloat.random(in: 0.2...0.8)
            randomizeMargins()
            speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
        } else if newPosition.y > screen.frame.height - topMargin {
            newPosition.y = screen.frame.height - topMargin
            headingAngle += CGFloat.pi * CGFloat.random(in: 0.2...0.8)
            randomizeMargins()
            speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
        }
        
        position = newPosition
        CGWarpMouseCursorPosition(position)
    }
    
    private func cleanup() {
        movementTimer?.invalidate()
        movementTimer = nil
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

struct ContentView: View {
    @StateObject private var controller = CursorController()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Cursor Position")
                .font(.title)
            
            Text("X: \(Int(controller.position.x)), Y: \(Int(controller.position.y))")
        }
        .padding()
    }
}
