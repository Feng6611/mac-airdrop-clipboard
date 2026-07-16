import Foundation
import KikiCommerceCore
import KikiRevenueCat

enum ClipDropRevenueCatConfiguration {
    static let trialDuration: TimeInterval = 2 * 24 * 60 * 60

    static let apiKeyInfoKey = "ClipDropRevenueCatAPIKey"
    static let entitlementIdentifier = "pro"
    static let offeringIdentifier = "default"
    static let lifetimeProductIdentifier = "dev.kkuk.clipboarddrop.pro.lifetime"
    static let supporterProductIdentifier = "dev.kkuk.clipboarddrop.pro.supporter"

    static var commerceConfiguration: CommerceConfiguration {
        CommerceConfiguration(
            entitlementIdentifier: entitlementIdentifier,
            productIdentifiers: [
                ClipDropPurchasePlan.lifetime.commercePlan: lifetimeProductIdentifier,
                ClipDropPurchasePlan.supporterLifetime.commercePlan: supporterProductIdentifier
            ],
            entitlementMatchingPolicy: .configuredEntitlementOrProductOnly,
            logSubsystem: Bundle.main.bundleIdentifier ?? "dev.kkuk.clipboarddrop",
            logCategory: "Purchase"
        )
    }

    static var revenueCatConfiguration: RevenueCatConfiguration {
        RevenueCatConfiguration.standardProFromInfoDictionary(
            apiKeyInfoDictionaryKey: apiKeyInfoKey,
            offeringIdentifier: offeringIdentifier
        )
    }

    static var accessConfiguration: KikiAccessConfiguration {
        KikiAccessConfiguration(
            plans: ClipDropPurchasePlan.allCases.map(\.kikiAccessPlan),
            defaultPlanID: ClipDropPurchasePlan.defaultSelection.id,
            commerceConfiguration: commerceConfiguration,
            trialPolicy: .explicitStart(duration: trialDuration),
            storageKeys: KikiAccessStorageKeys(
                trialStartedAt: "ClipDrop.Pro.trialStartedAt",
                debugProAccessOverride: "ClipDrop.Pro.debugProAccessOverride",
                usageCountPrefix: "ClipDrop.Pro.usage"
            )
        )
    }
}
