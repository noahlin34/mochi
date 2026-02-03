import SwiftUI
import SwiftData

struct HabitFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let habit: Habit?

    @State private var title: String
    @State private var scheduleType: ScheduleType
    @State private var targetPerDay: Int
    @State private var targetPerWeek: Int

    init(habit: Habit?) {
        self.habit = habit
        _title = State(initialValue: habit?.title ?? "")
        _scheduleType = State(initialValue: habit?.scheduleType ?? .daily)
        _targetPerDay = State(initialValue: habit?.targetPerDay ?? 3)
        _targetPerWeek = State(initialValue: habit?.targetPerWeek ?? 3)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Habit") {
                    TextField("Title", text: $title)
                }

                Section("Schedule") {
                    Picker("Type", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    if scheduleType.needsDailyTarget {
                        Stepper("Times per day: \(targetPerDay)", value: $targetPerDay, in: 1...20)
                    }

                    if scheduleType.needsWeeklyTarget {
                        Stepper("Times per week: \(targetPerWeek)", value: $targetPerWeek, in: 1...20)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveHabit()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveHabit() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let habit {
            habit.title = trimmedTitle
            habit.scheduleType = scheduleType
            habit.targetPerDay = scheduleType == .xTimesPerDay ? targetPerDay : nil
            habit.targetPerWeek = scheduleType == .xTimesPerWeek ? targetPerWeek : nil
        } else {
            let newHabit = Habit(
                title: trimmedTitle,
                scheduleType: scheduleType,
                targetPerDay: scheduleType == .xTimesPerDay ? targetPerDay : nil,
                targetPerWeek: scheduleType == .xTimesPerWeek ? targetPerWeek : nil
            )
            modelContext.insert(newHabit)
        }

        dismiss()
    }
}

#Preview {
    let preview = PreviewData.make()
    return HabitFormView(habit: nil)
        .modelContainer(preview.container)
}
