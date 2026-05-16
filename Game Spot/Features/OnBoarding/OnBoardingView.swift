import SwiftUI

struct OnBoardingItem: Identifiable {

    let id: Int

    let title: String
    let subtitle: String

    let screenshot: UIImage?

    let zoomScale: CGFloat
    let zoomAnchor: UnitPoint
}

struct OnBoardingView: View {

    // MARK: - State

    @StateObject private var locationManager =
        LocationManager()

    @State private var currentPage: Int = 0

    @State private var screenshotSize: CGSize = .zero

    // MARK: - Data

    private let items: [OnBoardingItem] = [

        .init(
            id: 0,
            title: "Play. Compete. Connect.",
            subtitle: "Find local sports games, meet players and level up your profile.",
            screenshot: UIImage(named: "onBoarding1"),
            zoomScale: 1,
            zoomAnchor: .center
        ),

        .init(
            id: 1,
            title: "Games Around You",
            subtitle: "Discover matches nearby and join with one tap.",
            screenshot: UIImage(named: "onBoarding2"),
            zoomScale: 1.45,
            zoomAnchor: .init(x: 0.05, y: 0.32)
        ),

        .init(
            id: 2,
            title: "Create Your Own Games",
            subtitle: "Host matches, invite players and build your community.",
            screenshot: UIImage(named: "onBoarding3"),
            zoomScale: 1.75,
            zoomAnchor: .center
        ),

        .init(
            id: 3,
            title: "Your Stats Matter",
            subtitle: "Earn rating, MVPs and performance points after every match.",
            screenshot: UIImage(named: "onBoarding4"),
            zoomScale: 1.3,
            zoomAnchor: .init(x: 0.52, y: 0.23)
        ),

        .init(
            id: 4,
            title: "Climb The Ranks",
            subtitle: "Improve your performance and unlock higher competitive tiers.",
            screenshot: UIImage(named: "onBoarding5"),
            zoomScale: 1.7,
            zoomAnchor: .init(x: 0.5, y: 0.16)
        ),

        .init(
            id: 5,
            title: "Ready To Play?",
            subtitle: "Set up your profile and start joining games today.",
            screenshot: UIImage(named: "onBoarding6"),
            zoomScale: 1,
            zoomAnchor: .center
        )
    ]

    var onFinish: (() -> Void)?

    // MARK: - Computed

    private var deviceCornerRadius: CGFloat {

        if let imageSize = items.first?.screenshot?.size {

            let ratio =
                screenshotSize.height / imageSize.height

            let actualCornerRadius: CGFloat = 190

            return actualCornerRadius * ratio
        }

        return 0
    }

    private var animation: Animation {

        .interpolatingSpring(
            duration: 0.65,
            bounce: 0.2,
            initialVelocity: 0
        )
    }

    // MARK: - Body

    var body: some View {

        ZStack(alignment: .bottom) {

            screenshotView
                .compositingGroup()
                .scaleEffect(
                    items[currentPage].zoomScale,
                    anchor: items[currentPage].zoomAnchor
                )
                .padding(.top, 35)
                .padding(.horizontal, 30)
                .padding(.bottom, 220)

            VStack(spacing: 10) {

                textContentView

                indicatorView

                continueButton
            }
            .padding(.top, 20)
            .padding(.horizontal, 15)
            .frame(height: 210)
            .background {
                variableGlassBlur(15)
            }

            backButton
        }
        .onChange(of: currentPage) { _, newValue in

            if newValue == 1 {

                locationManager
                    .requestLocationAccess()
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {

        Button {

            withAnimation(animation) {

                if currentPage == items.count - 1 {

                    onFinish?()

                } else {

                    currentPage =
                        min(
                            currentPage + 1,
                            items.count - 1
                        )
                }
            }

        } label: {

            Text(
                currentPage == items.count - 1
                ? "Start"
                : "Continue"
            )
            .fontWeight(.bold)
            .contentTransition(.numericText())
            .padding(.vertical, 6)
        }
        .tint(Color("AccentColor"))
        .buttonStyle(.glassProminent)
        .buttonSizing(.flexible)
        .padding(.horizontal, 30)
    }

    // MARK: - Back Button

    private var backButton: some View {

        Button {

            withAnimation(animation) {

                currentPage =
                    max(currentPage - 1, 0)
            }

        } label: {

            Image(systemName: "chevron.left")
                .font(.title3)
                .frame(width: 20, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(.leading, 15)
        .padding(.top, 5)
    }

    // MARK: - Indicator

    private var indicatorView: some View {

        HStack(spacing: 6) {

            ForEach(items.indices, id: \.self) { index in

                let isCurrentPage =
                    index == currentPage

                Capsule()
                    .fill(
                        .primary.opacity(
                            isCurrentPage ? 1 : 0.4
                        )
                    )
                    .frame(
                        width: isCurrentPage ? 25 : 6,
                        height: 6
                    )
            }
        }
        .padding(.bottom, 5)
    }

    // MARK: - Text Content

    private var textContentView: some View {

        GeometryReader { geometry in

            let size = geometry.size

            ScrollView(.horizontal) {

                HStack(spacing: 0) {

                    ForEach(items.indices, id: \.self) { index in

                        let item = items[index]

                        let isActive =
                            currentPage == index

                        VStack(spacing: 6) {

                            Text(item.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)

                            Text(item.subtitle)
                                .font(.callout)
                                .lineLimit(2)
                                .opacity(0.8)
                                .multilineTextAlignment(.center)
                        }
                        .scrollTargetLayout()
                        .frame(
                            width: size.width,
                            alignment: .center
                        )
                        .compositingGroup()
                        .blur(radius: isActive ? 0 : 30)
                        .opacity(isActive ? 1 : 0)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(true)
            .scrollClipDisabled()
            .scrollTargetBehavior(.paging)
            .scrollPosition(
                id: .init(
                    get: {
                        currentPage
                    },
                    set: { _ in }
                )
            )
        }
    }

    // MARK: - Screenshot View

    private var screenshotView: some View {

        let shape = ConcentricRectangle(
            corners: .concentric,
            isUniform: true
        )

        return GeometryReader { geometry in

            let size = geometry.size

            Rectangle()
                .fill(.opacity(0))

            ScrollView(.horizontal) {

                HStack(spacing: 12) {

                    ForEach(items.indices, id: \.self) { index in

                        let item = items[index]

                        Group {

                            if let screenshot = item.screenshot {

                                Image(uiImage: screenshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .onGeometryChange(
                                        for: CGSize.self
                                    ) {
                                        $0.size
                                    } action: { newValue in
                                        screenshotSize = newValue
                                    }
                                    .clipShape(shape)

                            } else {

                                Rectangle()
                                    .fill(.black)
                            }
                        }
                        .frame(
                            width: size.width,
                            height: size.height
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollDisabled(true)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(
                id: .init(
                    get: {
                        currentPage
                    },
                    set: { _ in }
                )
            )
        }
        .clipShape(shape)
        .overlay {

            if screenshotSize != .zero {

                ZStack {

                    shape
                        .stroke(.white, lineWidth: 6)

                    shape
                        .stroke(.black, lineWidth: 4)

                    shape
                        .stroke(.black, lineWidth: 6)
                        .padding(4)
                }
                .padding(-6)
            }
        }
        .frame(
            maxWidth:
                screenshotSize.width == 0
                ? nil
                : screenshotSize.width,

            maxHeight:
                screenshotSize.height == 0
                ? nil
                : screenshotSize.height
        )
        .containerShape(
            RoundedRectangle(
                cornerRadius: deviceCornerRadius
            )
        )
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Glass Blur

    @ViewBuilder
    private func variableGlassBlur(
        _ radius: CGFloat
    ) -> some View {

        let tint =
            Color("inversePrimary")
                .opacity(0.5)

        Rectangle()
            .fill(tint)
            .glassEffect(
                .clear.tint(tint),
                in: .rect
            )
            .blur(radius: radius)
            .padding(
                [.horizontal, .bottom],
                -radius * 2
            )
            .padding(.top, -radius / 2)
            .opacity(
                items[currentPage].zoomScale != 1
                ? 1
                : 0
            )
            .ignoresSafeArea()
    }
}

#Preview {

    OnBoardingView()
}
