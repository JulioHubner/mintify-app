# Contributing to Mintify

Thank you for your interest in contributing to Mintify! This document provides guidelines and information for contributors.

## Getting Started

1. Fork the repository
2. Clone your fork locally
3. Set up the development environment (see [DEVELOPMENT.md](DEVELOPMENT.md))
4. Create a feature branch

## How to Contribute

### Reporting Bugs

- Use GitHub Issues
- Include macOS version and Xcode version
- Describe steps to reproduce
- Include screenshots if applicable

### Suggesting Features

- Open a GitHub Issue with the `enhancement` label
- Describe the use case
- Explain why this would be useful

### Pull Requests

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**:
   - Follow existing code style
   - Add comments for complex logic
   - Keep commits focused

3. **Test your changes**:
   ```bash
   xcodebuild -scheme Mintify -destination 'platform=macOS' build
   ```

4. **Submit PR**:
   - Write a clear description
   - Reference any related issues
   - Wait for review

## Code Guidelines

### Swift Style

- Use Swift naming conventions (camelCase for properties/functions, PascalCase for types)
- Prefer `let` over `var` when possible
- Use trailing closure syntax
- Add documentation comments for public APIs

### SwiftUI

- Keep views focused and small
- Extract reusable components
- Use `@EnvironmentObject` for shared state
- Avoid complex logic in view bodies

### File Organization

```
Views/
├── FeatureName/           # Feature-specific views
│   └── FeatureView.swift
├── Shared/                # Reusable components
│   └── ComponentView.swift
```

## Commit Messages

Format: `type: short description`

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Code style (formatting, etc.)
- `refactor`: Code restructuring
- `test`: Adding tests

Examples:
```
feat: add dark mode toggle to settings
fix: resolve memory leak in scanner
docs: update installation instructions
```

## Questions?

Open an issue with the `question` label and we'll be happy to help!
