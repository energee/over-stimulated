//
//  OverStimulatedTests.swift
//  OverStimulatedTests
//
//  Created by Ted Slesinski on 12/18/24.
//

import XCTest
@testable import OverStimulated

final class OverStimulatedTests: XCTestCase {
    var controller: CursorController!
    
    override func setUp() {
        super.setUp()
        controller = CursorController()
    }
    
    override func tearDown() {
        controller = nil
        super.tearDown()
    }
    
    func testTogglePause() {
        // Initially not paused
        XCTAssertFalse(controller.isPaused)
        
        // Toggle pause on
        controller.togglePause()
        XCTAssertTrue(controller.isPaused)
        
        // Toggle pause off
        controller.togglePause()
        XCTAssertFalse(controller.isPaused)
    }
}
