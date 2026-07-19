import Foundation
import SwiftData

@Model
final class AccountRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRawValue: String
    var balanceAmount: Decimal
    var currencyCode: String
    var iconName: String
    var tintHex: String
    var createdAt: Date

    init(account: Account, createdAt: Date = .now) {
        id = account.id
        name = account.name
        kindRawValue = account.kind.rawValue
        balanceAmount = account.balance.amount
        currencyCode = account.balance.currencyCode
        iconName = account.iconName
        tintHex = account.tintHex
        self.createdAt = createdAt
    }

    var domainModel: Account {
        Account(
            id: id,
            name: name,
            kind: Account.Kind(rawValue: kindRawValue) ?? .checking,
            balance: Money(balanceAmount, currencyCode: currencyCode),
            iconName: iconName,
            tintHex: tintHex
        )
    }
}

@Model
final class CategoryRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var tintHex: String

    init(category: SpendingCategory) {
        id = category.id
        name = category.name
        iconName = category.iconName
        tintHex = category.tintHex
    }

    var domainModel: SpendingCategory {
        SpendingCategory(id: id, name: name, iconName: iconName, tintHex: tintHex)
    }
}

@Model
final class TransactionRecord {
    @Attribute(.unique) var id: UUID
    var accountID: UUID
    var categoryID: UUID?
    var title: String
    var amount: Decimal
    var currencyCode: String
    var kindRawValue: String
    var date: Date
    var note: String?

    init(transaction: FinancialTransaction) {
        id = transaction.id
        accountID = transaction.accountID
        categoryID = transaction.categoryID
        title = transaction.title
        amount = transaction.amount.amount
        currencyCode = transaction.amount.currencyCode
        kindRawValue = transaction.kind.rawValue
        date = transaction.date
        note = transaction.note
    }

    var domainModel: FinancialTransaction {
        FinancialTransaction(
            id: id,
            accountID: accountID,
            categoryID: categoryID,
            title: title,
            amount: Money(amount, currencyCode: currencyCode),
            kind: FinancialTransaction.Kind(rawValue: kindRawValue) ?? .expense,
            date: date,
            note: note
        )
    }
}
