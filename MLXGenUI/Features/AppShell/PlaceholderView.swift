import SwiftUI

/// A consistent empty state for features that are not yet implemented.
struct PlaceholderView: View {
    /// The empty-state heading.
    let title: String
    /// The SF Symbols name displayed above the heading.
    let systemImage: String
    /// A short explanation of the planned feature.
    let description: String

    /// The empty-state content.
    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(description))
            .navigationTitle(title)
    }
}
