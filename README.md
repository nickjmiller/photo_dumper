# Photo Dumper

A Flutter application for comparing and managing photos with swipe gestures. Built with clean architecture principles, BLoC pattern for state management, and comprehensive testing.

## Features

- **Photo Comparison**: Compare two photos side by side
- **Swipe Gestures**: Swipe right to keep, left to delete photos
- **Confirmation Dialogs**: Confirm actions before executing
- **Bulk Actions**: Keep or discard both photos at once
- **Material 3 Design**: Modern UI with Material 3 components
- **Responsive Layout**: Works on different screen sizes

## Architecture

This project follows **Clean Architecture** principles with the following structure:

```
lib/
├── core/
│   ├── constants/          # App-wide constants
│   ├── di/                 # Dependency injection setup
│   ├── error/              # Error handling and failures
│   └── theme/              # App theme configuration
├── features/
│   └── photo_comparison/
│       ├── data/
│       │   └── repositories/   # Data layer implementations
│       ├── domain/
│       │   ├── entities/       # Business entities
│       │   ├── repositories/   # Repository interfaces
│       │   └── usecases/       # Business logic use cases
│       └── presentation/
│           ├── bloc/           # State management
│           ├── pages/          # Screen implementations
│           └── widgets/        # Reusable UI components
└── main.dart
```

### Architecture Layers

1. **Presentation Layer**: UI components, BLoC state management
2. **Domain Layer**: Business logic, entities, use cases
3. **Data Layer**: Repository implementations, data sources

### Key Components

- **BLoC Pattern**: State management using `flutter_bloc`
- **Dependency Injection**: Using `get_it` for service locator pattern
- **Error Handling**: Functional error handling with `dartz`
- **Repository Pattern**: Abstract data access layer
- **Use Cases**: Business logic encapsulation

## Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Dart SDK (3.9.0 or higher)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd photo_dumper
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the application:
```bash
flutter run
```

## Testing

The project includes comprehensive testing at multiple levels:

### Test Structure

```
test/
├── unit/                      # Unit tests for business logic
├── widget/                    # Widget tests for UI components
├── integration/               # Integration tests for user flows
└── widget_test.dart           # Default Flutter test
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget/features/photo_comparison/presentation/widgets/action_buttons_test.dart

# Run tests with coverage
flutter test --coverage
```

### Test Coverage

- **Unit Tests**: Business logic, use cases, entities
- **Widget Tests**: UI components, user interactions
- **Integration Tests**: End-to-end user flows

## Dependencies

### Core Dependencies

- `flutter_bloc`: State management
- `get_it`: Dependency injection
- `dartz`: Functional programming utilities
- `equatable`: Value equality for objects

### Development Dependencies

- `flutter_test`: Flutter testing framework
- `bloc_test`: BLoC testing utilities
- `mockito`: Mocking framework
- `build_runner`: Code generation
- `flutter_lints`: Code quality rules

## State Management

The app uses **BLoC (Business Logic Component)** pattern for state management:

### Events
- `LoadPhotos`: Load photos for comparison
- `KeepPhoto`: Keep a specific photo
- `DeletePhoto`: Delete a specific photo
- `KeepBothPhotos`: Keep both photos
- `DeleteBothPhotos`: Delete both photos

### States
- `PhotoComparisonInitial`: Initial state
- `PhotoComparisonLoading`: Loading state
- `PhotoComparisonLoaded`: Photos loaded successfully
- `PhotoComparisonActionInProgress`: Action in progress
- `PhotoComparisonActionSuccess`: Action completed successfully
- `PhotoComparisonError`: Error state

## Error Handling

The app implements functional error handling using the `Either` type from `dartz`:

- `ServerFailure`: Server-related errors
- `CacheFailure`: Local storage errors
- `NetworkFailure`: Network connectivity errors
- `PhotoOperationFailure`: Photo operation errors

## Code Quality

- **Linting**: Uses `flutter_lints` for code quality
- **Null Safety**: Full null safety implementation
- **Clean Code**: Follows Flutter best practices
- **Documentation**: Comprehensive code documentation

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- BLoC library maintainers
- Material Design team for the design system
