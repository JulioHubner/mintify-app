# Development Guide

This guide helps you set up a development environment for Mintify.

## Prerequisites

- **macOS 14.0+** (Sonoma or later)
- **Xcode 15.0+**
- **XcodeGen** for project generation

### Install XcodeGen

```bash
brew install xcodegen
```

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/Mintify.git
cd Mintify
```

### 2. Generate Xcode Project

```bash
xcodegen generate
```

This creates `Mintify.xcodeproj` from `project.yml`.

### 3. Open in Xcode

```bash
open Mintify.xcodeproj
```

### 4. Set Development Team (Optional)

If you want to run on a real device or distribute:
1. Open project settings in Xcode
2. Select the "Mintify" target
3. Go to "Signing & Capabilities"
4. Set your Development Team

### 5. Build & Run

Press `⌘R` to build and run.

---

## Project Configuration

### project.yml

The `project.yml` file defines the Xcode project structure. Key sections:

```yaml
name: Mintify
options:
  bundleIdPrefix: com.yourname
  deploymentTarget:
    macOS: "14.0"
  
targets:
  Mintify:
    type: application
    platform: macOS
    sources:
      - path: Mintify
```

### After Adding New Files

If you add new Swift files:

```bash
xcodegen generate
```

This updates the Xcode project to include new files.

---

## Code Style

### SwiftUI Best Practices

- Use `@EnvironmentObject` for state shared across views
- Extract reusable views to `Views/Shared/`
- Keep views focused on presentation, logic in State classes

### File Organization

- One type per file (with minor exceptions)
- Views in feature-based folders
- Services contain business logic
- Models are pure data structures

---

## Building for Release

```bash
xcodebuild -scheme Mintify -configuration Release archive
```

---

## Troubleshooting

### "No such module" errors

Run `xcodegen generate` to regenerate the project.

### Code signing issues

Set your Development Team in Xcode project settings, or leave empty for local development.

### App doesn't appear in menu bar

Check Console.app for crash logs. The app runs as a menu bar accessory by default.
