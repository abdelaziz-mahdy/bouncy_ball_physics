

# Bouncy Ball Physics

## Overview
"Bouncy Ball Physics" is a Flutter application that demonstrates a physics-based animation of bouncing balls. This project showcases the capabilities of Flutter in creating dynamic and interactive animations, utilizing core concepts such as custom painting, animation controllers, and state management.

## Features
- **Dynamic Ball Animation**: Balls bounce around the screen, reflecting off the edges.
- **Physics Simulation**: Simple physics principles are applied to create realistic ball movements.
- **FPS Counter**: Displays the current frames per second, demonstrating the app's performance.
- **Ball Count Display**: Shows the number of balls currently on screen.
- **Responsive Design**: Adjusts to various screen sizes and orientations.
- **Reset Functionality**: A button to reset the animation and start afresh.

## Screenshots

| Trail Shape         | Desktop Screenshot                                                | Mobile Screenshot                                              |
|---------------------|-------------------------------------------------------------------|----------------------------------------------------------------|
| Line                | ![Line Desktop](test/goldens/line.desktop.png)                    | ![Line Mobile](test/goldens/line.phone.png)                    |
| Single Triangle     | ![Single Triangle Desktop](test/goldens/single_triangle.desktop.png) | ![Single Triangle Mobile](test/goldens/single_triangle.phone.png) |
| Multiple Triangles  | ![Multiple Triangles Desktop](test/goldens/multiple_triangles.desktop.png) | ![Multiple Triangles Mobile](test/goldens/multiple_triangles.phone.png) |

## Getting Started

### Prerequisites
- Flutter installed on your machine
- An IDE (like Android Studio or VS Code)
- An emulator or physical device to run the app

### Installation
1. Clone the repository to your local machine:
   ```
   git clone https://github.com/abdelaziz-mahdy/bouncy-ball-physics.git
   ```
2. Open the project in your preferred IDE.
3. Run the following command in the terminal to get the necessary packages:
   ```
   flutter pub get
   ```
4. Start the emulator or connect your device.
5. Run the app:
   ```
   flutter run
   ```

## Usage
Upon launching the app, you will see animated balls bouncing around the screen. The FPS and the number of balls are displayed at the top. Use the refresh button to reset the animation.

## Renderers

The settings panel (gear icon) switches between three renderers that draw the same physics state:

| Mode | How it draws |
|------|--------------|
| Canvas (CPU) | `CustomPainter` with plain `Canvas` calls |
| Shader (GPU) | `CustomPainter` with fragment shaders (`shaders/*.frag`) |
| flutter_scene (3D) | [`flutter_scene`](https://pub.dev/packages/flutter_scene) on Flutter GPU; balls are spheres, trails are rebuilt meshes |

Flutter GPU is enabled in the iOS/macOS `Info.plist` and the Android manifest. On Windows/Linux pass `--enable-flutter-gpu` to `flutter run`.

### Benchmark

Run the built-in sweep (every renderer × several loads, prints `BENCH` lines, then exits):

```bash
flutter run --profile -d macos --dart-define=BENCH=true
```

Results on an Apple Silicon MacBook, 120 Hz display, profile build, `Line` trail shape, FPS averaged over 5 s after an 8 s warm-up:

| balls × tail | Canvas | flutter_scene | Shader |
|-------------:|-------:|--------------:|-------:|
| 10 × 100     | 120.0  | 120.1         | 13.9   |
| 100 × 10     | 119.9  | 119.9         | 12.3   |
| 100 × 100    | 117.4  | 120.0         | 85.7   |
| 300 × 300    | 20.8   | 119.4         | 14.5   |
| 500 × 500    | 15.0   | 66.1          | 10.7   |
| 1000 × 100   | 13.2   | 104.6         | 15.2   |
| 1000 × 500   | 16.7   | 39.2          | 7.1    |
| 2000 × 100   | 12.4   | 48.4          | 10.9   |

The scene renderer batches every trail into one updatable mesh (one draw, no per-frame allocation), which is why it pulls ahead once segment counts get large. The shader renderer issues one shader `drawRect` per trail segment, which on Impeller becomes a blend sub-pass each, so it is raster-bound and erratic, and at large loads a single frame can take long enough that the app appears frozen.

## Contributing
Contributions to "Bouncy Ball Physics" are welcome.

