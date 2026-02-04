import SwiftUI
import SwiftData

struct StoreView: View {
    @EnvironmentObject private var reactionController: PetReactionController
    @Environment(\.tabBarHeight) private var tabBarHeight
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @Bindable var pet: Pet

    @State private var selectedCategory: StoreCategory = .outfits
    @State private var previewItem: InventoryItem?
    @AppStorage("storeShowAllItems") private var showAllItems = false

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
                    availabilityToggle
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
            .background(Color.appBackground)
            .navigationTitle("Shop")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "star.circle.fill")
                        .foregroundStyle(AppColors.accentPeach)
                }
            }
        }
        .onChange(of: selectedCategory) { _, _ in
            previewItem = nil
        }
        .onChange(of: showAllItems) { _, _ in
            if !showAllItems, let previewItem, !previewItem.isAvailable(for: pet.species) {
                self.previewItem = nil
            }
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

            HStack(spacing: 8) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.accentPeach)
                Text("\(pet.coins)")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)
                Text("coins")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.white)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppColors.cardYellow)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var categoryPill: some View {
        HStack(spacing: 6) {
            ForEach(StoreCategory.allCases) { category in
                Button {
                    selectedCategory = category
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

    private var equippedOutfit: InventoryItem? {
        let equipped = items.filter { $0.type == .outfit && $0.equipped }
        if let match = equipped.first(where: { $0.petSpecies == pet.species }) {
            return match
        }
        return equipped.first(where: { $0.petSpecies == nil })
    }

    private var equippedRoom: InventoryItem? {
        items.first { $0.type == .room && $0.equipped }
    }

    private var previewOutfit: InventoryItem? {
        if let previewItem, previewItem.type == .outfit {
            return previewItem
        }
        return equippedOutfit
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
        pet.coins -= item.price
        item.owned = true
        equip(item)
        Haptics.light()
    }

    private func equip(_ item: InventoryItem) {
        guard item.owned else { return }
        if item.type == .room {
            for other in items where other.type == .room {
                other.equipped = false
            }
        } else {
            for other in items where other.type == item.type && other.petSpecies == item.petSpecies {
                other.equipped = false
            }
        }
        item.equipped = true
        reactionController.trigger()
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

                PetView(species: previewSpecies, outfitSymbol: previewOutfit?.assetName, isBouncing: false)
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

#Preview {
    let preview = PreviewData.make()
    return StoreView(pet: preview.pet)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
