//
// Created by Admin on 10.01.2022.
//

import SwiftUI

struct EditableText: View {
    var text = ""
    var isEditing: Bool
    var onChanged: (String) -> Void

    init(_ text: String, isEditing: Bool, onChanged: @escaping (String) -> Void) {
        self.text = text
        self.isEditing = isEditing
        self.onChanged = onChanged
    }

    @State private var editableText = ""

    var body: some View {
        ZStack(alignment: .leading) {
            TextField(text, text: $editableText, onEditingChanged: { began in
                self.callOnChangedIfChanged()
            })
                    .opacity(isEditing ? 1 : 0)
                    .disabled(!isEditing)
            if !isEditing {
                Text(text)
                        .opacity(isEditing ? 0 : 1)
                        .onAppear {
                            self.callOnChangedIfChanged()
                        }
            }
        }
                .onAppear { self.editableText = self.text }
    }

    func callOnChangedIfChanged() {
        if editableText != text {
            onChanged(editableText)
        }
    }
}