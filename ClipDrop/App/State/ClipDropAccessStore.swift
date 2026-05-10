import Foundation

@MainActor
protocol ClipDropAccessProviding: AnyObject {
    var snapshot: ClipDropAccessSnapshot { get }
    var isSendingAllowed: Bool { get }
}

@MainActor
final class ClipDropAccessStore: ObservableObject, ClipDropAccessProviding {
    @Published private(set) var tier: ClipDropAccessTier
    @Published private(set) var updatedAt: Date?

    init(tier: ClipDropAccessTier = .unrestrictedStub) {
        self.tier = tier
    }

    var snapshot: ClipDropAccessSnapshot {
        ClipDropAccessSnapshot(tier: tier)
    }

    var isSendingAllowed: Bool {
        true
    }

    func refresh() {
        updatedAt = Date()
    }
}
