import SwiftUI
import Contacts

struct SyncContactsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var contacts: [CNContact] = []
    @State private var selectedContacts: Set<String> = []
    @State private var isSyncing = false
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Sync Your Contacts")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Find friends who are already using Gig and see their activity in your social feed.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button("Sync Contacts") {
                            requestContactsAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(contacts, id: \.identifier) { contact in
                            ContactRow(
                                contact: contact,
                                isSelected: selectedContacts.contains(contact.identifier),
                                onToggle: { isSelected in
                                    if isSelected {
                                        selectedContacts.insert(contact.identifier)
                                    } else {
                                        selectedContacts.remove(contact.identifier)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Sync Contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !contacts.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Sync Selected") {
                            syncSelectedContacts()
                        }
                        .disabled(selectedContacts.isEmpty || isSyncing)
                    }
                }
            }
            .alert("Contacts Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable contacts access in Settings to sync your contacts.")
            }
        }
    }
    
    private func requestContactsAccess() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    loadContacts()
                } else {
                    showingPermissionAlert = true
                }
            }
        }
    }
    
    private func loadContacts() {
        let store = CNContactStore()
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
        let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
        
        do {
            try store.enumerateContacts(with: request) { contact, stop in
                contacts.append(contact)
            }
        } catch {
            print("Error loading contacts: \(error)")
        }
    }
    
    private func syncSelectedContacts() {
        isSyncing = true
        
        // Mock sync process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSyncing = false
            dismiss()
        }
    }
}

struct ContactRow: View {
    let contact: CNContact
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack {
            // Contact Avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(contactInitials)
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(contactName)
                    .font(.headline)
                
                if let phoneNumber = contact.phoneNumbers.first?.value.stringValue {
                    Text(phoneNumber)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
    
    private var contactName: String {
        let firstName = contact.givenName
        let lastName = contact.familyName
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }
    
    private var contactInitials: String {
        let firstName = contact.givenName.prefix(1)
        let lastName = contact.familyName.prefix(1)
        return "\(firstName)\(lastName)".uppercased()
    }
}

#Preview {
    SyncContactsView()
} 