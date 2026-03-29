# GitHub Copilot Instructions for TimeWarden

## General Development Principles

- **Always follow industry best practices** for code quality, architecture, and design patterns
- **Clean Architecture**: Maintain strict separation between domain, data, and presentation layers
- **SOLID Principles**: Follow Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion
- **DRY (Don't Repeat Yourself)**: Extract duplicated code into reusable components or utilities

## Flutter/Dart Specific Standards

### Architecture
- Use **BLoC pattern** for state management with `flutter_bloc` package
- Follow **Clean Architecture** layers:
  - `domain/` - Business logic, entities, use cases (no Flutter dependencies)
  - `data/` - Repositories, data sources, models
  - `presentation/` - UI, BLoC, pages, widgets
- **Never** access repositories directly from UI widgets - always use BLoC
- Keep business logic in services or use cases, not in widgets or BLoCs

### Code Organization
- One widget per file for complex widgets
- Extract reusable widgets to `core/widgets/`
- Extract shared utilities to `core/utils/` or `core/services/`
- Group related files in feature folders

### State Management
- Use BLoC for complex state, Provider for simple dependency injection
- Events should be immutable and descriptive
- States should be immutable and use Equatable
- Handle all possible states: loading, loaded, error
- Never mutate state directly - always emit new state instances

### Error Handling
- Always handle errors gracefully with user-friendly messages
- Show loading states for async operations
- Provide retry mechanisms for failed operations
- Use try-catch blocks around repository/service calls
- Log errors with context using LogService

### Code Quality
- **Type Safety**: Use explicit types, avoid `dynamic` unless necessary
- **Null Safety**: Handle nullable types properly with `?` and `??`
- **Immutability**: Prefer `final` over `var`, use `const` where possible
- **Naming**: Use descriptive names (classes: PascalCase, variables: camelCase, files: snake_case)
- Remove unused imports automatically
- Follow Dart style guide for formatting

### Widget Development
- Use `const` constructors wherever possible for performance
- Extract complex build methods into smaller widget methods
- Use `Builder` pattern when accessing context for Scaffold/Theme
- Prefer composition over inheritance
- Keep widget trees shallow - extract nested widgets

### Testing
- Write unit tests for services, use cases, and BLoCs
- Aim for >70% code coverage on business logic
- Use mocks for external dependencies
- Test error cases, edge cases, and happy paths
- Name tests descriptively: `test('should return points when habits completed', ...)`

### Performance
- Use `ListView.builder` for long lists, not `ListView` with `children`
- Avoid rebuilding widgets unnecessarily
- Use `const` constructors to prevent unnecessary rebuilds
- Optimize images and assets
- Profile before optimizing

### Firebase/Backend
- Always check `FirebaseService().currentUserId` before operations
- Handle offline scenarios gracefully
- Use repositories to abstract Firebase implementation
- Never expose sensitive data in client code
- Validate data before sending to backend

### UI/UX
- Follow Material Design 3 guidelines
- Use theme colors from `Theme.of(context)` - no hardcoded colors
- Add haptic feedback for user interactions (HapticService)
- Provide visual feedback for all actions
- Support both light and dark themes
- Make UI accessible (semantic labels, contrast ratios)

### Documentation
- Add doc comments (`///`) for public APIs
- Document complex business logic
- Keep README.md and architecture docs updated
- Use meaningful commit messages

## Anti-Patterns to Avoid

❌ Direct repository access from widgets
❌ Business logic in widgets or UI code
❌ Mutable state in BLoC
❌ Hardcoded strings - use constants or localization
❌ Hardcoded colors - use theme
❌ Ignoring null safety
❌ Code duplication
❌ Missing error handling
❌ Silent failures without user feedback
❌ Mixing concerns (e.g., UI logic in data layer)

## When Implementing New Features

1. **Plan architecture** - Which layers are affected?
2. **Update domain layer** - Entities, use cases
3. **Update data layer** - Repositories, models
4. **Update presentation layer** - BLoC, UI
5. **Add error handling** - All layers
6. **Write tests** - At least for business logic
7. **Review code quality** - Check against these standards
8. **Update documentation** - If architecture changed

## Code Review Checklist

Before considering code complete, verify:
- [ ] Follows Clean Architecture principles
- [ ] Uses BLoC pattern correctly (no direct repository access)
- [ ] Has proper error handling and loading states
- [ ] No code duplication
- [ ] No unused imports or variables
- [ ] Proper type safety (no unnecessary `dynamic`)
- [ ] Uses theme colors (no hardcoded colors)
- [ ] Has haptic/visual feedback for interactions
- [ ] Includes relevant tests
- [ ] Code is readable and well-organized
- [ ] Follows Dart style guide

## Refactoring Guidelines

When refactoring:
- Extract duplicated code into shared utilities/widgets
- Improve architecture violations (e.g., UI accessing repositories)
- Add missing error handling
- Improve type safety
- Simplify complex methods
- Add tests for untested code

## Performance Optimization

- Profile before optimizing
- Use `const` constructors
- Optimize widget rebuilds
- Use builders for large lists
- Lazy load data when appropriate
- Cache expensive computations
