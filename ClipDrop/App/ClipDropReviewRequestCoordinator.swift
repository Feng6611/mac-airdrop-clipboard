import Foundation
import KikiReview

@MainActor
final class ClipDropReviewRequestCoordinator {
    static let successfulSendCountKey = "ClipDrop.Review.successfulSendCount"

    private let defaults: UserDefaults
    private let policy: KikiReviewRequestPolicy
    private let requestSystemReview: () -> Void

    init(
        defaults: UserDefaults = .standard,
        appVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "",
        now: @escaping () -> Date = Date.init,
        requestSystemReview: (() -> Void)? = nil
    ) {
        self.defaults = defaults
        self.policy = KikiReviewRequestPolicy(
            rules: .recommended(minimumQualifyingEvents: 3),
            defaults: defaults,
            keys: .prefixed("ClipDrop.Review"),
            appVersion: appVersion,
            now: now
        )
        self.requestSystemReview = requestSystemReview ?? {
            KikiSystemReviewRequest.request()
        }
    }

    var successfulSendCount: Int {
        defaults.integer(forKey: Self.successfulSendCountKey)
    }

    func recordSuccessfulSend() {
        defaults.set(successfulSendCount + 1, forKey: Self.successfulSendCountKey)
    }

    /// Called when the user opens the menu-bar popover, a natural pause after
    /// previous sends rather than immediately after the AirDrop action.
    @discardableResult
    func requestIfEligibleAtNaturalMoment() -> Bool {
        policy.requestIfEligible(qualifyingEvents: successfulSendCount, request: requestSystemReview)
    }
}
