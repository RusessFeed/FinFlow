import SwiftUI

struct FFCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(FFLayout.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FFColor.card, in: RoundedRectangle(cornerRadius: FFLayout.cardRadius))
    }
}
