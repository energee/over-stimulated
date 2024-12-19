import SwiftUI
import AppKit

/// Controls the automated cursor movement with human-like behavior
final class CursorController: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var position: CGPoint = .zero
    @Published private(set) var isPaused: Bool = false
    
    // MARK: - Movement Properties
    private var currentVelocity: CGPoint = .zero
    private var targetVelocity: CGPoint = .zero
    private var headingAngle: CGFloat = 0.0
    private var currentSpeed: CGFloat = CursorConfig.baseSpeed
    private var speedMultiplier: CGFloat = 1.0
    private var time: Double = 0
    
    // MARK: - Screen Boundaries
    private var leftMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    private var rightMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    private var topMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    private var bottomMargin: CGFloat = CursorConfig.maxEdgeMargin / 2
    
    // MARK: - State Tracking
    private var lastDirectionChangeTime: TimeInterval = 0
    private var pauseState: PauseState = .notPausing {
        didSet {
            isPaused = pauseState.isPaused
        }
    }
    private var desiredPauseEndTime: TimeInterval = 0
    
    // MARK: - Focus Point
    private var focusPoint: CGPoint?
    private var lastFocusChangeTime: TimeInterval = 0
    
    // MARK: - System Resources
    private var movementTimer: Timer?
    private var keyMonitor: Any?
    
    // MARK: - Initialization
    init() {
        setupInitialPosition()
        setupKeyboardMonitoring()
        startMovement()
    }
    
    deinit {
        cleanup()
    }
    
    // MARK: - Setup
    private func setupInitialPosition() {
        guard let screen = NSScreen.main else { return }
        position = CGPoint(x: screen.frame.width / 2, y: screen.frame.height / 2)
        CGWarpMouseCursorPosition(position)
        randomizeMargins()
        lastDirectionChangeTime = Date().timeIntervalSinceReferenceDate
        headingAngle = CGFloat.random(in: 0...(2*CGFloat.pi))
    }
    
    private func setupKeyboardMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyPress(event)
            return event
        }
    }
    
    private func startMovement() {
        movementTimer = Timer.scheduledTimer(
            withTimeInterval: CursorConfig.updateFrequency,
            repeats: true
        ) { [weak self] _ in
            self?.updatePosition()
        }
        RunLoop.current.add(movementTimer!, forMode: .common)
    }
    
    // MARK: - Public Interface
    func togglePause() {
        if pauseState.isPaused {
            resumeMovement()
        } else if case .notPausing = pauseState {
            pauseIndefinitely()
        }
    }
    
    // MARK: - Private Methods
    private func handleKeyPress(_ event: NSEvent) {
        switch event.charactersIgnoringModifiers {
        case "q":
            cleanup()
            NSApplication.shared.terminate(nil)
        case "p":
            togglePause()
        default:
            break
        }
    }
    
    private func pauseIndefinitely() {
        // Immediately stop movement by setting velocity to zero
        currentVelocity = .zero
        targetVelocity = .zero
        pauseState = .paused(endTime: .infinity)
        print("Manual pause activated - immediate stop")
    }
    
    private func resumeMovement() {
        pauseState = .notPausing
        print("Resuming movement")
        speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
        headingAngle += CGFloat.random(in: -CGFloat.pi/4...CGFloat.pi/4)
        randomizeMargins()
    }
    
    private func cleanup() {
        movementTimer?.invalidate()
        movementTimer = nil
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
    
    // MARK: - Movement Updates
    private func updatePosition() {
        time += CursorConfig.updateFrequency
        
        checkForRandomPause()
        updatePauseState()
        
        guard !pauseState.isPaused,
              let screen = NSScreen.main else { return }
        
        updateMovementParameters(screen: screen)
        applyMovement(screen: screen)
    }
    
    private func updateMovementParameters(screen: NSScreen) {
        updateSpeedMultiplier()
        maybeChangeFocusPoint(screen: screen)
        applyHeadingChanges()
        
        currentSpeed = CursorConfig.baseSpeed * speedMultiplier +
            CGFloat.random(in: -CursorConfig.maxSpeedVariation...CursorConfig.maxSpeedVariation) * 0.1
        
        updateVelocity()
    }
    
    private func updateVelocity() {
        // Base velocity from heading
        targetVelocity.x = cos(headingAngle) * currentSpeed * CGFloat(CursorConfig.updateFrequency)
        targetVelocity.y = sin(headingAngle) * currentSpeed * CGFloat(CursorConfig.updateFrequency)
        
        // Add noise
        targetVelocity.x += humanLikeXNoise() * 0.1
        targetVelocity.y += humanLikeYDrift(position.x) * 0.1 * CGFloat(CursorConfig.updateFrequency)
        
        // Smooth changes
        currentVelocity.x += (targetVelocity.x - currentVelocity.x) * CursorConfig.smoothingFactor
        currentVelocity.y += (targetVelocity.y - currentVelocity.y) * CursorConfig.smoothingFactor
        
        // Add micro jitter when not pausing
        if !pauseState.isSlowingDown {
            let microJitterX = CGFloat.random(in: -CursorConfig.microJitterAmplitude...CursorConfig.microJitterAmplitude) * CursorConfig.microJitterFrequency
            let microJitterY = CGFloat.random(in: -CursorConfig.microJitterAmplitude...CursorConfig.microJitterAmplitude) * CursorConfig.microJitterFrequency
            currentVelocity.x += microJitterX
            currentVelocity.y += microJitterY
        }
    }
    
    private func applyMovement(screen: NSScreen) {
        // Apply slowdown if needed
        var moveFactor: CGFloat = 1.0
        if case .slowingDown(let startTime) = pauseState {
            let elapsed = Date().timeIntervalSinceReferenceDate - startTime
            let fraction = min(elapsed / CursorConfig.pauseSlowingDuration, 1.0)
            moveFactor = 1.0 - CGFloat(fraction)
        }
        
        // Calculate new position
        let dx = max(min(currentVelocity.x * moveFactor, CursorConfig.maxDeltaPerFrame), -CursorConfig.maxDeltaPerFrame)
        let dy = max(min(currentVelocity.y * moveFactor, CursorConfig.maxDeltaPerFrame), -CursorConfig.maxDeltaPerFrame)
        
        var newPosition = position
        newPosition.x += dx
        newPosition.y += dy
        
        // Handle screen boundaries
        handleScreenBoundaries(position: &newPosition, screen: screen)
        
        // Update position
        position = newPosition
        CGWarpMouseCursorPosition(position)
    }
    
    private func handleScreenBoundaries(position: inout CGPoint, screen: NSScreen) {
        if position.x > screen.frame.width - rightMargin {
            position.x = screen.frame.width - rightMargin
            bounceOffEdge()
        } else if position.x < leftMargin {
            position.x = leftMargin
            bounceOffEdge()
        }
        
        if position.y < bottomMargin {
            position.y = bottomMargin
            bounceOffEdge()
        } else if position.y > screen.frame.height - topMargin {
            position.y = screen.frame.height - topMargin
            bounceOffEdge()
        }
    }
    
    private func bounceOffEdge() {
        headingAngle += CGFloat.pi * CGFloat.random(in: 0.2...0.8)
        randomizeMargins()
        speedMultiplier = CGFloat.random(in: CursorConfig.minSpeedMultiplier...CursorConfig.maxSpeedMultiplier)
    }
    
    // MARK: - Helper Methods
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
            // Only use slowdown for automatic pauses
            pauseState = .slowingDown(startTime: now)
            desiredPauseEndTime = now + CursorConfig.pauseSlowingDuration + pauseDuration
            print("Starting to slow down for automatic pause, then pausing for \(Int(pauseDuration))s")
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
                resumeMovement()
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
}
