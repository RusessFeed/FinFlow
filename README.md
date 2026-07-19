# FinFlow

FinFlow is a portfolio-grade personal finance app built as a production-minded iOS project.

## Current milestone — Exchange rates and offline caching

- SwiftUI application shell and tab navigation
- Dependency injection through `AppContainer`
- Persisted onboarding state
- Reusable design tokens and UI components
- Domain models for accounts, categories, transactions, and money
- SwiftData persistence behind a protocol-based repository
- Account creation with type-specific visual styling
- Income and expense forms with validation and categories
- Transaction deletion with automatic balance rollback
- Live dashboard totals driven by persisted data
- Seven-day spending chart powered by Swift Charts
- Monthly income, spending, and cash-flow calculations
- Category breakdown with accessible visualizations
- Editable monthly budgets with progress and warning states
- Multi-page receipt scanning powered by VisionKit
- Photo-library receipt import and on-device Vision OCR
- Automatic merchant, total, and date extraction
- Async/await exchange-rate networking with typed errors
- Preferred display currency across the financial dashboard
- USD, EUR, GBP, GEL, and JPY conversion
- UserDefaults-backed offline rate cache with network fallback
- Unit tests for CRUD operations, balance calculations, and app state

## Roadmap

Future milestones will add smart insights, security, widgets, accessibility polish, and CI.

## Stack

Swift, SwiftUI, SwiftData, Swift Charts, VisionKit, Vision, MVVM, protocol-oriented dependency injection, XCTest · iOS 17+
