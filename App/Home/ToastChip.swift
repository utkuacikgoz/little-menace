import SwiftUI
import MenaceCore

struct ToastChip: View {
    let toast: Toast
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.symbol).font(.title3.weight(.bold))
            if let text = toast.text {
                Text(text).font(.system(.headline, design: .rounded).weight(.heavy))
            }
        }
        .foregroundStyle(Ink.body)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Ink.eye, in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .accessibilityHidden(true)
    }
}
