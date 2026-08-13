# FinFlow

FinFlow is a portfolio-grade personal finance app built as a production-minded iOS project.

## Current milestone — Smart search and insights

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
- Async/await exchange-rate networking with typed errors
- Preferred display currency across the financial dashboard
- USD, EUR, GBP, GEL, and JPY conversion
- UserDefaults-backed offline rate cache with network fallback
- Search across transaction titles, notes, accounts, categories, and amounts
- Filters for income, expenses, and spending categories
- Smart insight cards for budget risk, category trends, recurring expenses, and cash flow
- Unit tests for CRUD operations, balance calculations, and app state

## Stack

Swift, SwiftUI, SwiftData, Swift Charts, MVVM, protocol-oriented dependency injection, XCTest · iOS 17+
