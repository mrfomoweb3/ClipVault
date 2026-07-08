import SwiftUI

struct ClipboardListView: View {
    @Bindable var vm: ClipboardViewModel
    let onPaste: (ClipboardEntry) -> Void

    var body: some View {
        Group {
            if vm.filteredEntries.isEmpty {
                EmptyStateView(isFiltered: !vm.searchText.isEmpty)
            } else {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.filteredEntries, id: \.id) { entry in
                                ClipboardRowView(
                                    entry: entry,
                                    isSelected: vm.selectedID == entry.id,
                                    onTap: { onPaste(entry) },
                                    onPin: { vm.togglePin(entry) },
                                    onDelete: { vm.delete(entry) }
                                )
                                .id(entry.id)

                                if entry.id != vm.filteredEntries.last?.id {
                                    Divider()
                                        .padding(.leading, 52)
                                        .foregroundStyle(Color.cvDivider)
                                }
                            }
                        }
                    }
                    .onChange(of: vm.selectedID) { _, id in
                        guard let id else { return }
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            proxy.scrollTo(id, anchor: .center)
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.filteredEntries.map(\.id))
    }
}
