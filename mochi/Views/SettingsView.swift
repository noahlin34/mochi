import SwiftUI

struct SettingsView: View {
    @Bindable var pet: Pet
    @Bindable var appState: AppState

    var body: some View {
        NavigationStack {
            Form {
                Section("Pet") {
                    Picker("Species", selection: $appState.selectedPetSpecies) {
                        ForEach(PetSpecies.allCases) { species in
                            Text(species.displayName).tag(species)
                        }
                    }
                    .onChange(of: appState.selectedPetSpecies) { _, newValue in
                        pet.species = newValue
                    }

                    TextField("Name", text: $pet.name)
                }

                Section("Tutorial") {
                    Toggle("Tutorial seen", isOn: $appState.tutorialSeen)
                }
            }
            .navigationTitle("Settings")
        }
    }
}
