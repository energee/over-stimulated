# OverStimulated

OverStimulated is a macOS utility that simulates natural human cursor movement to keep your computer active. It creates organic, human-like mouse movements with realistic acceleration, deceleration, and pause patterns.

## Features

- 🖱️ Realistic cursor movement simulation
  - Natural acceleration and deceleration
  - Random direction changes
  - Micro-jitters that mimic human hand tremors
  - Edge-aware behavior that respects screen boundaries
  
- ⏸️ Intelligent pausing system
  - Random pauses that mimic human behavior
  - Smooth slowdown before pausing
  - Manual pause/resume with keyboard shortcut
  
- 🎯 Focus point system
  - Simulates human tendency to gravitate toward certain screen areas
  - Dynamically changes over time
  
- 🎛️ Menu bar controls
  - Easy access to pause/resume
  - Quick quit option
  - Keyboard shortcuts (P to pause, Q to quit)

## To Modify

1. Clone this repository
2. Open the project in Xcode
3. Build and run the application
4. Grant accessibility permissions when prompted

## To install

Available in the builds on the right.

## Usage

Once launched, OverStimulated runs in your menu bar. The icon indicates the current state:
- ⏺️ Circle: Active (cursor moving)
- ⏸️ Pause: Paused

### Controls
- Click the menu bar icon to access controls
- Press `p` to toggle pause/resume
- Press `q` to quit the application

## Configuration

The cursor behavior can be fine-tuned by modifying the constants in `CursorConfig.swift`. Key parameters include:

- Base movement speed
- Edge margins
- Pause frequency and duration
- Movement noise and jitter
- Speed variation
- Direction change probability

## Requirements

- macOS 15.1 or later
- Xcode 16.2 or later (for development)

## Privacy

OverStimulated requires accessibility permissions to control the cursor position. It operates entirely locally and does not collect or transmit any data.

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2024 Ted Slesinski

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.