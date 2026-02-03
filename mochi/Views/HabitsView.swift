import SwiftUI
import SwiftData

struct HabitsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var reactionController: PetReactionController
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @Bindable var pet: Pet
    @Bindable var appState: AppState

    @State private var showingForm = false
    @State private var habitToEdit: Habit?
    @State private var isBouncing = false

    private let engine = GameEngine()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard

                    if habits.isEmpty {
                        ContentUnavailableView("No Habits Yet", systemImage: "sparkles", description: Text("Add your first habit to care for your pet."))
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(habits) { habit in
                                HabitListCard(
                                    habit: habit,
                                    onComplete: { complete(habit) },
                                    onEdit: {
                                        habitToEdit = habit
                                        showingForm = true
                                    },
                                    onDelete: {
                                        deleteHabit(habit)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.appBackground)
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        habitToEdit = nil
                        showingForm = true
                    } label: {
                        Label("Add Habit", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingForm) {
                HabitFormView(habit: habitToEdit)
            }
        }
        .onChange(of: reactionController.pulse) { _ in
            triggerBounce()
        }
    }

    private var headerCard: some View {
        HStack(spacing: 16) {
            PetView(species: pet.species, outfitSymbol: nil, isBouncing: isBouncing)
                .scaleEffect(0.55)
                .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 6) {
                Text("Care Actions")
                    .font(.headline)
                Text("Complete habits to keep your pet happy.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(14)
        .background(AppColors.cardPurple)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func complete(_ habit: Habit) {
        engine.completeHabit(habit, pet: pet, appState: appState)
        reactionController.trigger()
        Haptics.success()
    }

    private func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)
    }

    private func triggerBounce() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            isBouncing = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isBouncing = false
            }
        }
    }
}

private struct HabitListCard: View {
    @Bindable var habit: Habit
    let onComplete: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.headline)
                    Text(scheduleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    onComplete()
                } label: {
                    Text("Complete")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppColors.accentPurple)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            HStack {
                Label("Today: \(habit.completedCountToday)", systemImage: "sun.max")
                Spacer()
                Label("This week: \(habit.completedThisWeek)", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Menu {
                    Button("Edit", action: onEdit)
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var scheduleText: String {
        switch habit.scheduleType {
        case .daily:
            return "Daily"
        case .xTimesPerWeek:
            let target = habit.targetPerWeek ?? 0
            return "\(target)x per week"
        }
    }
}

#Preview {
    let preview = PreviewData.make()
    return HabitsView(pet: preview.pet, appState: preview.appState)
        .modelContainer(preview.container)
        .environmentObject(PetReactionController())
}
