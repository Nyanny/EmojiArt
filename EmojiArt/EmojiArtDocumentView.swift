//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Admin on 08.01.2022.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    @State private var chosenPalette: String = ""
    @State private var explainBackgroundPaste = false
    @State private var confirmBackgroundPaste = false

    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(wrappedValue: self.document.defaultPalette)
    }

    var body: some View {
        VStack {
            HStack {
                PaletteChooser(document: document, chosenPalette: $chosenPalette)
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(chosenPalette.map {
                            String($0)
                        }, id: \.self) { emoji in
                            Text(emoji)
                                    .font(Font.system(size: defaultEmojiSize))
                                    .onDrag {
                                        NSItemProvider(object: emoji as NSString)
                                    }
                        }
                    }
                }
//                        .onAppear{self.chosenPalette = self.document.defaultPalette}
            }
            GeometryReader { geometry in
                ZStack {
                    Color.white.overlay(
                            OptionalImage(uiImage: self.document.backgroundImage)
                                    .scaleEffect(self.zoomScale)
                                    .offset(self.panOffset)
                    )
                            .gesture(self.doubleTapToZoom(in: geometry.size))
                    //                            .gesture(self.panGesture())
                    //                            .gesture(self.zoomGesture())
                    if self.isLoading {
                        Image(systemName: "hourglass").imageScale(.large)
                    } else {
                        ForEach(self.document.emojis) { emoji in
                            Text(emoji.text)
                                    .gesture(self.panEmojiGesture(emoji: emoji))
                                    //                                .gesture(self.scaleEmojiGesture(emoji: emoji))
                                    .font(animatableWithSize: emoji.fontSize * zoomScale)
                                    .position(self.position(for: emoji, in: geometry.size))
                        }
                    }
                }
                        .clipped()
                        .gesture(self.panGesture())
                        .gesture(self.zoomGesture())
                        .edgesIgnoringSafeArea([.horizontal, .bottom])
                        .onReceive(self.document.$backgroundImage) { image in
                            self.zoomToFit(image, in: geometry.size)
                        }
                        .onDrop(of: ["public.image", "public.text"], isTargeted: nil) { providers, location in
                            var location = geometry.convert(location, from: .global)
                            location = CGPoint(x: location.x - geometry.size.width / 2, y: location.y - geometry.size.height / 2)
                            location = CGPoint(x: location.x - self.panOffset.width, y: location.y - self.panOffset.height)
                            location = CGPoint(x: location.x / self.zoomScale, y: location.y / self.zoomScale)
                            return self.drop(providers: providers, at: location)
                        }
                        .navigationBarItems(trailing: Button(action: {
                            if let url = UIPasteboard.general.url, url != self.document.backgroundURL {
                                self.confirmBackgroundPaste = true
                            } else {
                                self.explainBackgroundPaste = true
                            }
                        }, label: {
                            Image(systemName: "doc.on.clipboard").imageScale(.large)
                                    .alert(isPresented: self.$explainBackgroundPaste) { () -> Alert in
                                        return Alert(title: Text("Paste Backgorund"),
                                                message: Text("Copy the URL of na image to the clipboard and touch this button to make it the background of ur document."),
                                                dismissButton: .default(Text("Ok")))                                    }
                        }))
            }
                    .zIndex(-1)
        }
                .alert(isPresented: self.$confirmBackgroundPaste) {
                    Alert(title: Text("Paste Background"),
                            message: Text("Replace your background with \(UIPasteboard.general.url?.absoluteString ?? "nothing")?."),
                            primaryButton: .default(Text("OK")) {
                                self.document.backgroundURL = UIPasteboard.general.url
                            }, secondaryButton:  .cancel())
                }
    }

    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }

    private let defaultEmojiSize: CGFloat = 40
    @GestureState private var gestureZoomScale: CGFloat = 1.0
    @GestureState private var gesturePanOffset: CGSize = .zero

    private var zoomScale: CGFloat {
        self.document.steadyStateZoomScale * gestureZoomScale
    }

    private var panOffset: CGSize {
        (self.document.steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    private func zoomGesture() -> some Gesture {
        MagnificationGesture()
                .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, transaction in
                    gestureZoomScale = latestGestureScale
                }
                .onEnded { finalGestureScale in
                    self.document.steadyStateZoomScale *= finalGestureScale
                }
    }

    private func panGesture() -> some Gesture {
        DragGesture()
                .updating($gesturePanOffset) { latestDragGestureValue, gesturePanOffset, transaction in
                    gesturePanOffset = latestDragGestureValue.translation / self.zoomScale
                }
                .onEnded { finalDragGestureValue in
                    self.document.steadyStatePanOffset = self.document.steadyStatePanOffset + (finalDragGestureValue.translation / self.zoomScale)
                }
    }

    private func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
                .onEnded {
                    withAnimation {
                        self.zoomToFit(self.document.backgroundImage, in: size)
                    }
                }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: emoji.location.x + size.width / 2, y: emoji.location.y + size.height / 2)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        return location
    }

    private func zoomToFit(_ image: UIImage?, in size: CGSize) {
        if let image = image, image.size.width > 0, image.size.height > 0, size.height > 0, size.width > 0 {
            let hZoom = size.width / image.size.width
            let vZoom = size.height / image.size.height
            self.document.steadyStatePanOffset = .zero
            self.document.steadyStateZoomScale = min(hZoom, vZoom)
        }
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("dropped \(url)")
            self.document.backgroundURL = url
        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }

    @GestureState private var gesturePanEmojisOffset: CGSize = .zero

    private func panEmojiGesture(emoji: EmojiArt.Emoji) -> some Gesture {
        DragGesture()
                .updating($gesturePanEmojisOffset) { latestDragGestureValue, gestureDragEmojisOffset, transition in
                    gestureDragEmojisOffset = latestDragGestureValue.translation / zoomScale
                }
                .onEnded { finalDragGestureValue in
                    document.moveEmoji(emoji, by: finalDragGestureValue.translation / zoomScale)
                }
    }

    // TODO Delete if theres no need to scale emoji without scaling backgroundimage
    @GestureState private var gestureZoomScaleEmoji: CGFloat = 1.0

    private func scaleEmojiGesture(emoji: EmojiArt.Emoji) -> some Gesture {
        //        MagnificationGesture()
        //                .updating($gestureZoomScale, body: { latestGestureScale, gestureZoomScaleEmoji, transaction in
        //                    gestureZoomScaleEmoji = latestGestureScale
        //                })
        //                .onEnded { finalGestureScale in
        //                    document.scaleEmoji(emoji, by: finalGestureScale)
        //                }
        MagnificationGesture()
                .updating($gestureZoomScale, body: { latestGestureScale, gestureZoomScale, transaction in
                    gestureZoomScale = latestGestureScale
                })
                .onEnded { finalGestureScale in
                    document.scaleEmoji(emoji, by: finalGestureScale)
                }
    }
}

//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
