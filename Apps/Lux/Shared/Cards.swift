import LuxCore
import LuxDesignSystem
import SwiftUI

/// A card under a gradient sky (`Sky`): Today's offices and the Library's
/// folders. The title sits at the top of the sky, where its contrast is
/// tested (SkyTests); the symbol sits low.
struct GradientCard: View {
    let title: String
    var subtitle: String? = nil
    var symbol: String? = nil
    var badge: String? = nil
    let sky: Sky.Gradient
    var minHeight: CGFloat = 150

    var body: some View {
        let text = sky.text.color
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(TypeRole.heading.font)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Spacing.s)
                if let badge {
                    Text(badge)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, Spacing.s)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(text.opacity(0.16)))
                }
            }
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .opacity(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: Spacing.l)
            if let symbol {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .font(.title2)
                    .accessibilityHidden(true)
            }
        }
        .foregroundStyle(text)
        .padding(Spacing.m)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(sky.linear, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.primary.opacity(0.08)))
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// A daily office as a card: dawn for Morning Prayer, dusk for Evening Prayer.
struct OfficeCard: View {
    let office: Office
    var isSuggested = false
    var minHeight: CGFloat = 150
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let dark = scheme == .dark
        GradientCard(title: office.displayName,
                     symbol: office == .morningPrayer ? "sunrise.fill" : "sunset.fill",
                     badge: isSuggested ? "Now" : nil,
                     sky: office == .morningPrayer ? Sky.dawn(dark: dark) : Sky.dusk(dark: dark),
                     minHeight: minHeight)
            .accessibilityLabel(isSuggested ? "\(office.displayName), the office for now" : office.displayName)
    }
}

/// Cards in a row that scrolls a card at a time, with page dots beneath.
struct Carousel<Item: Hashable, Card: View>: View {
    let items: [Item]
    @Binding var selection: Item?
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        VStack(spacing: Spacing.s) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: Spacing.m) {
                    ForEach(items, id: \.self) { item in
                        card(item)
                            .containerRelativeFrame(.horizontal) { length, _ in min(length - 2 * Spacing.l, 560) }
                            .id(item)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selection)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, Spacing.m, for: .scrollContent)
            if items.count > 1 {
                HStack(spacing: Spacing.s) {
                    ForEach(items, id: \.self) { item in
                        Circle()
                            .fill(Color.primary.opacity(item == (selection ?? items.first) ? 0.6 : 0.2))
                            .frame(width: 7, height: 7)
                            .onTapGesture { withAnimation { selection = item } }
                    }
                }
                .accessibilityHidden(true)
            }
        }
    }
}

/// A small neutral tile for an index: a day of the month, a psalm.
struct IndexTile: View {
    let title: String
    var caption: String? = nil
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let colors = LuxColors(scheme)
        VStack(spacing: 2) {
            Text(title).font(TypeRole.heading.font.monospacedDigit()).foregroundStyle(colors.textPrimary)
            if let caption {
                Text(caption).font(.caption2).foregroundStyle(colors.textSecondary).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(colors.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(colors.divider))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
