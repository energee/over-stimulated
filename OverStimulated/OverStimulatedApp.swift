//
//  OverStimulatedApp.swift
//  OverStimulated
//
//  Created by Ted Slesinski on 12/18/24.
//

import SwiftUI

@main
struct OverStimulatedApp: App {
    @StateObject private var controller = CursorController()
    
    var body: some Scene {
        MenuBarExtra {
            Button(action: {
                controller.togglePause()
            }) {
                Text(controller.isPaused ? "Resume" : "Pause")
            }
            .keyboardShortcut("p", modifiers: [])
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Text("Quit")
            }
            .keyboardShortcut("q", modifiers: [])
        } label: {
            Group {
                if controller.isPaused {
                    Image(systemName: "pause")
                } else {
                    Image(systemName: "circle")
                }
            }
        }
    }
}
