import SwiftUI
import SwiftData

struct StoreView: View {
    @EnvironmentObject private var reactionController: PetReactionController
    @Query(sort: \InventoryItem.createdAt) private var items: [InventoryItem]

    @Bindable var pet: Pet

    @State private var selectedType: InventoryItemType = .outfit

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                picker

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredItems) { item in
                            InventoryItemCard(
                                item: item,
                                coins: pet.coins,
                                onBuy: { buy(item) },
                                onEquip: { equip(item) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(AppColors.accentPeach)
                        Text("\(pet.coins)")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppColors.coinPill)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var picker: some View {
        Picker("Type", selection: $selectedType) {
            ForEach(InventoryItemType.allCases) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 20)
    }

    private var filteredItems: [InventoryItem] {
        items.filter { $0.type == selectedType }
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
}

private struct InventoryItemCard: View {
    @Bindable var item: InventoryItem
    let coins: Int
    let onBuy: () -> Void
    let onEquip: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: item.assetName)
                .font(.title2)
                .frame(width: 48, height: 48)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                Text("Price: \(item.price)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if item.owned {
                Button(item.equipped ? "Equipped" : "Equip") {
                    onEquip()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(item.equipped ? AppColors.cardPurple : AppColors.cardGreen)
                .clipShape(Capsule())
            } else {
                Button("Buy") {
                    onBuy()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(coins >= item.price ? AppColors.cardYellow : .gray.opacity(0.2))
                .clipShape(Capsule())
                .foregroundStyle(AppColors.textPrimary)
                .disabled(coins < item.price)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
