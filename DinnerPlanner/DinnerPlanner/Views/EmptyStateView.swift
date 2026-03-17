import SwiftUI

/// iOS 16-compatible replacement for ContentUnavailableView (iOS 17+).
struct EmptyStateView: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundColor(.secondary)
            Text(title)
                .font(.title3.bold())
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}
