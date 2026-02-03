import SwiftUI
import SwiftData

struct StoreView: View {
    @EnvironmentObject private var reactionController: PetReactionController
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @Bindable var pet: Pet

    @State private var selectedCategory: StoreCategory = .outfits
    @State private var previewItem: InventoryItem?

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
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                            StoreItemCard(
                                item: item,
                                accent: cardAccents[index % cardAccents.count],
                                coins: pet.coins,
                                onBuy: { buy(item) },
                                onToggleEquip: { toggleEquip(item) },
                                onPreview: { previewItem = item }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
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

    private var filteredItems: [InventoryItem] {
        items.filter { $0.type == selectedCategory.inventoryType }
    }

    private var cardAccents: [Color] {
        [AppColors.cardGreen, AppColors.cardPeach, AppColors.cardPurple, AppColors.cardYellow]
    }

    private var equippedOutfit: InventoryItem? {
        items.first { $0.type == .outfit && $0.equipped }
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

    private func buy(_ item: InventoryItem) {
        guard !item.owned, pet.coins >= item.price else { return }
        pet.coins -= item.price
        item.owned = true
        equip(item)
        Haptics.light()
    }

    private func equip(_ item: InventoryItem) {
        guard item.owned else { return }
        for other in items where other.type == item.type {
            other.equipped = false
        }
        item.equipped = true
        reactionController.trigger()
    }

    private func toggleEquip(_ item: InventoryItem) {
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
                Text("Preview")
                    .font(.headline)
                    .foregroundStyle(AppColors.textPrimary)
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

                PetView(species: pet.species, outfitSymbol: previewOutfit?.assetName, isBouncing: false)
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
    let coins: Int
    let onBuy: () -> Void
    let onToggleEquip: () -> Void
    let onPreview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(accent.opacity(0.4))
                    .frame(height: 100)

                itemPreview
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.textPrimary)

            Text(item.type == .outfit ? "Outfit" : "Room decor")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(AppColors.accentPeach)
                Text("\(item.price)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                if item.owned {
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

    private var itemPreview: some View {
        Group {
            if let imageName = resolvedPreviewName() {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
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
            let dogOutfit = "dog_pet_\(item.assetName)"
            if UIImage(named: dogOutfit) != nil {
                return dogOutfit
            }
        }
        return nil
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

#Preview {
    let preview = PreviewData.make()
    return StoreView(pet: preview.pet)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
