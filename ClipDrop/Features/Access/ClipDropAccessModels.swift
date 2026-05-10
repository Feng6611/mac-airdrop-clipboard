import Foundation

enum ClipDropAccessTier: Equatable {
    case unrestrictedStub

    var status: String {
        switch self {
        case .unrestrictedStub:
            return "Unrestricted"
        }
    }

    var detail: String {
        switch self {
        case .unrestrictedStub:
            return "Purchase logic is intentionally a replaceable stub in V1."
        }
    }
}

struct ClipDropAccessSnapshot: Equatable {
    let tier: ClipDropAccessTier

    var accountStatus: String {
        tier.status
    }

    var detail: String {
        tier.detail
    }
}
