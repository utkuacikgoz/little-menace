import SwiftUI

/// Settings and Points in the app's cream style rather than stock grey lists, to match the other sheets.
extension View {
    /// The whole form: cream page, rounded type, orange controls, a cream navigation bar.
    func creamForm() -> some View {
        scrollContentBackground(.hidden)
            .background(Ink.eye.ignoresSafeArea())
            .tint(Color(hex: 0xC2541A))
            .fontDesign(.rounded)
            .environment(\.colorScheme, .light)
            .toolbarBackground(Ink.eye, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }

    /// One section's rows: white on the cream page.
    func creamSection() -> some View {
        listRowBackground(Color.white)
    }
}
