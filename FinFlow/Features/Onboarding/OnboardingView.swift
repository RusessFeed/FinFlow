import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var page = 0

    private let pages = [
        OnboardingPage(
            title: "See the whole picture",
            message: "Bring every account together and understand where your money goes.",
            systemImage: "chart.pie.fill",
            color: FFColor.accent
        ),
        OnboardingPage(
            title: "Build better habits",
            message: "Set thoughtful budgets and follow progress without complicated spreadsheets.",
            systemImage: "target",
            color: FFColor.positive
        ),
        OnboardingPage(
            title: "Private by design",
            message: "Your financial data stays under your control and remains available offline.",
            systemImage: "lock.shield.fill",
            color: Color(hex: "#0984E3")
        )
    ]

    var body: some View {
        VStack(spacing: FFLayout.large) {
            HStack {
                Spacer()
                if page < pages.count - 1 {
                    Button("Skip") { finish() }
                        .foregroundStyle(FFColor.secondaryText)
                }
            }
            .frame(height: 30)

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                    OnboardingPageView(page: item)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button(page == pages.count - 1 ? "Start with FinFlow" : "Continue") {
                if page == pages.count - 1 {
                    finish()
                } else {
                    withAnimation { page += 1 }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(FFLayout.large)
        .background(FFColor.canvas.ignoresSafeArea())
    }

    private func finish() {
        container.completeOnboarding()
    }
}

private struct OnboardingPage {
    let title: String
    let message: String
    let systemImage: String
    let color: Color
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: FFLayout.large) {
            Spacer()
            Image(systemName: page.systemImage)
                .font(.system(size: 70, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 160, height: 160)
                .background(page.color.gradient, in: RoundedRectangle(cornerRadius: 44))
                .shadow(color: page.color.opacity(0.25), radius: 28, y: 16)
                .accessibilityHidden(true)

            VStack(spacing: FFLayout.small) {
                Text(page.title)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(FFColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, FFLayout.medium)
    }
}
