import SwiftUI

struct DashboardView: View {
  @Environment(DashboardStore.self) private var store
  @State private var resetConfirmation = false
  @State private var showingAllKeys = false
  @State private var editingKeySlot: DeviceKeySlot?
  @State private var portraitDrawerExpanded = true
  @State private var landscapeDrawerExpanded = false

  var body: some View {
    @Bindable var store = store
    let agents = store.agents
    let hasAttention = agents.contains(where: \.isAttention)
    GeometryReader { proxy in
      let isLandscape = proxy.size.width > proxy.size.height
      ZStack(alignment: .bottom) {
        CodexBackdrop(accent: hasAttention ? CodexTheme.orange : CodexTheme.green)
          .ignoresSafeArea()
        if store.profiles.isEmpty {
          pairingLayout(isLandscape: isLandscape)
        } else if isLandscape {
          landscapeDashboard(size: proxy.size)
        } else {
          portraitDashboard
        }

        if let toast = store.toast {
          Text(toast.message)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(toast.kind == .success ? CodexTheme.control : CodexTheme.red, in: Capsule())
            .padding(.bottom, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
    }
    .tint(CodexTheme.ink)
    .sheet(isPresented: $store.showingSettings) { SettingsView() }
    .sheet(isPresented: $store.showingAttentionCenter) { AttentionCenterView() }
    .sheet(isPresented: $showingAllKeys) { AllKeysView() }
    .sheet(item: $editingKeySlot) { KeycapPickerView(slot: $0) }
    .sheet(item: $store.presentedAgentReference) { reference in
      AgentDetailView(reference: reference)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(34)
        .presentationBackground(.clear)
    }
    .confirmationDialog(
      "Use one rate-limit reset?", isPresented: $resetConfirmation, titleVisibility: .visible
    ) {
      Button("Use reset", role: .destructive) { Task { await store.resetRateLimit() } }
    } message: {
      Text("This sends the same authenticated reset command as the Stream Deck button.")
    }
    .animation(.snappy, value: store.toast)
    .sensoryFeedback(.impact(weight: .medium), trigger: store.presentedAgentReference?.threadIdentity)
    .sensoryFeedback(.success, trigger: store.commandSuccessPulse)
    .sensoryFeedback(.error, trigger: store.commandErrorPulse)
  }

  private var portraitDashboard: some View {
    ScrollView {
      LazyVStack(spacing: 10) {
        DashboardTopBar()
        microDevice(presentation: .framed)
        InformationDrawer(
          isLandscape: false,
          isExpanded: $portraitDrawerExpanded,
          resetConfirmation: $resetConfirmation,
          showAllKeys: { showingAllKeys = true })
        Color.clear.frame(height: 8)
      }
      .padding(.horizontal, 12)
      .padding(.top, 6)
    }
    .scrollIndicators(.hidden)
    .defaultScrollAnchor(.top)
  }

  private func landscapeDashboard(size: CGSize) -> some View {
    let side = min(size.height, size.width)
    return ZStack {
      microDevice(presentation: .bezelFree)
        .frame(width: side, height: side)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      VStack {
        DashboardTopBar(landscape: true)
        Spacer()
      }
      .padding(.horizontal, 12)
      .padding(.top, 6)

      HStack {
        Spacer()
        InformationDrawer(
          isLandscape: true,
          isExpanded: $landscapeDrawerExpanded,
          resetConfirmation: $resetConfirmation,
          showAllKeys: { showingAllKeys = true })
          .frame(
            width: landscapeDrawerExpanded
              ? min(330, size.width * 0.42) : 48)
          .frame(maxHeight: max(190, size.height - 64))
      }
      .padding(.trailing, 10)
      .padding(.top, 50)
      .padding(.bottom, 8)
    }
  }

  private func pairingLayout(isLandscape: Bool) -> some View {
    VStack(spacing: 16) {
      DashboardTopBar(landscape: isLandscape)
      PairingWelcome().frame(maxWidth: 480)
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.top, 6)
  }

  private func microDevice(presentation: CodexMicroPresentation) -> some View {
    CodexMicroDeviceView(
      presentation: presentation,
      placements: store.mobileAgentPlacements,
      editKey: { editingKeySlot = $0 },
      showAgent: { store.presentAgent($0) })
  }
}

private struct DashboardTopBar: View {
  @Environment(DashboardStore.self) private var store
  var landscape = false

  var body: some View {
    CodexGlassGroup(spacing: 9) {
      HStack(spacing: 9) {
        ConnectionCapsule()
        Spacer(minLength: 8)
        settingsButton
      }
      .frame(maxWidth: .infinity)
    }
    .foregroundStyle(CodexTheme.ink)
  }

  @ViewBuilder
  private var settingsButton: some View {
    if #available(iOS 26.0, *) {
      Button {
        store.showingSettings = true
      } label: {
        Image(systemName: "gearshape.fill")
          .font(.subheadline.weight(.semibold))
          .frame(width: 36, height: 36)
      }
      .buttonStyle(.plain)
      .glassEffect(.regular.interactive(), in: .circle)
      .accessibilityLabel("Connection settings")
    } else {
      Button {
        store.showingSettings = true
      } label: {
        Image(systemName: "gearshape.fill")
          .font(.subheadline.weight(.semibold))
          .frame(width: 36, height: 36)
          .background(.ultraThinMaterial, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Connection settings")
    }
  }
}

private struct ConnectionCapsule: View {
  @Environment(DashboardStore.self) private var store

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        capsuleContent
          .glassEffect(.regular, in: .capsule)
      } else {
        capsuleContent
          .background(.ultraThinMaterial, in: Capsule())
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      "\(store.connectedCount) of \(store.expectedCount) computers connected")
  }

  private var capsuleContent: some View {
    HStack(spacing: 7) {
      Circle()
        .fill(connectionColor)
        .frame(width: 7, height: 7)
      Text("\(store.connectedCount)/\(store.expectedCount)")
        .font(.caption.weight(.semibold))
    }
    .padding(.horizontal, 11)
    .frame(height: 36)
  }

  private var connectionColor: Color {
    let ready = store.connectedCount
    if ready == store.expectedCount && ready > 0 { return CodexTheme.green }
    if ready > 0 { return CodexTheme.orange }
    return CodexTheme.red
  }
}

private struct InformationDrawer: View {
  @AppStorage(CodexAppearance.darkModeKey) private var darkAppearance = true
  @Namespace private var glassNamespace
  let isLandscape: Bool
  @Binding var isExpanded: Bool
  @Binding var resetConfirmation: Bool
  let showAllKeys: () -> Void

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        GlassEffectContainer(spacing: 12) {
          if isExpanded {
            expandedPanel
              .glassEffect(.regular, in: .rect(cornerRadius: 18))
              .glassEffectID("information-drawer", in: glassNamespace)
          } else {
            collapsedHandle
              .glassEffectID("information-drawer", in: glassNamespace)
          }
        }
      } else if isExpanded {
        expandedPanel
          .codexGlassSurface(cornerRadius: 27)
      } else {
        collapsedHandle
          .codexGlassSurface(cornerRadius: 24, interactive: true)
      }
    }
    .animation(.snappy(duration: 0.42, extraBounce: 0.08), value: isExpanded)
  }

  private var expandedPanel: some View {
    VStack(spacing: 8) {
      HStack {
        Label("Activity", systemImage: "waveform.path.ecg")
          .font(.subheadline.weight(.semibold))
        Spacer()
        appearanceToggle
        collapseButton
      }

      DrawerActions(showAllKeys: showAllKeys)
      Divider()

      if isLandscape {
        ScrollView { drawerSections }
          .scrollIndicators(.hidden)
      } else {
        drawerSections
      }
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .top)
  }

  private var appearanceToggle: some View {
    Toggle(isOn: $darkAppearance) {
      Image(systemName: darkAppearance ? "moon.fill" : "sun.max.fill")
        .font(.caption.weight(.semibold))
        .frame(width: 16)
    }
    .toggleStyle(.switch)
    .tint(CodexTheme.green)
    .controlSize(.mini)
    .fixedSize()
    .accessibilityLabel("Dark appearance")
  }

  @ViewBuilder
  private var collapseButton: some View {
    if #available(iOS 26.0, *) {
      Button {
        withAnimation(.snappy) { isExpanded = false }
      } label: {
        Image(systemName: isLandscape ? "chevron.right" : "chevron.down")
          .font(.caption.weight(.bold))
          .frame(width: 32, height: 32)
      }
      .buttonStyle(.plain)
      .glassEffect(.regular.interactive(), in: .circle)
      .accessibilityLabel("Collapse activity panel")
    } else {
      Button {
        withAnimation(.snappy) { isExpanded = false }
      } label: {
        Image(systemName: isLandscape ? "chevron.right" : "chevron.down")
          .font(.caption.weight(.bold))
          .frame(width: 32, height: 32)
          .background(.ultraThinMaterial, in: Circle())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Collapse activity panel")
    }
  }

  @ViewBuilder
  private var collapsedHandle: some View {
    if #available(iOS 26.0, *) {
      Button {
        withAnimation(.snappy) { isExpanded = true }
      } label: {
        Image(systemName: isLandscape ? "chevron.left" : "chevron.up")
          .font(.subheadline.weight(.semibold))
          .frame(width: isLandscape ? 42 : 64, height: isLandscape ? 58 : 42)
      }
      .buttonStyle(.plain)
      .glassEffect(.regular.interactive(), in: .capsule)
      .accessibilityLabel("Show selected chats and account capacity")
    } else {
      Button {
        withAnimation(.snappy) { isExpanded = true }
      } label: {
        Image(systemName: isLandscape ? "chevron.left" : "chevron.up")
          .font(.subheadline.weight(.semibold))
          .frame(width: isLandscape ? 42 : 64, height: isLandscape ? 58 : 42)
          .background(.ultraThinMaterial, in: Capsule())
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Show selected chats and account capacity")
    }
  }

  private var drawerSections: some View {
    NativeActivityContent(resetConfirmation: $resetConfirmation)
  }
}

private struct NativeActivityContent: View {
  @Environment(DashboardStore.self) private var store
  @Binding var resetConfirmation: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 7) {
      Label("Selected Chats", systemImage: "bubble.left.and.bubble.right")
        .font(.caption2.weight(.semibold))
        .foregroundStyle(.secondary)

      if store.activeChats.isEmpty {
        Label("No selected chat", systemImage: "bubble.left")
          .font(.caption)
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
      } else {
        ForEach(store.activeChats) { chat in
          HStack(spacing: 8) {
            Image(systemName: "bubble.left.fill")
              .font(.caption2)
              .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
              Text(chat.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)
              Text(chat.host.hostName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Circle()
              .fill(CodexTheme.statusColor(chat.status))
              .frame(width: 6, height: 6)
              .accessibilityLabel(chat.status)
          }
          .frame(minHeight: 30)
        }
      }

      Divider()
      weeklyCapacity
    }
    .padding(.horizontal, 2)
  }

  private var weeklyCapacity: some View {
    let usage = store.usageSource?.snapshot.usage
    let weekly = usage?.windows.first(where: { $0.kind == "weekly" })
    let remaining = weekly?.remainingPercent
    let fraction = min(max((remaining ?? 0) / 100, 0), 1)
    let resets = usage?.resetCreditsAvailable ?? 0
    let resetAvailable = resets > 0 && usage?.resetCreditsApplicable != 0

    return VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 8) {
        Label("Weekly Capacity", systemImage: "chart.bar.fill")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(.secondary)
        Spacer()
        Text(freshness(usage?.observedAt))
          .font(.caption2)
          .foregroundStyle(.tertiary)
      }

      LabeledContent("Remaining") {
        Text(remaining.map { "\(Int($0.rounded()))%" } ?? "—")
          .font(.caption.weight(.semibold))
      }
      .font(.caption)

      ProgressView(value: fraction)
        .tint(capacityColor(remaining))
        .controlSize(.small)
        .accessibilityLabel("Weekly remaining")
        .accessibilityValue(
          remaining.map { "\(Int($0.rounded())) percent" } ?? "Unavailable")

      HStack {
        Label("\(resets) resets", systemImage: "arrow.counterclockwise")
          .font(.caption2)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Use") { resetConfirmation = true }
          .buttonStyle(.borderless)
          .controlSize(.small)
          .disabled(!resetAvailable)
      }
    }
  }

  private func freshness(_ timestamp: Double?) -> String {
    guard let timestamp else { return "Waiting" }
    return Date(timeIntervalSince1970: timestamp / 1_000)
      .formatted(.relative(presentation: .numeric))
  }

  private func capacityColor(_ value: Double?) -> Color {
    guard let value else { return .secondary }
    return value < 20 ? CodexTheme.red : value < 40 ? CodexTheme.orange : CodexTheme.green
  }
}

private struct DrawerActions: View {
  @Environment(DashboardStore.self) private var store
  let showAllKeys: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      HeaderHostMenu()
      Spacer()

      Button {
        store.showingAttentionCenter = true
      } label: {
        Image(systemName: store.unreadAttentionCount > 0 ? "bell.fill" : "bell")
      }
      .accessibilityLabel("Attention")

      Button(action: showAllKeys) {
        Image(systemName: "square.grid.3x3.fill")
      }
      .accessibilityLabel("All Codex Keys")
    }
    .buttonStyle(.borderless)
    .controlSize(.small)
    .font(.subheadline)
  }
}

private struct HeaderView: View {
  @Environment(DashboardStore.self) private var store
  let showAllKeys: () -> Void

  var body: some View {
    HStack(spacing: 7) {
      Spacer()
      ConnectionLight()
      HeaderHostMenu()
      if #available(iOS 26.0, *) {
        GlassEffectContainer(spacing: 8) {
          HeaderGlassActions(showAllKeys: showAllKeys)
        }
        .overlay(alignment: .topLeading) { AttentionBadge() }
      } else {
        HeaderGlassActions(showAllKeys: showAllKeys)
          .overlay(alignment: .topLeading) { AttentionBadge() }
      }
    }
    .foregroundStyle(CodexTheme.ink)
  }
}

private struct HeaderGlassActions: View {
  @Environment(DashboardStore.self) private var store
  let showAllKeys: () -> Void

  var body: some View {
    HStack(spacing: 7) {
      Button {
        store.showingAttentionCenter = true
      } label: {
        Image(systemName: store.unreadAttentionCount > 0 ? "bell.fill" : "bell")
          .font(.system(size: 15, weight: .semibold))
          .frame(width: 36, height: 36)
          .codexGlassSurface(
            cornerRadius: 18,
            tint: store.unreadAttentionCount > 0 ? CodexTheme.orange.opacity(0.12) : nil,
            interactive: true)
      }
      .buttonStyle(.plain)
      .accessibilityLabel(
        store.unreadAttentionCount == 0
          ? "Attention center" : "Attention center, \(store.unreadAttentionCount) unread")
      Button(action: showAllKeys) {
        Image(systemName: "square.grid.3x3.fill")
          .font(.system(size: 15, weight: .semibold))
          .frame(width: 36, height: 36)
          .codexGlassSurface(cornerRadius: 18, interactive: true)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("All Codex keys")
      Button {
        store.showingSettings = true
      } label: {
        Image(systemName: "gearshape.fill")
          .font(.system(size: 16, weight: .semibold))
          .frame(width: 36, height: 36)
          .codexGlassSurface(cornerRadius: 18, interactive: true)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Connection settings")
    }
  }
}

private struct AttentionBadge: View {
  @Environment(DashboardStore.self) private var store

  var body: some View {
    if store.unreadAttentionCount > 0 {
      Text(store.unreadAttentionCount > 9 ? "9+" : "\(store.unreadAttentionCount)")
        .font(.caption2.weight(.bold))
        .foregroundStyle(.white)
        .padding(.horizontal, 4)
        .frame(minWidth: 15, minHeight: 15)
        .background(CodexTheme.red, in: Capsule())
        .offset(x: 25, y: -3)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .zIndex(100)
    }
  }
}

private struct ConnectionLight: View {
  @Environment(DashboardStore.self) private var store

  var body: some View {
    let ready = store.connectedCount
    Circle()
      .fill(
        ready == store.expectedCount && ready > 0
          ? CodexTheme.green : ready > 0 ? CodexTheme.orange : CodexTheme.red
      )
      .frame(width: 11, height: 11)
      .accessibilityLabel("\(ready) of \(store.expectedCount) computers connected")
  }
}

private struct HeaderHostMenu: View {
  @Environment(DashboardStore.self) private var store

  var body: some View {
    let hosts = Dictionary(grouping: store.nodes.values.compactMap(\.host), by: \.hostId)
      .compactMap { $0.value.first }
      .sorted { $0.platform.rawValue < $1.platform.rawValue }
    Menu {
      ForEach(hosts, id: \.hostId) { host in
        Button {
          store.selectHost(host)
        } label: {
          Label(
            host.hostName,
            systemImage: store.selectedHost?.hostId == host.hostId ? "checkmark.circle.fill" : "circle")
        }
      }
    } label: {
      Label(
        store.selectedHost?.platform.displayName ?? "Computer",
        systemImage: "desktopcomputer")
    }
    .accessibilityLabel("Control computer")
  }
}

private struct PairingWelcome: View {
  @Environment(DashboardStore.self) private var store

  var body: some View {
    VStack(spacing: 18) {
      Image(systemName: "iphone.and.arrow.forward")
        .font(.system(size: 44, weight: .light))
      Text("Bring Codex Micro with you")
        .font(.title2.bold())
      Text(
        "Pair your Mac or Windows computer over nearby Wi-Fi, then add Tailscale when you want secure access away from home. Chrome DevTools never leaves the computer."
      )
      .font(.subheadline)
      .foregroundStyle(CodexTheme.secondary)
      .multilineTextAlignment(.center)
      .lineSpacing(3)
      Button("Pair first computer") { store.showingSettings = true }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }
    .padding(28)
    .frame(maxWidth: .infinity)
    .codexGlassSurface(cornerRadius: 30, tint: .white.opacity(0.08))
  }
}

private struct AgentGrid: View {
  @Environment(DashboardStore.self) private var store
  private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

  var body: some View {
    VStack(spacing: 12) {
      SectionLabel("Live agents", detail: "Newest across Mac + Windows")
      LazyVGrid(columns: columns, spacing: 12) {
        ForEach(0..<6, id: \.self) { index in
          if let agent = store.agents.first(where: { $0.id == index }) {
            AgentCard(agent: agent)
          } else {
            EmptyAgentCard(index: index)
          }
        }
      }
    }
  }
}

private struct AgentCard: View {
  @Environment(DashboardStore.self) private var store
  let agent: RoutedAgent

  var body: some View {
    let hostState = store.connectionState(for: agent.host.hostId)
    Button {
      Task { await store.activate(agent) }
    } label: {
      VStack(alignment: .leading, spacing: 13) {
        HStack {
          ZStack {
            Circle().fill(CodexTheme.statusColor(agent.status).opacity(0.15)).frame(
              width: 34, height: 34)
            Image(systemName: statusSymbol).font(.system(size: 15, weight: .bold))
          }
          Spacer()
          Text(agent.originPlatform.shortLabel)
            .font(.caption2.weight(.black))
            .frame(width: 23, height: 23)
            .background(hostState == .ready ? CodexTheme.control : CodexTheme.red, in: Circle())
            .foregroundStyle(.white)
        }
        Text(agent.title)
          .font(.subheadline.weight(.semibold))
          .lineLimit(2)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)
        HStack(spacing: 6) {
          Circle().fill(CodexTheme.statusColor(agent.status)).frame(width: 7, height: 7)
          Text(hostState == .offline ? "OFFLINE" : statusTitle)
            .font(.caption2.weight(.bold)).foregroundStyle(
              hostState == .offline ? CodexTheme.red : CodexTheme.secondary
            )
          Spacer()
          if agent.originPlatform != agent.host.platform {
            Text("VIA \(agent.host.platform.shortLabel)")
              .font(.system(size: 7, weight: .black))
              .foregroundStyle(CodexTheme.secondary)
          }
          if agent.selected { Image(systemName: "viewfinder").font(.caption2) }
        }
      }
      .padding(15)
      .frame(minHeight: 150)
      .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay(alignment: .leading) {
        if agent.isAttention {
          Capsule().fill(CodexTheme.statusColor(agent.status)).frame(width: 4).padding(
            .vertical, 18)
        }
      }
    }
    .buttonStyle(.plain)
    .disabled(hostState == .offline || hostState == .connecting)
    .opacity(hostState == .offline || hostState == .connecting ? 0.68 : 1)
    .accessibilityHint("Opens this task on \(agent.host.hostName)")
  }

  private var statusSymbol: String {
    if ["working", "thinking"].contains(agent.status) { return "sparkles" }
    if ["approval", "awaiting-approval", "awaiting-response"].contains(agent.status) {
      return "hand.raised.fill"
    }
    if agent.status == "error" { return "exclamationmark" }
    if ["unread", "complete", "completed", "done"].contains(agent.status) { return "checkmark" }
    return "circle.fill"
  }

  private var statusTitle: String {
    agent.status.replacingOccurrences(of: "-", with: " ").uppercased()
  }
}

private struct EmptyAgentCard: View {
  let index: Int
  var body: some View {
    VStack(spacing: 10) {
      Image(systemName: "plus").font(.title3.weight(.semibold))
      Text("SLOT \(index + 1)").font(.caption2.bold()).tracking(1)
    }
    .foregroundStyle(CodexTheme.secondary.opacity(0.6))
    .frame(maxWidth: .infinity, minHeight: 150)
    .background(.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
  }
}

private struct MicroConsole: View {
  @Environment(DashboardStore.self) private var store

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        SectionLabel("Micro console")
        Spacer()
        HostPicker()
      }
      VStack(spacing: 13) {
        HStack(spacing: 12) {
          ConsoleButton(title: "Fast", symbol: "bolt.fill") { await store.pressAction("ACT06") }
          ConsoleButton(title: "Approve", symbol: "checkmark.circle") {
            await store.pressAction("ACT07")
          }
          ConsoleButton(title: "Decline", symbol: "xmark.circle") {
            await store.pressAction("ACT08")
          }
          ConsoleButton(title: "Fork", symbol: "arrow.triangle.branch") {
            await store.pressAction("ACT09")
          }
        }
        HStack(spacing: 12) {
          ConsoleButton(title: "Back", symbol: "chevron.left") { await store.pressJoystick("left") }
          ConsoleButton(title: "Plan", symbol: "list.bullet.clipboard") {
            await store.pressJoystick("up")
          }
          ConsoleButton(title: "New", symbol: "plus.bubble") {
            await store.trigger(.keycap(id: "NEW"))
          }
          ConsoleButton(title: "Send", symbol: "arrow.up.circle.fill") {
            await store.pressAction("ACT12")
          }
        }
        HStack(spacing: 12) {
          Button {
            Task { await store.trigger(.reasoning(direction: "decrease")) }
          } label: {
            Image(systemName: "minus").font(.title3.bold())
          }.buttonStyle(HardwareKeyStyle())
          VStack(spacing: 3) {
            Image(systemName: "brain.head.profile").font(.title2)
            Text("REASONING").font(.system(size: 8, weight: .bold)).tracking(1)
          }
          .frame(maxWidth: .infinity, minHeight: 62)
          Button {
            Task { await store.trigger(.reasoning(direction: "increase")) }
          } label: {
            Image(systemName: "plus").font(.title3.bold())
          }.buttonStyle(HardwareKeyStyle())
        }
      }
      .padding(16)
      .background(CodexTheme.panel, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(
          .white.opacity(0.8), lineWidth: 2))
      Text("LET’S BUILD")
        .font(.system(size: 8, weight: .bold)).tracking(2)
        .foregroundStyle(CodexTheme.secondary)
    }
  }
}

private struct ConsoleButton: View {
  let title: String
  let symbol: String
  let action: () async -> Void

  var body: some View {
    Button {
      Task { await action() }
    } label: {
      VStack(spacing: 5) {
        Image(systemName: symbol).font(.system(size: 19, weight: .semibold))
        Text(title.uppercased()).font(.system(size: 7, weight: .bold)).lineLimit(1)
      }
    }
    .buttonStyle(HardwareKeyStyle())
  }
}

private struct HostPicker: View {
  @Environment(DashboardStore.self) private var store
  var body: some View {
    HStack(spacing: 4) {
      ForEach(store.nodes.values.compactMap(\.host).uniqued(), id: \.hostId) { host in
        Button(host.platform.shortLabel) { store.selectHost(host) }
          .font(.caption2.weight(.black))
          .frame(width: 28, height: 28)
          .background(
            store.selectedHost?.hostId == host.hostId ? CodexTheme.control : CodexTheme.key,
            in: Circle()
          )
          .foregroundStyle(store.selectedHost?.hostId == host.hostId ? .white : CodexTheme.ink)
          .accessibilityLabel("Control \(host.platform.displayName)")
      }
    }
  }
}

extension Array where Element == CodexHost {
  fileprivate func uniqued() -> [CodexHost] {
    var seen = Set<String>()
    return filter { seen.insert($0.hostId).inserted }
  }
}

#Preview("Dual host dashboard") {
  DashboardView()
    .environment(DashboardStore(defaults: UserDefaults(suiteName: "preview-dashboard")!))
}
