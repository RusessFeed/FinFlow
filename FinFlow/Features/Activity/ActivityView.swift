import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var showingAddTransaction = false
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var kindFilter: TransactionKindFilter = .all
    @State private var categoryFilterID: UUID?

    private var filteredTransactions: [FinancialTransaction] {
        TransactionSearch.filter(
            transactions: container.transactions,
            accounts: container.accounts,
            categories: container.categories,
            filter: TransactionSearchFilter(
                query: searchText,
                kind: kindFilter,
                categoryID: categoryFilterID
            )
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if container.transactions.isEmpty {
                    ContentUnavailableView(
                        "No transactions yet",
                        systemImage: "arrow.left.arrow.right.circle",
                        description: Text("Add an income or expense to start tracking activity.")
                    )
                } else {
                    List {
                        Section {
                            Picker("Transaction type", selection: $kindFilter) {
                                ForEach(TransactionKindFilter.allCases) { filter in
                                    Text(filter.title).tag(filter)
                                }
                            }
                            .pickerStyle(.segmented)

                            Menu {
                                Button("All categories") { categoryFilterID = nil }
                                ForEach(container.categories) { category in
                                    Button {
                                        categoryFilterID = category.id
                                    } label: {
                                        Label(category.name, systemImage: category.iconName)
                                    }
                                }
                            } label: {
                                Label(selectedCategoryTitle, systemImage: "line.3.horizontal.decrease.circle")
                            }
                        }

                        if filteredTransactions.isEmpty {
                            ContentUnavailableView.search(text: searchText.isEmpty ? selectedCategoryTitle : searchText)
                        }

                        ForEach(filteredTransactions) { transaction in
                            TransactionRow(
                                transaction: transaction,
                                category: container.category(id: transaction.categoryID),
                                account: container.account(id: transaction.accountID)
                            )
                            .swipeActions {
                                Button(role: .destructive) {
                                    delete(transaction)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Activity")
            .searchable(text: $searchText, prompt: "Search title, account, category")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAddTransaction = true } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add transaction")
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
            .alert("Could not update activity", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private var selectedCategoryTitle: String {
        guard let categoryFilterID,
              let category = container.categories.first(where: { $0.id == categoryFilterID }) else {
            return "All categories"
        }
        return category.name
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func delete(_ transaction: FinancialTransaction) {
        do {
            try container.deleteTransaction(id: transaction.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct TransactionRow: View {
    let transaction: FinancialTransaction
    let category: SpendingCategory?
    let account: Account?

    private var amountColor: Color {
        transaction.kind == .income ? FFColor.positive : .primary
    }

    private var amountPrefix: String {
        transaction.kind == .income ? "+" : "−"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category?.iconName ?? "arrow.left.arrow.right")
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color(hex: category?.tintHex ?? "#636E72"), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.title).font(.headline)
                Text([account?.name, transaction.date.formatted(date: .abbreviated, time: .omitted)]
                    .compactMap { $0 }
                    .joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(amountPrefix + transaction.amount.formatted())
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(amountColor)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

private struct AddTransactionView: View {
    @EnvironmentObject private var container: AppContainer
    @Environment(\.dismiss) private var dismiss
    @State private var kind: FinancialTransaction.Kind = .expense
    @State private var title = ""
    @State private var amount = ""
    @State private var accountID: UUID?
    @State private var categoryID: UUID?
    @State private var date = Date.now
    @State private var note = ""
    @State private var errorMessage: String?

    private var parsedAmount: Decimal? {
        guard let value = Decimal(string: amount.replacingOccurrences(of: ",", with: ".")), value > 0 else {
            return nil
        }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        Text("Expense").tag(FinancialTransaction.Kind.expense)
                        Text("Income").tag(FinancialTransaction.Kind.income)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Details") {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                    Picker("Account", selection: $accountID) {
                        Text("Select account").tag(UUID?.none)
                        ForEach(container.accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    Picker("Category", selection: $categoryID) {
                        Text("Uncategorized").tag(UUID?.none)
                        ForEach(container.categories) { category in
                            Label(category.name, systemImage: category.iconName)
                                .tag(Optional(category.id))
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: [.date])
                }

                Section("Optional note") {
                    TextField("Note", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(!canSave)
                }
            }
            .onAppear {
                accountID = accountID ?? container.accounts.first?.id
                categoryID = categoryID ?? defaultCategoryID
            }
            .alert("Could not add transaction", isPresented: errorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && parsedAmount != nil
            && accountID != nil
    }

    private var defaultCategoryID: UUID? {
        let preferredName = kind == .income ? "Salary" : "Food"
        return container.categories.first { $0.name == preferredName }?.id
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )
    }

    private func save() {
        guard let accountID, let parsedAmount else { return }
        do {
            try container.addTransaction(
                TransactionDraft(
                    accountID: accountID,
                    categoryID: categoryID,
                    title: title,
                    amount: Money(parsedAmount),
                    kind: kind,
                    date: date,
                    note: note.isEmpty ? nil : note
                )
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
