import KikiPaywall
import SwiftUI

struct ClipDropAccessView: View {
    let snapshot: ClipDropAccessSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KikiPaywallFeatureRow(icon: "lock.open", text: snapshot.accountStatus)
            Text(snapshot.detail)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
