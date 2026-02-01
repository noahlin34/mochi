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
            List {
                Section {
                    HStack {
                        PetView(species: pet.species, outfitSymbol: nil, isBouncing: isBouncing)
                            .scaleEffect(0.6)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Care Actions")
                                .font(.headline)
                            Text("Complete habits to keep your pet happy.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }

                if habits.isEmpty {
                    ContentUnavailableView("No Habits Yet", systemImage: "sparkles", description: Text("Add your first habit to care for your pet."))
                } else {
                    ForEach(habits) { habit in
                        HabitRow(habit: habit) {
                            complete(habit)
                        } onEdit: {
                            habitToEdit = habit
                            showingForm = true
                        }
                    }
                    .onDelete(perform: deleteHabits)
                }
            }
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

    private func complete(_ habit: Habit) {
        engine.completeHabit(habit, pet: pet, appState: appState)
        reactionController.trigger()
        Haptics.success()
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(habits[index])
        }
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

private struct HabitRow: View {
    @Bindable var habit: Habit
    let onComplete: () -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(habit.title)
                        .font(.headline)
                    Text(scheduleText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Complete") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
            }

            HStack {
                Label("Today: \(habit.completedCountToday)", systemImage: "sun.max")
                Spacer()
                Label("This week: \(habit.completedThisWeek)", systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit()
        }
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
