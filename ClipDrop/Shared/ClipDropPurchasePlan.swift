import KikiCommerceCore

enum ClipDropPurchasePlan: String, CaseIterable, Equatable, Hashable, Identifiable {
    case lifetime
    case supporterLifetime

    static let defaultSelection: Self = .lifetime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lifetime:
            return "Lifetime"
        case .supporterLifetime:
            return "Lifetime + Support"
        }
    }

    var fallbackDisplayPrice: String {
        switch self {
        case .lifetime:
            return "$6.99"
        case .supporterLifetime:
            return "$10.99"
        }
    }

    var billingDetail: String { "one-time purchase" }

    var badge: String? {
        switch self {
        case .lifetime:
            return "Default"
        case .supporterLifetime:
            return "Support Development"
        }
    }

    var subtitle: String {
        switch self {
        case .lifetime:
            return "All Clipboard Drop Pro features"
        case .supporterLifetime:
            return "Same Pro features, with extra support for development"
        }
    }

    var commercePlan: CommercePlan { CommercePlan(rawValue) }

    var kikiAccessPlan: KikiAccessPlan {
        KikiAccessPlan(
            id: id,
            commercePlan: commercePlan,
            title: title,
            fallbackDisplayPrice: fallbackDisplayPrice,
            billingDetail: billingDetail,
            subtitle: subtitle,
            badge: badge
        )
    }
}
