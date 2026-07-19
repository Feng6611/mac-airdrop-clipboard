import AppKit
import KikiCommerceCore
import KikiOnboarding
import SwiftUI

enum ClipDropOnboardingPhase: Int, CaseIterable, Equatable {
    case welcome
    case workflow

    var progressIndex: Int { rawValue }
}

@MainActor
final class ClipDropOnboardingSession: ObservableObject {
    @Published private(set) var phase: ClipDropOnboardingPhase = .welcome
    @Published var isPaywallPresented = false

    private let onFinish: @MainActor () -> Void
    private var didFinish = false

    init(onFinish: @escaping @MainActor () -> Void) {
        self.onFinish = onFinish
    }

    func advance() {
        switch phase {
        case .welcome:
            phase = .workflow
        case .workflow:
            isPaywallPresented = true
        }
    }

    func back() {
        guard phase == .workflow else { return }
        phase = .welcome
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
        accessManager: KikiAccessManager,
        completionStore: KikiOnboardingCompletionStore
    ) -> KikiOnboardingCoordinator {
        let flow = KikiOnboardingStep.custom(id: "clipdrop-guided-flow") { navigation in
            AnyView(
                ClipDropOnboardingFlowView(
                    config: definition.config,
                    accessManager: accessManager,
                    onFinish: navigation.finish
                )
            )
        }

        return KikiOnboardingCoordinator(
            configuration: KikiOnboardingConfiguration(
                appName: definition.config.appName,
                steps: [flow],
                completionKey: definition.onboardingCompletionKey,
                canSkip: true,
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
    @ObservedObject var accessManager: KikiAccessManager
    @StateObject private var session: ClipDropOnboardingSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        config: ClipDropAppConfig,
        accessManager: KikiAccessManager,
        onFinish: @escaping @MainActor () -> Void
    ) {
        self.config = config
        self.accessManager = accessManager
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
        .sheet(
            isPresented: $session.isPaywallPresented,
            onDismiss: session.complete
        ) {
            ClipDropPaywallSheetView(
                accessManager: accessManager,
                context: .onboarding,
                config: config,
                onFinish: session.complete
            )
        }
    }

    private var page: some View {
        KikiOnboardingScaffold(
            appName: config.appName,
            title: title,
            bodyText: bodyText,
            appIcon: session.phase == .welcome ? NSApp.applicationIconImage : nil,
            iconSystemName: "paperplane.fill",
            primaryAction: KikiOnboardingAction(
                title: primaryActionTitle,
                action: session.advance
            ),
            backAction: backAction,
            skipAction: KikiOnboardingAction(
                title: "Skip",
                action: session.complete
            ),
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
        case .welcome:
            return "Send copied text and links with AirDrop"
        case .workflow:
            return "Copy. Send. Done."
        }
    }

    private var bodyText: String {
        switch session.phase {
        case .welcome:
            return "Clipboard Drop turns copied text and links into lightweight files ready to send with AirDrop."
        case .workflow:
            return "Your latest clipboard item is always ready from the menu bar—no receiver app, account, or cloud sync required."
        }
    }

    private var primaryActionTitle: String {
        switch session.phase {
        case .welcome:
            return "See How It Works"
        case .workflow:
            return "View Pro Options"
        }
    }

    private var backAction: KikiOnboardingAction? {
        guard session.phase == .workflow else { return nil }
        return KikiOnboardingAction(title: "Back", action: session.back)
    }

    private var rows: [KikiOnboardingRow] {
        switch session.phase {
        case .welcome:
            return [
                KikiOnboardingRow(
                    systemImage: "menubar.rectangle",
                    title: "Always in the menu bar",
                    detail: "Open your latest copied text or link without switching apps."
                ),
                KikiOnboardingRow(
                    systemImage: "airplayaudio",
                    title: "No receiver app",
                    detail: "Send to any nearby Mac, iPhone, or iPad that accepts AirDrop."
                ),
                KikiOnboardingRow(
                    systemImage: "hand.raised.fill",
                    title: "Local by design",
                    detail: "Recent items stay in memory and disappear when you quit."
                )
            ]
        case .workflow:
            return [
                KikiOnboardingRow(
                    systemImage: "1.circle.fill",
                    title: "Copy text or a link",
                    detail: "Clipboard Drop notices supported clipboard content automatically."
                ),
                KikiOnboardingRow(
                    systemImage: "2.circle.fill",
                    title: "Open Clipboard Drop",
                    detail: "Choose the current item or anything recent from the menu bar."
                ),
                KikiOnboardingRow(
                    systemImage: "3.circle.fill",
                    title: "Send with AirDrop",
                    detail: "Pick a nearby device in the standard macOS AirDrop picker."
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
