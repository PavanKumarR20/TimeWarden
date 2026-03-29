# TimeWarden - Clean Architecture Folder Structure

## Core Layer (`lib/core/`)
- **constants/** - App-wide constants and configuration
- **services/** - External services (Firebase, etc.)
- **utils/** - Utility functions and helpers
- **widgets/** - Reusable UI components

## Features Layer (`lib/features/`)

### Auth Feature (`lib/features/auth/`)
- **data/**
  - **repositories/** - Auth repository implementations
- **domain/**
  - **entities/** - AppUser entity
  - **repositories/** - Auth repository interface
- **presentation/**
  - **bloc/** - AuthBloc for state management
  - **pages/** - Auth UI pages (sign in, sign up, wrapper)

### Habits Feature (`lib/features/habits/`)
- **data/**
  - **repositories/** - Habit repository implementation
- **domain/**
  - **entities/** - Habit entity
  - **repositories/** - Habit repository interface
- **presentation/**
  - **bloc/** - HabitsBloc for state management
  - **pages/** - Habits UI pages
  - **widgets/** - Habit-specific widgets

### Dashboard Feature (`lib/features/dashboard/`)
- **presentation/**
  - **pages/** - Main dashboard with navigation

## Key Improvements Made:

### 1. Simplified Data Layer
- ✅ Changed from Stream-based to Future-based habit loading
- ✅ Eliminated complex stream subscription management
- ✅ Removed race condition issues with BLoC emit

### 2. Clean Architecture Implementation
- ✅ Proper separation of data, domain, and presentation layers
- ✅ Repository pattern with interfaces
- ✅ Entity models separated from Firebase models
- ✅ Dependency injection through constructor parameters

### 3. Consistent Error Handling
- ✅ Centralized error messages
- ✅ Graceful degradation for common errors
- ✅ Better logging for debugging

### 4. Code Organization
- ✅ Consistent folder structure across features
- ✅ Shared utilities in core layer
- ✅ Constants and validation helpers
- ✅ Removed temporary/duplicate files

### 5. Better State Management
- ✅ Simplified BLoC logic
- ✅ Proper async/await patterns
- ✅ Automatic refresh after CRUD operations
- ✅ Pull-to-refresh support

## What to Test:
1. Authentication flow (sign in/up/out)
2. Habits loading (should show empty state, not infinite loading)
3. Adding/editing/deleting habits
4. Habit completion toggle
5. Pull-to-refresh functionality
