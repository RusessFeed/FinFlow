import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var container: AppContainer

    private let currencies = ["USD", "EUR", "GBP", "GEL", "JPY"]

    var body: some View {
        NavigationStack {
            List {
                Section("Currency") {
                    Picker("Display currency", selection: currencyBinding) {
                        ForEach(currencies, id: \.self) { code in
                            Text(currencyName(code)).tag(code)
                        }
                    }

                    if let rates = container.exchangeRates {
                        LabeledContent("Market date", value: rates.marketDate)
                        LabeledContent("Last synchronized") {
                            Text(rates.fetchedAt, format: .relative(presentation: .named))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        Task { await container.refreshExchangeRates() }
                    } label: {
                        HStack {
                            Label("Refresh exchange rates", systemImage: "arrow.clockwise")
                            Spacer()
                            if container.isRefreshingRates { ProgressView() }
                        }
                    }
                    .disabled(container.isRefreshingRates)

                    if let message = container.rateErrorMessage {
                        Label(message, systemImage: "wifi.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(FFColor.warning)
                    }
                }

                Section("Preferences") {
                    Label("Appearance", systemImage: "circle.lefthalf.filled")
                }

                Section("Data source") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Frankfurter exchange-rate API")
                        Text("Rates are cached for reliable offline access.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Development") {
                    Button("Show onboarding again") {
                        container.resetOnboarding()
                    }
                }

                Section {
                    Text("FinFlow · Portfolio build")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
            .refreshable {
                await container.refreshExchangeRates()
            }
        }
    }

    private var currencyBinding: Binding<String> {
        Binding(
            get: { container.preferredCurrency },
            set: { container.setPreferredCurrency($0) }
        )
    }

    private func currencyName(_ code: String) -> String {
        let name = Locale.current.localizedString(forCurrencyCode: code) ?? code
        return "\(code) · \(name)"
    }
}
