//
//  PaletteChooser.swift
//  EmojiArt
//
//  Created by Admin on 10.01.2022.
//

import SwiftUI

struct PaletteChooser: View {
    @ObservedObject var document: EmojiArtDocument
    @Binding var chosenPalette: String

    @State private var showPaletteEditor = false

    var body: some View {
        HStack {
            Stepper(onIncrement: {
                self.chosenPalette = self.document.palette(after: self.chosenPalette)
            }, onDecrement: {
                self.chosenPalette = self.document.palette(before: self.chosenPalette)
            }, label: { EmptyView() })
            Text(self.document.paletteNames[self.chosenPalette] ?? "")
            Image(systemName: "keyboard")
                    .imageScale(.large)
                    .onTapGesture {
                        showPaletteEditor = true
                    }
                    .sheet(isPresented: $showPaletteEditor) {
//                    .popover(isPresented: $showPaletteEditor) {
                        PaletteEditor(isShowing: self.$showPaletteEditor, chosenPalette: self.$chosenPalette)
                                .environmentObject(self.document)
                                .frame(minWidth: 300, minHeight: 400)
                    }
        }
                .fixedSize(horizontal: true, vertical: false)
    }
}

struct PaletteEditor: View {
    @EnvironmentObject var document: EmojiArtDocument
    @Binding var isShowing: Bool
    @Binding var chosenPalette: String
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor")
                        .font(.headline)
                        .padding()
                HStack {
                    Spacer ()
                    Button(action: {self.isShowing = false}, label: {
                        Text("Done").padding()
                    })
                }
            }
            Divider()
            Form {
                Section {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            self.document.renamePalette(self.chosenPalette, to: self.paletteName)
                        }
                    })
                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            self.chosenPalette = self.document.addEmoji(self.emojisToAdd, toPalette: self.chosenPalette)
                            self.emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map {
                        String($0)
                    }, id: \.self) { emoji in
                        Text(emoji)
                                .font(Font.system(size: fontSize))
                                .onTapGesture {
                                    self.chosenPalette = self.document.removeEmoji(emoji, fromPalette: self.chosenPalette)
                                }
                    }
                            .frame(height: self.height)
                }
            }
        }
                .onAppear {
                    self.paletteName = self.document.paletteNames[self.chosenPalette] ?? ""
                }
    }

    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6) * 70 + 70
    }

    let fontSize: CGFloat = 40
}


struct PaletteChooser_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument(), chosenPalette: Binding.constant(""))
    }
}
