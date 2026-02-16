import SwiftUI
import SwiftData

struct StoreView: View {
    @EnvironmentObject private var reactionController: PetReactionController
    @Environment(\.tabBarHeight) private var tabBarHeight
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @Bindable var pet: Pet

    @State private var selectedCategory: StoreCategory = .outfits
    @State private var previewItem: InventoryItem?
    @State private var displayedCoins: Int = 0
    @State private var pendingSpendAnimations: [ShopSpendAnimationRequest] = []
    @State private var activeSpendAnimation: ShopSpendAnimationRequest?
    @State private var showFloatingCoinPill: Bool = false
    @State private var headerFrame: CGRect = .zero
    @State private var headerCoinPillFrame: CGRect = .zero
    @State private var floatingCoinPillFrame: CGRect = .zero
    @State private var buyButtonFrames: [UUID: CGRect] = [:]
    @State private var coinPillPulseToken: Int = 0
    @State private var spendAnimationTask: Task<Void, Never>?
    @AppStorage("storeShowAllItems") private var showAllItems = false
    @Namespace private var coinPillNamespace

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    petPreviewCard
                    categoryPill
                    if selectedCategory == .outfits {
                        availabilityToggle
                    }
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            StoreItemCard(
                                item: item,
                                accent: cardAccents[index % cardAccents.count],
                                activeSpecies: pet.species,
                                coins: pet.coins,
                                onBuy: { buy(item) },
                                onToggleEquip: { toggleEquip(item) },
                                onPreview: { previewItem = item }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, tabBarPadding)
            }
            .coordinateSpace(name: ShopAnimationCoordinateSpace.name)
            .scrollIndicators(.hidden)
            .background(Color.appBackground)
            .overlay(alignment: .topLeading) {
                ShopSpendParticlesOverlay(
                    request: activeSpendAnimation,
                    reduceMotion: reduceMotion
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .topLeading) {
                if showFloatingCoinPill {
                    floatingCoinPill
                        .transition(floatingCoinPillTransition)
                }
            }
            .navigationTitle("Shop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(AppColors.accentPeach)
                }
            }
        }
        .onAppear {
            displayedCoins = pet.coins
        }
        .onChange(of: selectedCategory) { _, _ in
            previewItem = nil
        }
        .onChange(of: showAllItems) { _, _ in
            if !showAllItems, let previewItem, !previewItem.isAvailable(for: pet.species) {
                self.previewItem = nil
            }
        }
        .onChange(of: pet.coins) { _, newValue in
            if activeSpendAnimation == nil && pendingSpendAnimations.isEmpty {
                let duration = reduceMotion ? 0.2 : 0.45
                withAnimation(.easeOut(duration: duration)) {
                    displayedCoins = newValue
                }
            }
        }
        .onPreferenceChange(ShopHeaderFramePreferenceKey.self) { frame in
            guard frame != .zero else { return }
            headerFrame = frame

            let stickyThreshold: CGFloat = 8
            let shouldFloat = frame.maxY < stickyThreshold
            guard shouldFloat != showFloatingCoinPill else { return }

            if reduceMotion {
                withAnimation(.easeOut(duration: 0.15)) {
                    showFloatingCoinPill = shouldFloat
                }
            } else {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                    showFloatingCoinPill = shouldFloat
                }
            }
        }
        .onPreferenceChange(ShopHeaderCoinPillFramePreferenceKey.self) { frame in
            guard frame != .zero else { return }
            headerCoinPillFrame = frame
        }
        .onPreferenceChange(ShopFloatingCoinPillFramePreferenceKey.self) { frame in
            guard frame != .zero else { return }
            floatingCoinPillFrame = frame
        }
        .onPreferenceChange(ShopBuyButtonFramePreferenceKey.self) { frames in
            buyButtonFrames = frames
        }
        .onChange(of: showFloatingCoinPill) { _, isShowing in
            if !isShowing {
                floatingCoinPillFrame = .zero
            }
        }
        .onDisappear {
            spendAnimationTask?.cancel()
            spendAnimationTask = nil
            activeSpendAnimation = nil
            pendingSpendAnimations.removeAll()
        }
    }

    private var tabBarPadding: CGFloat {
        max(tabBarHeight + 16, 96)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spend your coins on goodies!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !showFloatingCoinPill {
                AnimatedShopCoinPill(
                    coins: displayedCoins,
                    pulseToken: coinPillPulseToken,
                    reduceMotion: reduceMotion,
                    style: .full,
                    matchedGeometry: ShopCoinPillMatchedGeometry(
                        id: "shopCoinPill",
                        namespace: coinPillNamespace
                    )
                )
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ShopHeaderCoinPillFramePreferenceKey.self,
                            value: proxy.frame(in: .named(ShopAnimationCoordinateSpace.name))
                        )
                    }
                )
                .transition(
                    headerCoinPillTransition
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.cardYellow)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ShopHeaderFramePreferenceKey.self,
                    value: proxy.frame(in: .named(ShopAnimationCoordinateSpace.name))
                )
            }
        )
    }

    private var floatingCoinPill: some View {
        AnimatedShopCoinPill(
            coins: displayedCoins,
            pulseToken: coinPillPulseToken,
            reduceMotion: reduceMotion,
            style: .compact,
            matchedGeometry: ShopCoinPillMatchedGeometry(
                id: "shopCoinPill",
                namespace: coinPillNamespace
            )
        )
        .padding(.leading, 20)
        .padding(.top, 8)
        .allowsHitTesting(false)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: ShopFloatingCoinPillFramePreferenceKey.self,
                    value: proxy.frame(in: .named(ShopAnimationCoordinateSpace.name))
                )
            }
        )
        .zIndex(3)
    }

    private var headerCoinPillTransition: AnyTransition {
        if reduceMotion {
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .leading)),
                removal: .opacity.combined(with: .scale(scale: 0.92, anchor: .leading))
            )
        }

        // Left edge stays anchored while trailing edge collapses toward it.
        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .leading)),
            removal: .opacity.combined(with: .scale(scale: 0.56, anchor: .leading))
        )
    }

    private var floatingCoinPillTransition: AnyTransition {
        if reduceMotion {
            return .asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.94, anchor: .leading)),
                removal: .opacity
            )
        }

        return .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.82, anchor: .leading)),
            removal: .opacity.combined(with: .scale(scale: 0.92, anchor: .leading))
        )
    }

    private var categoryPill: some View {
        HStack(spacing: 6) {
            ForEach(StoreCategory.allCases) { category in
                Button {
                    guard selectedCategory != category else { return }
                    selectedCategory = category
                    Haptics.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.caption)
                        Text(category.title)
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(selectedCategory == category ? .white : .secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selectedCategory == category ? AppColors.accentPeach : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var availabilityToggle: some View {
        HStack {
            Text("Show all pets")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)
            Spacer()
            Toggle("", isOn: $showAllItems)
                .labelsHidden()
                .tint(AppColors.accentPeach)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    private var filteredItems: [InventoryItem] {
        items.filter { item in
            item.type == selectedCategory.inventoryType
                && (showAllItems || item.isAvailable(for: pet.species))
        }
    }

    private var cardAccents: [Color] {
        [AppColors.cardGreen, AppColors.cardPeach, AppColors.cardPurple, AppColors.cardYellow]
    }

    private var equippedBaseOutfit: InventoryItem? {
        let equipped = items.filter {
            $0.type == .outfit
                && $0.equipped
                && $0.equipStyle == .replaceSprite
        }
        if let match = equipped.first(where: { $0.petSpecies == pet.species }) {
            return match
        }
        return equipped.first(where: { $0.petSpecies == nil })
    }

    private var equippedRoom: InventoryItem? {
        items.first { $0.type == .room && $0.equipped }
    }

    private func equippedOverlayOutfits(for species: PetSpecies) -> [InventoryItem] {
        items
            .filter {
                $0.type == .outfit
                    && $0.equipped
                    && $0.equipStyle == .overlay
                    && $0.isAvailable(for: species)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var previewBaseOutfit: InventoryItem? {
        if let previewItem,
           previewItem.type == .outfit,
           previewItem.equipStyle == .replaceSprite {
            return previewItem
        }
        return equippedBaseOutfit
    }

    private var previewOverlayOutfits: [InventoryItem] {
        var overlays = equippedOverlayOutfits(for: previewSpecies)
        guard let previewItem,
              previewItem.type == .outfit,
              previewItem.equipStyle == .overlay,
              previewItem.isAvailable(for: previewSpecies) else {
            return overlays
        }
        if !overlays.contains(where: { $0.id == previewItem.id }) {
            overlays.append(previewItem)
        }
        return overlays
    }

    private var previewRoom: InventoryItem? {
        if let previewItem, previewItem.type == .room {
            return previewItem
        }
        return equippedRoom
    }

    private var previewSpecies: PetSpecies {
        if let previewItem, previewItem.type == .outfit {
            return previewItem.petSpecies ?? pet.species
        }
        return pet.species
    }

    private func buy(_ item: InventoryItem) {
        guard item.isAvailable(for: pet.species) else { return }
        guard !item.owned, pet.coins >= item.price else { return }
        let coinsFrom = pet.coins
        let coinsTo = coinsFrom - item.price
        let fallbackTarget = buyButtonFrames[item.id]?.center
        let sourcePoint = resolvedCoinSourcePoint(fallbackTarget: fallbackTarget)
        let targetPoint = fallbackTarget ?? CGPoint(x: sourcePoint.x, y: sourcePoint.y + 56)

        let request = ShopSpendAnimationRequest(
            coinsFrom: coinsFrom,
            coinsTo: coinsTo,
            sourcePoint: sourcePoint,
            targetPoint: targetPoint,
            particles: makeSpendParticles(
                from: sourcePoint,
                to: targetPoint,
                count: 18
            ),
            duration: 1.05
        )

        enqueueSpendAnimation(request)
        pet.coins = coinsTo
        item.owned = true
        equip(item)
        Haptics.light()
    }

    private func equip(_ item: InventoryItem) {
        if InventoryEquipService.applyEquip(for: item, in: items) {
            reactionController.trigger()
        }
    }

    private func toggleEquip(_ item: InventoryItem) {
        guard item.isAvailable(for: pet.species) else { return }
        guard item.owned else { return }
        if item.equipped {
            item.equipped = false
        } else {
            equip(item)
        }
    }

    private func enqueueSpendAnimation(_ request: ShopSpendAnimationRequest) {
        pendingSpendAnimations.append(request)
        runNextSpendAnimationIfNeeded()
    }

    private func runNextSpendAnimationIfNeeded() {
        guard activeSpendAnimation == nil else { return }
        guard !pendingSpendAnimations.isEmpty else { return }
        let next = pendingSpendAnimations.removeFirst()
        startSpendAnimation(next)
    }

    private func startSpendAnimation(_ request: ShopSpendAnimationRequest) {
        activeSpendAnimation = request
        let duration = reduceMotion ? 0.2 : request.duration

        if reduceMotion {
            coinPillPulseToken += 1
        }

        withAnimation(.easeOut(duration: duration)) {
            displayedCoins = request.coinsTo
        }

        spendAnimationTask?.cancel()
        spendAnimationTask = Task {
            let delay = duration + 0.2
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                activeSpendAnimation = nil
                runNextSpendAnimationIfNeeded()
            }
        }
    }

    private func resolvedCoinSourcePoint(fallbackTarget: CGPoint?) -> CGPoint {
        if showFloatingCoinPill, floatingCoinPillFrame != .zero {
            return floatingCoinPillFrame.center
        }
        if headerCoinPillFrame != .zero {
            return headerCoinPillFrame.center
        }
        if let fallbackTarget {
            return CGPoint(x: fallbackTarget.x, y: fallbackTarget.y - 80)
        }
        return CGPoint(x: 120, y: 120)
    }

    private func makeSpendParticles(from source: CGPoint, to target: CGPoint, count: Int) -> [ShopSpendParticle] {
        let count = max(1, count)
        let midpoint = CGPoint(
            x: (source.x + target.x) / 2,
            y: min(source.y, target.y) - 44
        )

        return (0..<count).map { index in
            let launchSpreadX = CGFloat.random(in: -16...16)
            let launchSpreadY = CGFloat.random(in: -10...10)
            let controlX = midpoint.x + CGFloat.random(in: -44...44)
            let controlY = midpoint.y + CGFloat.random(in: -30...24)
            let targetSpreadX = CGFloat.random(in: -18...18)
            let targetSpreadY = CGFloat.random(in: -14...14)

            return ShopSpendParticle(
                start: CGPoint(x: source.x + launchSpreadX, y: source.y + launchSpreadY),
                control: CGPoint(x: controlX, y: controlY),
                end: CGPoint(x: target.x + targetSpreadX, y: target.y + targetSpreadY),
                size: CGFloat.random(in: 16...24),
                delay: Double(index) * 0.025,
                duration: 0.72 + Double.random(in: 0...0.22),
                spinDegrees: Double.random(in: -90...90)
            )
        }
    }

    private var petPreviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {

                Spacer()
                Text("Tap an item to preview")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppColors.cardPurple.opacity(0.6))

                LandscapeBackgroundView(assetName: previewRoom?.assetName)
                    .padding(12)

                PetView(
                    species: previewSpecies,
                    baseOutfitSymbol: previewBaseOutfit?.assetName,
                    overlaySymbols: previewOverlayOutfits.map(\.assetName),
                    isBouncing: false
                )
                    .scaleEffect(0.8)
                    .padding(.top, 8)
            }
            .frame(height: 200)
        }
    }
}

private struct StoreItemCard: View {
    @Bindable var item: InventoryItem
    let accent: Color
    let activeSpecies: PetSpecies
    let coins: Int
    let onBuy: () -> Void
    let onToggleEquip: () -> Void
    let onPreview: () -> Void

    var body: some View {
        let isAvailable = item.isAvailable(for: activeSpecies)
        let previewImageName = resolvedPreviewName()
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accent.opacity(0.4))
                    .frame(height: 100)

                itemPreview(imageName: previewImageName)
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(item.type == .outfit ? "Outfit" : "Room decor")
                .font(.caption)
                .foregroundStyle(.secondary)

            if item.type == .outfit {
                Text("\(item.outfitClass.displayName) item")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text(itemSpeciesLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isAvailable ? .secondary : AppColors.accentPeach)

            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.accentPeach)
                Text("\(item.price)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if !isAvailable {
                    Text("Not for this pet")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                } else if item.owned {
                    Text(item.equipped ? "Equipped" : "Equip")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(item.equipped ? AppColors.cardPurple : AppColors.cardGreen)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                        .onTapGesture {
                            onToggleEquip()
                        }
                } else {
                    Button("Buy") {
                        onBuy()
                    }
                    .buttonStyle(.plain)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(coins >= item.price ? AppColors.cardYellow : .gray.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(AppColors.textPrimary)
                    .disabled(coins < item.price)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ShopBuyButtonFramePreferenceKey.self,
                                value: [item.id: proxy.frame(in: .named(ShopAnimationCoordinateSpace.name))]
                            )
                        }
                    )
                }
            }
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .onTapGesture {
            onPreview()
        }
    }

    private func itemPreview(imageName: String?) -> some View {
        Group {
            if let imageName {
                ZStack {
                    ChromaKeyedImage(
                        name: imageName,
                        applyChromaKey: item.type == .outfit,
                        resizable: true,
                        contentMode: .fit
                    )
                        .padding(8)

                    if shouldOverlayEyes(for: imageName) {
                        StaticPetEyes(species: previewSpecies)
                    }
                }
            } else {
                Image(systemName: item.assetName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(AppColors.accentPeach)
            }
        }
    }

    private func resolvedPreviewName() -> String? {
        if UIImage(named: item.assetName) != nil {
            return item.assetName
        }
        if item.type == .room {
            let roomName = "room_\(item.assetName)"
            if UIImage(named: roomName) != nil {
                return roomName
            }
        }
        if item.type == .outfit {
            if item.equipStyle == .overlay {
                for candidate in overlayAssetCandidates(for: previewSpecies, assetName: item.assetName) {
                    if UIImage(named: candidate) != nil {
                        return candidate
                    }
                }
            }
            if let petSpecies = item.petSpecies {
                let petOutfit = "\(petSpecies.rawValue)_pet_\(item.assetName)"
                if UIImage(named: petOutfit) != nil {
                    return petOutfit
                }
            }
            let fallbackDogOutfit = "dog_pet_\(item.assetName)"
            if UIImage(named: fallbackDogOutfit) != nil {
                return fallbackDogOutfit
            }
        }
        return nil
    }

    private func overlayAssetCandidates(for species: PetSpecies, assetName: String) -> [String] {
        [
            "\(species.rawValue)_pet_overlay_\(assetName)",
            "\(species.rawValue)_overlay_\(assetName)",
            "pet_overlay_\(assetName)",
            "overlay_\(assetName)",
            assetName
        ]
    }

    private var previewSpecies: PetSpecies {
        item.petSpecies ?? activeSpecies
    }

    private func shouldOverlayEyes(for imageName: String) -> Bool {
        guard item.type == .outfit else { return false }
        return imageName.contains("_pet")
    }

    private var itemSpeciesLabel: String {
        if item.type == .room {
            return "All pets"
        }
        if let petSpecies = item.petSpecies {
            return "For \(petSpecies.displayName)"
        }
        return "All pets"
    }
}

private enum StoreCategory: String, CaseIterable, Identifiable {
    case outfits
    case rooms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .outfits: return "Outfits"
        case .rooms: return "Decor"
        }
    }

    var icon: String {
        switch self {
        case .outfits: return "tshirt"
        case .rooms: return "house"
        }
    }

    var inventoryType: InventoryItemType {
        switch self {
        case .outfits: return .outfit
        case .rooms: return .room
        }
    }
}

private struct StaticPetEyes: View {
    let species: PetSpecies

    var body: some View {
        GeometryReader { proxy in
            let base = min(proxy.size.width, proxy.size.height)
            let scale = base / 160
            let config = EyeConfig.forSpecies(species)
            let eyeSize = config.size * scale
            let halfSeparation = (config.separation * scale) / 2

            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: eyeSize, height: eyeSize)
                    .offset(x: config.centerX * scale - halfSeparation, y: config.centerY * scale)

                Circle()
                    .fill(Color.black.opacity(0.9))
                    .frame(width: eyeSize, height: eyeSize)
                    .offset(x: config.centerX * scale + halfSeparation, y: config.centerY * scale)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private struct EyeConfig {
        let centerX: CGFloat
        let centerY: CGFloat
        let separation: CGFloat
        let size: CGFloat

        static func forSpecies(_ species: PetSpecies) -> EyeConfig {
            switch species {
            case .dog:
                return EyeConfig(centerX: -5, centerY: -21, separation: 22, size: 8)
            case .penguin:
                return EyeConfig(centerX: -10, centerY: -20, separation: 25, size: 9)
            case .lion:
                return EyeConfig(centerX: -6, centerY: -20, separation: 24, size: 8)
            case .cat:
                return EyeConfig(centerX: 0, centerY: -18, separation: 24, size: 7)
            case .bunny:
                return EyeConfig(centerX: 0, centerY: -16, separation: 22, size: 7)
            }
        }
    }
}

private enum ShopAnimationCoordinateSpace {
    static let name = "ShopAnimationSpace"
}

private struct ShopSpendAnimationRequest: Identifiable, Equatable {
    let id = UUID()
    let coinsFrom: Int
    let coinsTo: Int
    let sourcePoint: CGPoint
    let targetPoint: CGPoint
    let particles: [ShopSpendParticle]
    let duration: Double
}

private struct ShopSpendParticle: Identifiable, Equatable {
    let id = UUID()
    let start: CGPoint
    let control: CGPoint
    let end: CGPoint
    let size: CGFloat
    let delay: Double
    let duration: Double
    let spinDegrees: Double
}

private struct ShopHeaderFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct ShopHeaderCoinPillFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct ShopFloatingCoinPillFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

private struct ShopBuyButtonFramePreferenceKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] = [:]

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct ShopCoinPillMatchedGeometry {
    let id: String
    let namespace: Namespace.ID
}

private struct AnimatedShopCoinPill: View {
    enum Style {
        case full
        case compact
    }

    let coins: Int
    let pulseToken: Int
    let reduceMotion: Bool
    let style: Style
    let matchedGeometry: ShopCoinPillMatchedGeometry?

    @State private var pulseScale: CGFloat = 1
    @State private var pulseOpacity: Double = 1

    var body: some View {
        let content = HStack(spacing: style == .full ? 8 : 6) {
            Image(systemName: "circle.fill")
                .font(.system(size: style == .full ? 12 : 11))
                .foregroundStyle(AppColors.accentPeach)
            Text("\(coins)")
                .font((style == .full ? Font.headline : Font.subheadline).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(AppColors.textPrimary)
                .contentTransition(.numericText(value: Double(coins)))
            if style == .full {
                Text("coins")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, style == .full ? 16 : 12)
        .padding(.vertical, style == .full ? 10 : 8)

        Group {
            if let matchedGeometry, !reduceMotion {
                content
                    .matchedGeometryEffect(
                        id: matchedGeometry.id,
                        in: matchedGeometry.namespace,
                        properties: [.position, .size],
                        anchor: .leading
                    )
            } else {
                content
            }
        }
        .frame(width: style == .compact ? 108 : nil, alignment: .leading)
        .background(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        .scaleEffect(pulseScale)
        .opacity(pulseOpacity)
        .onChange(of: pulseToken) { _, _ in
            guard reduceMotion else { return }
            pulseScale = 0.95
            pulseOpacity = 0.86
            withAnimation(.easeOut(duration: 0.2)) {
                pulseScale = 1
                pulseOpacity = 1
            }
        }
    }
}

private struct ShopSpendParticlesOverlay: View {
    let request: ShopSpendAnimationRequest?
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            if let request, !reduceMotion {
                ForEach(request.particles) { particle in
                    ShopSpendParticleView(particle: particle)
                }
            }
        }
        .id(request?.id)
    }
}

private struct ShopSpendParticleView: View {
    let particle: ShopSpendParticle

    @State private var progress: CGFloat = 0

    var body: some View {
        Circle()
            .fill(AppColors.accentPeach)
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(particle.spinDegrees * Double(progress)))
        .scaleEffect(1 - (0.1 * progress))
        .opacity(max(0, 1 - (1.2 * Double(progress))))
        .position(currentPosition(progress: progress))
        .onAppear {
            withAnimation(
                .timingCurve(0.25, 0.8, 0.25, 1, duration: particle.duration)
                    .delay(particle.delay)
            ) {
                progress = 1
            }
        }
    }

    private func currentPosition(progress t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let x = (oneMinusT * oneMinusT * particle.start.x)
            + (2 * oneMinusT * t * particle.control.x)
            + (t * t * particle.end.x)
        let y = (oneMinusT * oneMinusT * particle.start.y)
            + (2 * oneMinusT * t * particle.control.y)
            + (t * t * particle.end.y)
            + (14 * t * t)
        return CGPoint(x: x, y: y)
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

#Preview {
    let preview = PreviewData.make()
    return StoreView(pet: preview.pet)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
