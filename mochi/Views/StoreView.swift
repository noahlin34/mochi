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
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Label("\(pet.coins)", systemImage: "bitcoinsign.circle")
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
        .padding(.horizontal)
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
                .frame(width: 44, height: 44)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

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
                .buttonStyle(.borderedProminent)
                .disabled(item.equipped)
            } else {
                Button("Buy") {
                    onBuy()
                }
                .buttonStyle(.bordered)
                .disabled(coins < item.price)
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
