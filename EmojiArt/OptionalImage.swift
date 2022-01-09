//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Admin on 09.01.2022.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?

    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}

//struct OptionalImage_Previews: PreviewProvider {
//    static var previews: some View {
//        OptionalImage()
//    }
//}
