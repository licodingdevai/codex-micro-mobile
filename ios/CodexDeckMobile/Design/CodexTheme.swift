import SwiftUI
import UIKit

enum CodexAppearance {
  static let darkModeKey = "codex-dark-appearance"
  static let onboardingCompleteKey = "codex-onboarding-complete-v1"
}

enum CodexTheme {
  static let canvas = adaptive(light: 0xF4F5F2, dark: 0x050607)
  static let backgroundTop = adaptive(light: 0xFFFFFF, dark: 0x0B0D10)
  static let aluminum = adaptive(light: 0xDFE2DF, dark: 0x171A1E)
  static let panel = adaptive(light: 0xE2E4E2, dark: 0x0F1215)
  static let key = adaptive(light: 0xFBFCFA, dark: 0x20242A)
  static let agentKey = adaptive(light: 0xFFFFFF, dark: 0x171B20).opacity(0.72)
  static let ink = adaptive(light: 0x131413, dark: 0xF3F5F7)
  static let secondary = adaptive(light: 0x646866, dark: 0x9CA3AA)
  static let control = Color(red: 0.075, green: 0.085, blue: 0.10)
  static let deviceShell = adaptive(light: 0xF9FAF8, dark: 0x111419)
  static let deviceShellSecondary = adaptive(light: 0xEEF1EE, dark: 0x090B0E)
  static let devicePlateTop = adaptive(light: 0xF8F9F7, dark: 0x171B20)
  static let deviceBorder = adaptive(light: 0xFFFFFF, dark: 0x343A42)
  static let keyBorder = adaptive(light: 0xFFFFFF, dark: 0x48505A)
  static let keyHighlight = adaptive(light: 0xFFFFFF, dark: 0x76808C)
  static let keyGlassTint = adaptive(light: 0xFFFFFF, dark: 0x11151A)
  static let green = Color(red: 0.18, green: 0.83, blue: 0.44)
  static let blue = Color(red: 0.13, green: 0.53, blue: 0.98)
  static let selection = Color(red: 0.26, green: 0.89, blue: 0.76)
  static let orange = Color(red: 1.0, green: 0.61, blue: 0.13)
  static let red = Color(red: 1.0, green: 0.27, blue: 0.36)

  static func statusColor(_ status: String) -> Color {
    if ["working", "thinking"].contains(status) { return blue }
    if ["approval", "awaiting-approval", "awaiting-response"].contains(status) { return orange }
    if ["unread", "complete", "completed", "done"].contains(status) { return green }
    if status == "error" { return red }
    return secondary.opacity(0.55)
  }

  private static func adaptive(light: UInt32, dark: UInt32) -> Color {
    Color(
      uiColor: UIColor { traits in
        UIColor(rgb: traits.userInterfaceStyle == .dark ? dark : light)
      })
  }
}

private extension UIColor {
  convenience init(rgb: UInt32) {
    self.init(
      red: CGFloat((rgb >> 16) & 0xFF) / 255,
      green: CGFloat((rgb >> 8) & 0xFF) / 255,
      blue: CGFloat(rgb & 0xFF) / 255,
      alpha: 1)
  }
}

struct CodexBackdrop: View {
  let accent: Color

  var body: some View {
    LinearGradient(
      colors: [CodexTheme.backgroundTop, CodexTheme.canvas],
      startPoint: .top,
      endPoint: .bottom)
  }
}

extension View {
  @ViewBuilder
  func codexGlassSurface(
    cornerRadius: CGFloat,
    tint: Color? = nil,
    interactive: Bool = false
  ) -> some View {
    modifier(
      CodexGlassSurfaceModifier(
        cornerRadius: cornerRadius, tint: tint, interactive: interactive))
  }
}

private struct CodexGlassSurfaceModifier: ViewModifier {
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
  @Environment(\.colorSchemeContrast) private var colorSchemeContrast
  let cornerRadius: CGFloat
  let tint: Color?
  let interactive: Bool

  @ViewBuilder
  func body(content: Content) -> some View {
    if reduceTransparency {
      content
        .background {
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(CodexTheme.key)
            .overlay {
              RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint ?? Color.clear)
            }
        }
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
              CodexTheme.ink.opacity(colorSchemeContrast == .increased ? 0.26 : 0.1),
              lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
        }
    } else if #available(iOS 26.0, *) {
      if let tint {
        if interactive {
          content.glassEffect(
            .regular.tint(tint).interactive(), in: .rect(cornerRadius: cornerRadius))
            .overlay { contrastBorder }
        } else {
          content.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
            .overlay { contrastBorder }
        }
      } else if interactive {
        content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
          .overlay { contrastBorder }
      } else {
        content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
          .overlay { contrastBorder }
      }
    } else {
      content
        .background(
          .ultraThinMaterial,
          in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(
              CodexTheme.ink.opacity(colorSchemeContrast == .increased ? 0.22 : 0.08),
              lineWidth: colorSchemeContrast == .increased ? 1.5 : 1)
        }
    }
  }

  @ViewBuilder
  private var contrastBorder: some View {
    if colorSchemeContrast == .increased {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .stroke(CodexTheme.ink.opacity(0.26), lineWidth: 1.5)
    }
  }
}

struct CodexGlassGroup<Content: View>: View {
  let spacing: CGFloat
  private let content: Content

  init(spacing: CGFloat, @ViewBuilder content: () -> Content) {
    self.spacing = spacing
    self.content = content()
  }

  @ViewBuilder
  var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: spacing) { content }
    } else {
      content
    }
  }
}

struct HardwareKeyStyle: ButtonStyle {
  var tint: Color = CodexTheme.ink

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .foregroundStyle(tint)
      .frame(maxWidth: .infinity, minHeight: 62)
      .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(CodexTheme.key.opacity(configuration.isPressed ? 0.72 : 1))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .stroke(CodexTheme.keyHighlight.opacity(0.55), lineWidth: 1)
      )
      .scaleEffect(configuration.isPressed ? 0.97 : 1)
      .animation(.snappy(duration: 0.15), value: configuration.isPressed)
  }
}

struct SectionLabel: View {
  let title: String
  let detail: String?

  init(_ title: String, detail: String? = nil) {
    self.title = title
    self.detail = detail
  }

  var body: some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title.uppercased())
        .font(.caption.weight(.bold))
        .tracking(1.5)
        .foregroundStyle(CodexTheme.secondary)
      Spacer()
      if let detail { Text(detail).font(.caption).foregroundStyle(.secondary) }
    }
  }
}
