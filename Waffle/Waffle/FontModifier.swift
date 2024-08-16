import SwiftUI

extension View {
    func montserratAlternates(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        self.modifier(MontserratAlternatesFont(size: size, weight: weight))
    }
}

struct MontserratAlternatesFont: ViewModifier {
    var size: CGFloat
    var weight: Font.Weight

    func body(content: Content) -> some View {
        content.font(.custom("MontserratAlternates-Regular", size: size, relativeTo: .body))
    }
}
