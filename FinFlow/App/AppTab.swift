import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case overview
    case activity
    case accounts
    case profile

    var id: Self { self }

    var title: String {
        switch self {
        case .overview: "Overview"
        case .activity: "Activity"
        case .accounts: "Accounts"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "chart.pie.fill"
        case .activity: "arrow.left.arrow.right"
        case .accounts: "creditcard.fill"
        case .profile: "person.crop.circle"
        }
    }
}
