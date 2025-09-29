import SwiftUI

struct ZoomableModifier: ViewModifier {
    let minZoomScale: CGFloat
    let maxZoomScale: CGFloat?
    let doubleTapZoomScale: CGFloat?

    @State private var lastTransform: CGAffineTransform = .identity
    @State private var transform: CGAffineTransform = .identity
    @State private var contentSize: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .background(alignment: .topLeading) {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            contentSize = proxy.size
                        }
                }
            }
            .animatableTransformEffect(transform)
            .gesture(dragGesture, including: transform == .identity ? .none : .all)
            .modify { view in
                if #available(iOS 17.0, *) {
                    view.gesture(magnificationGesture)
                } else {
                    view.gesture(oldMagnificationGesture)
                }
            }
            .modify { view in
                if let doubleTapZoomScale {
                    view.gesture(doubleTapGesture(doubleTapZoomScale))
                } else {
                    view
                }
            }
    }

    @available(iOS, introduced: 16.0, deprecated: 17.0)
    private var oldMagnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let zoomFactor = 0.5
                let scale = value * zoomFactor
                transform = lastTransform.scaledBy(x: scale, y: scale)
            }
            .onEnded { _ in
                onEndGesture()
            }
    }

    @available(iOS 17.0, *)
    private var magnificationGesture: some Gesture {
        MagnifyGesture(minimumScaleDelta: 0)
            .onChanged { value in
                let newTransform = CGAffineTransform.anchoredScale(
                    scale: value.magnification,
                    anchor: value.startAnchor.scaledBy(contentSize)
                )

                withAnimation(.interactiveSpring) {
                    transform = lastTransform.concatenating(newTransform)
                }
            }
            .onEnded { _ in
                onEndGesture()
            }
    }

    private func doubleTapGesture(_ zoomScale: CGFloat) -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                let newTransform: CGAffineTransform =
                    if transform.isIdentity {
                        .anchoredScale(scale: zoomScale, anchor: value.location)
                    } else {
                        .identity
                    }

                withAnimation(.linear(duration: 0.15)) {
                    transform = newTransform
                    lastTransform = newTransform
                }

                onEndGesture()
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation(.interactiveSpring) {
                    transform = lastTransform.translatedBy(
                        x: value.translation.width / max(transform.scaleX, .leastNonzeroMagnitude),
                        y: value.translation.height / max(transform.scaleY, .leastNonzeroMagnitude)
                    )
                }
            }
            .onEnded { _ in
                onEndGesture()
            }
    }

    private func onEndGesture() {
        let newTransform = limitTransform(transform)

        withAnimation(.snappy(duration: 0.1)) {
            transform = newTransform
            lastTransform = newTransform
        }
    }

    private func limitTransform(_ transform: CGAffineTransform) -> CGAffineTransform {
        let scaleX = transform.scaleX
        let scaleY = transform.scaleY

        if scaleX < minZoomScale || scaleY < minZoomScale {
            return .identity
        }

        var capped = transform

        if let maxZoomScale {
            let currentScale = max(scaleX, scaleY)
            if currentScale > maxZoomScale {
                let factor = maxZoomScale / currentScale
                let contentCenter = CGPoint(x: contentSize.width / 2, y: contentSize.height / 2)
                let capTransform = CGAffineTransform.anchoredScale(scale: factor, anchor: contentCenter)
                capped = capped.concatenating(capTransform)
            }
        }

        let maxX = contentSize.width * (capped.scaleX - 1)
        let maxY = contentSize.height * (capped.scaleY - 1)

        if capped.tx > 0 || capped.tx < -maxX || capped.ty > 0 || capped.ty < -maxY {
            let tx = min(max(capped.tx, -maxX), 0)
            let ty = min(max(capped.ty, -maxY), 0)
            capped.tx = tx
            capped.ty = ty
        }

        return capped
    }
}

public extension View {
    @ViewBuilder
    func zoomable(
        minZoomScale: CGFloat = 1,
        maxZoomScale: CGFloat? = nil,
        doubleTapZoomScale: CGFloat? = 3
    ) -> some View {
        modifier(ZoomableModifier(
            minZoomScale: minZoomScale,
            maxZoomScale: maxZoomScale,
            doubleTapZoomScale: doubleTapZoomScale
        ))
    }

    @ViewBuilder
    func zoomable(
        minZoomScale: CGFloat = 1,
        maxZoomScale: CGFloat? = nil,
        doubleTapZoomScale: CGFloat? = 3,
        outOfBoundsColor: Color = .clear
    ) -> some View {
        GeometryReader { _ in
            ZStack {
                outOfBoundsColor
                self.zoomable(
                    minZoomScale: minZoomScale,
                    maxZoomScale: maxZoomScale,
                    doubleTapZoomScale: doubleTapZoomScale
                )
            }
        }
    }
}

private extension View {
    @ViewBuilder
    func modify(@ViewBuilder _ fn: (Self) -> some View) -> some View {
        fn(self)
    }

    @ViewBuilder
    func animatableTransformEffect(_ transform: CGAffineTransform) -> some View {
        scaleEffect(
            x: transform.scaleX,
            y: transform.scaleY,
            anchor: .zero
        )
        .offset(x: transform.tx, y: transform.ty)
    }
}

private extension UnitPoint {
    func scaledBy(_ size: CGSize) -> CGPoint {
        .init(
            x: x * size.width,
            y: y * size.height
        )
    }
}

private extension CGAffineTransform {
    static func anchoredScale(scale: CGFloat, anchor: CGPoint) -> CGAffineTransform {
        CGAffineTransform(translationX: anchor.x, y: anchor.y)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: -anchor.x, y: -anchor.y)
    }

    var scaleX: CGFloat {
        sqrt(a * a + c * c)
    }

    var scaleY: CGFloat {
        sqrt(b * b + d * d)
    }
}
