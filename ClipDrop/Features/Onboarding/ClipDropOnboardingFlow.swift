import AppKit
import KikiOnboarding
import SwiftUI

enum ClipDropOnboardingPhase: Int, CaseIterable, Equatable {
    case howToSend
    case receiverTips

    var progressIndex: Int { rawValue }
}

@MainActor
final class ClipDropOnboardingSession: ObservableObject {
    @Published private(set) var phase: ClipDropOnboardingPhase = .howToSend

    private let onFinish: @MainActor () -> Void
    private var didFinish = false

    init(onFinish: @escaping @MainActor () -> Void) {
        self.onFinish = onFinish
    }

    func advance() {
        switch phase {
        case .howToSend:
            phase = .receiverTips
        case .receiverTips:
            complete()
        }
    }

    func back() {
        guard phase == .receiverTips else { return }
        phase = .howToSend
    }

    func complete() {
        guard didFinish == false else { return }
        didFinish = true
        onFinish()
    }
}

enum ClipDropOnboardingFlow {
    static let windowSize = KikiOnboardingDefaults.windowSize

    @MainActor
    static func makeCoordinator(
        definition: ClipDropAppDefinition,
        completionStore: KikiOnboardingCompletionStore
    ) -> KikiOnboardingCoordinator {
        let flow = KikiOnboardingStep.custom(id: "clipdrop-guided-flow") { navigation in
            AnyView(
                ClipDropOnboardingFlowView(
                    config: definition.config,
                    onFinish: navigation.finish
                )
            )
        }

        return KikiOnboardingCoordinator(
            configuration: KikiOnboardingConfiguration(
                appName: definition.config.appName,
                steps: [flow],
                completionKey: definition.onboardingCompletionKey,
                canSkip: false,
                tint: ClipDropDesignToken.Colors.brand,
                windowAutosaveName: definition.onboardingWindowAutosaveName,
                windowTitle: "Welcome to Clipboard Drop",
                windowSize: windowSize,
                minimumWindowSize: windowSize,
                closeDisposition: .complete
            ),
            completionStore: completionStore
        )
    }
}

private struct ClipDropOnboardingFlowView: View {
    let config: ClipDropAppConfig
    @StateObject private var session: ClipDropOnboardingSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        config: ClipDropAppConfig,
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.config = config
        _session = StateObject(wrappedValue: ClipDropOnboardingSession(onFinish: onFinish))
    }

    var body: some View {
        ZStack {
            page
                .id(session.phase)
                .transition(pageTransition)
        }
        .animation(
            .easeInOut(duration: reduceMotion ? 0.16 : 0.28),
            value: session.phase
        )
    }

    private var page: some View {
        KikiOnboardingScaffold(
            appName: config.appName,
            title: title,
            bodyText: bodyText,
            appIcon: session.phase == .howToSend ? NSApp.applicationIconImage : nil,
            iconSystemName: "paperplane.fill",
            primaryAction: KikiOnboardingAction(
                title: primaryActionTitle,
                action: session.advance
            ),
            backAction: backAction,
            tint: ClipDropDesignToken.Colors.brand,
            size: ClipDropOnboardingFlow.windowSize,
            stepIndex: session.phase.progressIndex,
            stepCount: ClipDropOnboardingPhase.allCases.count
        ) {
            KikiOnboardingRowsContent(
                rows: rows,
                tint: ClipDropDesignToken.Colors.brand
            )
            .frame(maxWidth: 420)
        }
    }

    private var title: String {
        switch session.phase {
        case .howToSend:
            return "Send with AirDrop"
        case .receiverTips:
            return "Help the receiver accept AirDrop"
        }
    }

    private var bodyText: String {
        switch session.phase {
        case .howToSend:
            return "Copy text or a link, open Clipboard Drop from the menu bar, choose Send, then pick a device. The other person doesn’t need to install this app."
        case .receiverTips:
            return "A few AirDrop settings can help the other person receive your file."
        }
    }

    private var primaryActionTitle: String {
        switch session.phase {
        case .howToSend:
            return "Continue"
        case .receiverTips:
            return "Done"
        }
    }

    private var backAction: KikiOnboardingAction? {
        guard session.phase == .receiverTips else { return nil }
        return KikiOnboardingAction(title: "Back", action: session.back)
    }

    private var rows: [KikiOnboardingRow] {
        switch session.phase {
        case .howToSend:
            return [
                KikiOnboardingRow(
                    systemImage: "doc.on.clipboard",
                    title: "Copy text or a link",
                    detail: "Copy the content you want to send."
                ),
                KikiOnboardingRow(
                    systemImage: "menubar.rectangle",
                    title: "Open Clipboard Drop",
                    detail: "Choose Send from the menu bar app."
                ),
                KikiOnboardingRow(
                    systemImage: "airplayaudio",
                    title: "Pick a device",
                    detail: "The other person doesn’t need to install this app."
                )
            ]
        case .receiverTips:
            return [
                KikiOnboardingRow(
                    systemImage: "person.crop.circle.badge.questionmark",
                    title: "Everyone for 10 Minutes",
                    detail: "If the other person isn’t in Contacts, they can set AirDrop to Everyone for 10 Minutes."
                ),
                KikiOnboardingRow(
                    systemImage: "number.circle",
                    title: "AirDrop code",
                    detail: "On macOS and iOS 26.2 or later, they may need to enter the code shown on their screen."
                ),
                KikiOnboardingRow(
                    systemImage: "person.2",
                    title: "No shared Apple ID",
                    detail: "You don’t need to use the same Apple ID."
                )
            ]
        }
    }

    private var pageTransition: AnyTransition {
        guard reduceMotion == false else { return .opacity }
        return .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }
}
