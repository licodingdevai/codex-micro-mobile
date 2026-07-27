import SwiftUI

struct OnboardingView: View {
  @Environment(DashboardStore.self) private var store
  @Environment(LocalNodeDiscovery.self) private var discovery
  @Binding var isComplete: Bool
  @State private var page = 0
  @State private var showingConnections = false

  private let pageCount = 4

  var body: some View {
    ZStack {
      CodexBackdrop(accent: CodexTheme.green)
        .ignoresSafeArea()

      VStack(spacing: 0) {
        header

        TabView(selection: $page) {
          WelcomeOnboardingPage().tag(0)
          ControlsOnboardingPage().tag(1)
          PairingOnboardingPage(
            isPaired: !store.profiles.isEmpty,
            nearbyCount: discovery.nodes.count,
            discoveryDetail: discovery.detail,
            openConnections: { showingConnections = true })
            .tag(2)
          ReadyOnboardingPage(isPaired: !store.profiles.isEmpty).tag(3)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))

        footer
      }
      .padding(.horizontal, 18)
      .padding(.top, 8)
      .padding(.bottom, 12)
    }
    .sheet(isPresented: $showingConnections) { SettingsView() }
    .onChange(of: store.profiles.count) { _, count in
      guard count > 0, page == 2 else { return }
      withAnimation(.snappy) { page = 3 }
    }
  }

  private var header: some View {
    HStack {
      HStack(spacing: 8) {
        Image("CodexMicroMark")
          .resizable()
          .scaledToFit()
          .frame(width: 30, height: 30)
          .accessibilityHidden(true)
        Text("Codex Micro")
          .font(.subheadline.weight(.semibold))
      }
      Spacer()
      Button("Skip") { isComplete = true }
        .font(.subheadline)
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
    .frame(height: 40)
  }

  private var footer: some View {
    VStack(spacing: 14) {
      HStack(spacing: 7) {
        ForEach(0..<pageCount, id: \.self) { index in
          Capsule()
            .fill(index == page ? CodexTheme.green : CodexTheme.secondary.opacity(0.28))
            .frame(width: index == page ? 22 : 7, height: 7)
        }
      }
      .animation(.snappy, value: page)

      HStack(spacing: 12) {
        if page > 0 {
          Button {
            withAnimation(.snappy) { page -= 1 }
          } label: {
            Image(systemName: "chevron.left")
              .frame(width: 44, height: 44)
              .contentShape(Circle())
              .codexGlassSurface(cornerRadius: 22, interactive: true)
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Previous")
        }

        Button {
          if page == pageCount - 1 {
            isComplete = true
          } else {
            withAnimation(.snappy) { page += 1 }
          }
        } label: {
          HStack {
            Text(page == pageCount - 1 ? "Start using Codex Micro" : "Continue")
            Spacer()
            Image(systemName: page == pageCount - 1 ? "checkmark" : "arrow.right")
          }
          .font(.headline)
          .padding(.horizontal, 18)
          .frame(height: 52)
          .frame(maxWidth: .infinity)
          .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
          .codexGlassSurface(
            cornerRadius: 26, tint: CodexTheme.green.opacity(0.28), interactive: true)
        }
        .buttonStyle(.plain)
      }
    }
  }
}

private struct WelcomeOnboardingPage: View {
  var body: some View {
    OnboardingPageLayout(
      eyebrow: "YOUR POCKET CONTROL SURFACE",
      title: "Control Codex without leaving your flow",
      detail:
        "Switch tasks, approve actions, tune reasoning and dictate from one compact surface."
    ) {
      OnboardingDevicePreview()
        .frame(maxWidth: 330)
    }
  }
}

private struct ControlsOnboardingPage: View {
  var body: some View {
    OnboardingPageLayout(
      eyebrow: "THE ESSENTIALS",
      title: "Every control has one clear job",
      detail: "The mobile layout mirrors the physical Codex Micro and uses the same native events."
    ) {
      VStack(spacing: 9) {
        KnobControlGuide()
        OnboardingFeatureRow(
          icon: "square.grid.2x2.fill", tint: CodexTheme.blue,
          title: "Agent keys", detail: "Open your six most relevant Codex tasks.")
        OnboardingFeatureRow(
          icon: "mic.fill", tint: CodexTheme.green,
          title: "Push to talk", detail: "Hold to dictate, or double-tap to keep recording.")
        OnboardingFeatureRow(
          icon: "checkmark.circle.fill", tint: CodexTheme.selection,
          title: "Command keys", detail: "Approve, reject, fork and send with native Codex actions.")
      }
      .frame(maxWidth: 390)
    }
  }
}

private struct PairingOnboardingPage: View {
  let isPaired: Bool
  let nearbyCount: Int
  let discoveryDetail: String
  let openConnections: () -> Void

  var body: some View {
    OnboardingPageLayout(
      eyebrow: "PAIR YOUR COMPUTER",
      title: isPaired ? "Your computer is ready" : "One secure scan, then it reconnects",
      detail: isPaired
        ? "The token is stored in Keychain and the computer certificate is pinned."
        : "Build the open-source bridge, keep both devices on the same private Wi‑Fi, then scan its private QR code."
    ) {
      VStack(spacing: 12) {
        pairingStatus
        VStack(spacing: 0) {
          PairingStep(
            number: 1, title: "Build the local bridge",
            detail: "Clone the public repository, install dependencies, and run the bridge build.")
          PairingStep(
            number: 2, title: "Create a pairing code",
            detail: "Run mobile-local-config to display your private QR code.")
          PairingStep(
            number: 3, title: "Scan with iPhone Camera",
            detail: "Tap “Open in Codex Micro” to finish securely.")
        }
        .codexGlassSurface(cornerRadius: 22)

        if !isPaired {
          Link(destination: ProjectDistribution.setupGuideURL) {
            Label("Open setup guide", systemImage: "book.pages")
              .padding(.horizontal, 16)
              .frame(height: 46)
              .frame(maxWidth: .infinity)
              .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
              .codexGlassSurface(
                cornerRadius: 23, tint: CodexTheme.blue.opacity(0.12), interactive: true)
          }
          .buttonStyle(.plain)
          .accessibilityHint("Opens the public source installation guide in Safari")
        }

        Button(action: openConnections) {
          Label(isPaired ? "View connection" : "I already built it", systemImage: "desktopcomputer")
            .padding(.horizontal, 16)
            .frame(height: 46)
            .frame(maxWidth: .infinity)
            .contentShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
            .codexGlassSurface(cornerRadius: 23, interactive: true)
        }
        .buttonStyle(.plain)
      }
      .frame(maxWidth: 390)
    }
  }

  private var pairingStatus: some View {
    HStack(spacing: 12) {
      Image(systemName: isPaired ? "checkmark.circle.fill" : "qrcode.viewfinder")
        .font(.title2)
        .foregroundStyle(isPaired ? CodexTheme.green : CodexTheme.blue)
      VStack(alignment: .leading, spacing: 2) {
        Text(isPaired ? "Paired securely" : nearbyCount > 0 ? "\(nearbyCount) nearby computer found" : "Waiting for pairing code")
          .font(.subheadline.weight(.semibold))
        Text(isPaired ? "Automatic reconnect is enabled" : discoveryDetail)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
      Spacer()
    }
    .padding(14)
    .codexGlassSurface(
      cornerRadius: 18,
      tint: (isPaired ? CodexTheme.green : CodexTheme.blue).opacity(0.1))
  }
}

private struct ReadyOnboardingPage: View {
  let isPaired: Bool

  var body: some View {
    OnboardingPageLayout(
      eyebrow: "READY TO BUILD",
      title: isPaired ? "Your live tasks will appear here" : "Explore now, pair whenever you are ready",
      detail: "This preview uses sample data. Your real task names and weekly capacity stay on your devices."
    ) {
      MockActivityPreview()
        .frame(maxWidth: 390)
    }
  }
}

private struct OnboardingPageLayout<Content: View>: View {
  let eyebrow: String
  let title: String
  let detail: String
  let content: Content

  init(
    eyebrow: String, title: String, detail: String,
    @ViewBuilder content: () -> Content
  ) {
    self.eyebrow = eyebrow
    self.title = title
    self.detail = detail
    self.content = content()
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        Spacer(minLength: 8)
        VStack(spacing: 9) {
          Text(eyebrow)
            .font(.caption2.weight(.bold))
            .tracking(1.3)
            .foregroundStyle(CodexTheme.green)
          Text(title)
            .font(.largeTitle.weight(.bold))
            .multilineTextAlignment(.center)
            .lineLimit(3)
          Text(detail)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineSpacing(3)
        }
        .frame(maxWidth: 430)

        content
        Spacer(minLength: 12)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
    }
    .scrollIndicators(.hidden)
  }
}

private struct OnboardingDevicePreview: View {
  private static let host = CodexHost(
    hostId: "onboarding-mac", hostName: "MacBook Pro", platform: .darwin)

  private static let agents: [(String, String, Bool, Double)] = [
    ("Build UI", "thinking", true, 34),
    ("Review PR", "complete", false, 18),
    ("Fix tests", "approval", false, 62),
    ("Ship app", "working", false, 47),
    ("Refactor", "idle", false, 12),
    ("Docs", "unread", false, 25),
  ]

  private var placements: [MobileAgentPlacement] {
    Self.agents.enumerated().map { index, item in
      let agent = RoutedAgent(
        id: index, threadKey: "onboarding:\(index)", title: item.0, status: item.1,
        selected: item.2, activityAt: Date.now.timeIntervalSince1970,
        host: Self.host, sourceSlot: index, originPlatform: .darwin,
        ownedByHost: true, contextUsedPercent: item.3)
      return MobileAgentPlacement(
        position: index, reference: AgentReference(agent: agent), agent: agent)
    }
  }

  var body: some View {
    CodexMicroDeviceView(
      presentation: .framed,
      placements: placements,
      demoMode: true,
      editKey: { _ in },
      showAgent: { _ in })
  }
}

private struct KnobControlGuide: View {
  var body: some View {
    VStack(spacing: 12) {
      HStack(spacing: 14) {
        OnboardingKnob()
        VStack(alignment: .leading, spacing: 3) {
          Text("Navigation knob")
            .font(.headline)
          Text("Move through composer controls, select an option, or open Micro settings.")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer(minLength: 0)
      }

      Divider()

      VStack(spacing: 8) {
        KnobActionRow(symbol: "rotate.right", title: "Turn right", detail: "Previous control or option")
        KnobActionRow(symbol: "rotate.left", title: "Turn left", detail: "Next control or option")
        KnobActionRow(symbol: "hand.tap.fill", title: "Click", detail: "Open or select highlighted")
        KnobActionRow(symbol: "hand.point.up.left.fill", title: "Press and hold", detail: "Open Codex Micro settings")
      }
    }
    .padding(14)
    .codexGlassSurface(cornerRadius: 20, tint: CodexTheme.orange.opacity(0.08))
  }
}

private struct OnboardingKnob: View {
  var body: some View {
    ZStack {
      Circle()
        .fill(
          AngularGradient(
            colors: [.white, .gray, .white, .gray, .white],
            center: .center))
      Circle()
        .stroke(CodexTheme.deviceBorder.opacity(0.65), lineWidth: 1)
        .padding(3)
      Capsule()
        .fill(Color.black.opacity(0.58))
        .frame(width: 8, height: 41)
        .offset(y: -3)
        .rotationEffect(.degrees(-45))
    }
    .frame(width: 64, height: 64)
    .accessibilityHidden(true)
  }
}

private struct KnobActionRow: View {
  let symbol: String
  let title: String
  let detail: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: symbol)
        .font(.caption)
        .foregroundStyle(CodexTheme.orange)
        .frame(width: 18)
      Text(title)
        .font(.caption.weight(.semibold))
        .frame(width: 92, alignment: .leading)
      Text(detail)
        .font(.caption)
        .foregroundStyle(.secondary)
      Spacer(minLength: 0)
    }
  }
}

private struct OnboardingFeatureRow: View {
  let icon: String
  let tint: Color
  let title: String
  let detail: String

  var body: some View {
    HStack(spacing: 13) {
      Image(systemName: icon)
        .font(.body.weight(.semibold))
        .foregroundStyle(tint)
        .frame(width: 36, height: 36)
        .background(tint.opacity(0.12), in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.subheadline.weight(.semibold))
        Text(detail).font(.caption).foregroundStyle(.secondary)
      }
      Spacer(minLength: 0)
    }
    .padding(13)
    .codexGlassSurface(cornerRadius: 18)
  }
}

private struct PairingStep: View {
  let number: Int
  let title: String
  let detail: String

  var body: some View {
    HStack(spacing: 12) {
      Text("\(number)")
        .font(.caption.weight(.bold))
        .foregroundStyle(.black)
        .frame(width: 26, height: 26)
        .background(CodexTheme.green, in: Circle())
      VStack(alignment: .leading, spacing: 2) {
        Text(title).font(.subheadline.weight(.semibold))
        Text(detail).font(.caption).foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 11)
  }
}

private struct MockActivityPreview: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Live activity", systemImage: "waveform.path.ecg")
        .font(.subheadline.weight(.semibold))

      HStack(spacing: 10) {
        Image(systemName: "bubble.left.fill").foregroundStyle(CodexTheme.blue)
        VStack(alignment: .leading, spacing: 2) {
          Text("Polish onboarding flow").font(.subheadline.weight(.medium))
          Text("MacBook Pro · Thinking").font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Circle().fill(CodexTheme.blue).frame(width: 7, height: 7)
      }

      Divider()
      HStack {
        Label("Weekly capacity", systemImage: "chart.bar.fill")
          .font(.caption.weight(.semibold))
        Spacer()
        Text("84%").font(.caption.weight(.semibold))
      }
      ProgressView(value: 0.84)
        .tint(CodexTheme.green)
    }
    .padding(16)
    .codexGlassSurface(cornerRadius: 22)
  }
}
