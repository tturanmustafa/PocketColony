//
//  ShimmerModifier.swift
//  PocketColony
//
//  Created by Mustafa Turan on 10.02.2026.
//


// Extensions.swift
// Faydalı uzantılar

import SwiftUI
import SpriteKit

// MARK: - View Extensions
extension View {
    func glow(color: Color, radius: CGFloat = 10) -> some View {
        self.shadow(color: color, radius: radius / 2)
            .shadow(color: color, radius: radius)
    }
    
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
    
    func bounceOnTap() -> some View {
        self.modifier(BounceModifier())
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.3), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + phase * geometry.size.width * 3)
                    .mask(content)
                }
            )
            .onAppear {
                guard isActive else { return }
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

// MARK: - Bounce Tap
struct BounceModifier: ViewModifier {
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
            .onTapGesture {
                isPressed = true
                HapticsService.shared.impact(.light)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isPressed = false
                }
            }
    }
}

// MARK: - Number Formatting
extension Double {
    var shortString: String {
        if self >= 1_000_000 { return String(format: "%.1fM", self / 1_000_000) }
        if self >= 1_000 { return String(format: "%.1fK", self / 1_000) }
        return String(format: "%.0f", self)
    }
}

extension Int {
    var shortString: String {
        Double(self).shortString
    }
}

// MARK: - Date Extensions
extension Date {
    var timeAgoString: String {
        let interval = -self.timeIntervalSinceNow
        if interval < 60 { return "Az önce" }
        if interval < 3600 { return "\(Int(interval/60)) dk önce" }
        if interval < 86400 { return "\(Int(interval/3600)) saat önce" }
        return "\(Int(interval/86400)) gün önce"
    }
}

// MARK: - TimeInterval Formatting
extension TimeInterval {
    var formattedBuildTime: String {
        if self < 60 { return "\(Int(self))sn" }
        if self < 3600 { return "\(Int(self/60))dk \(Int(self.truncatingRemainder(dividingBy: 60)))sn" }
        let hours = Int(self / 3600)
        let mins = Int(self.truncatingRemainder(dividingBy: 3600) / 60)
        return "\(hours)sa \(mins)dk"
    }
}

// MARK: - Array Extensions
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - SKColor Extension
extension SKColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - Conditional ViewModifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Random Weighted Selection
extension Array where Element == (weight: Double, value: Rarity) {
    func weightedRandom() -> Rarity {
        let total = reduce(0) { $0 + $1.weight }
        var random = Double.random(in: 0..<total)
        for item in self {
            random -= item.weight
            if random < 0 { return item.value }
        }
        return last?.value ?? .common
    }
}