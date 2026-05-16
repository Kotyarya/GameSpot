import SwiftUI

struct LoadingView: View {

    // MARK: - Animation State

    @State private var pulseLogo = false

    @State private var animateDots = false

    // MARK: - Body

    var body: some View {

        ZStack {

            backgroundGradient

            content
        }
        .onAppear {

            pulseLogo = true
            animateDots = true
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {

        LinearGradient(
            colors: [

                Color(
                    red: 28 / 255,
                    green: 24 / 255,
                    blue: 72 / 255
                ),

                Color(
                    red: 76 / 255,
                    green: 66 / 255,
                    blue: 190 / 255
                ),

                Color(
                    red: 187 / 255,
                    green: 186 / 255,
                    blue: 255 / 255
                )
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Content

    private var content: some View {

        VStack(spacing: 38) {

            logoSection

            titleSection

            loaderSection
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(.horizontal, 32)
    }

    // MARK: - Logo

    private var logoSection: some View {

        ZStack {

            Circle()
                .stroke(
                    .white.opacity(0.16),
                    lineWidth: 2
                )
                .frame(width: 210, height: 210)

            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: 170, height: 170)
                .overlay {

                    Circle()
                        .stroke(
                            .white.opacity(0.14),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: .black.opacity(0.12),
                    radius: 18,
                    y: 10
                )

            Image(systemName: "trophy.fill")
                .font(
                    .system(
                        size: 68,
                        weight: .black
                    )
                )
                .foregroundStyle(
                    Color("AccentColor")
                )
                .scaleEffect(
                    pulseLogo ? 1.06 : 0.96
                )
                .shadow(
                    color: .white.opacity(0.35),
                    radius: 10
                )
                .animation(
                    .easeInOut(duration: 1.8)
                        .repeatForever(
                            autoreverses: true
                        ),
                    value: pulseLogo
                )
        }
        .drawingGroup()
    }

    // MARK: - Title

    private var titleSection: some View {

        Text("Game Spot")
            .font(
                .system(
                    size: 50,
                    weight: .bold
                )
            )
            .fontDesign(.rounded)
            .foregroundStyle(.white)
    }

    // MARK: - Loader

    private var loaderSection: some View {

        HStack(spacing: 12) {

            ForEach(0..<3, id: \.self) { index in

                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .scaleEffect(
                        animateDots ? 1 : 0.5
                    )
                    .opacity(
                        animateDots ? 1 : 0.25
                    )
                    .animation(
                        .easeInOut(duration: 0.75)
                            .repeatForever()
                            .delay(
                                Double(index) * 0.16
                            ),
                        value: animateDots
                    )
            }
        }
    }
}

#Preview {

    LoadingView()
}
