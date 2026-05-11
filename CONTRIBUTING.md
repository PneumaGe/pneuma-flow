# Contributing to PneumaGe

Thank you for your interest in contributing to PneumaGe! We welcome contributions from researchers, developers, and anyone interested in gas flux measurement and environmental science.

## How to Contribute

### Reporting Bugs

If you find a bug, please open an issue on GitHub with:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs. actual behavior
- Device/OS information (Android/iOS version, Flutter version)
- Screenshots or logs if applicable

### Suggesting Features

We welcome feature suggestions! Please open an issue with:
- A clear description of the feature
- Your use case (how would this help your research?)
- Any relevant scientific context or references

### Submitting Code

1. **Fork the repository** and create a branch for your feature/fix
2. **Follow the coding style**:
   - Use Dart formatting: `dart format .`
   - Follow Flutter best practices
   - Add comments for complex logic
   - Use meaningful variable names
3. **Test your changes**:
   - Test on a physical device (BLE doesn't work in simulators)
   - Verify both Android and iOS if possible
   - Check landscape mode behavior
4. **Commit with clear messages**:
   - Use descriptive commit messages
   - Reference issue numbers: `Fixes #123`
5. **Submit a Pull Request**:
   - Describe what you changed and why
   - Link related issues
   - Be responsive to feedback

## Development Setup

### Prerequisites
- Flutter 3.38.3 or higher
- Dart 3.10.1 or higher
- Physical Android or iOS device (for BLE testing)
- Arduino Nano BLE Sense Rev 2 (optional, for full hardware testing)

### Getting Started
```bash
git clone https://github.com/[your-username]/pneumage-app.git
cd pneumage-app
flutter pub get
flutter run
```

### Project Structure
```
lib/
├── main.dart              # App entry point
├── config/               # Configuration and constants
├── models/               # Data models (User, Project, Measurement, etc.)
├── providers/            # Riverpod providers for state management
├── screens/              # UI screens (Home, Scan/Connect, etc.)
├── services/             # Business logic (BLE, GPS, Firebase, etc.)
├── theme/                # App theming and design constants
└── widgets/              # Reusable UI components

plugins/
└── pneumage_offline_maps/ # Custom plugin for offline maps
```

## Code of Conduct

### Our Standards
- **Be respectful**: Treat all contributors with respect
- **Be collaborative**: Work together to improve PneumaGe
- **Be patient**: Remember this is a research project
- **Be constructive**: Provide helpful feedback
- **Be scientific**: Back suggestions with research when possible

### Unacceptable Behavior
- Harassment, discrimination, or personal attacks
- Trolling, insulting, or derogatory comments
- Publishing others' private information
- Any conduct inappropriate in a professional setting

## Questions?

- **Technical questions**: Open a GitHub Discussion
- **Bug reports**: Open a GitHub Issue
- **Security issues**: Email [your-email] directly (don't open a public issue)

## License

By contributing to PneumaGe, you agree that your contributions will be licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## Recognition

Contributors will be acknowledged in:
- The project README
- Release notes
- Any resulting publications (for significant scientific contributions)

Thank you for helping make PneumaGe better for the research community! 🌱
