import SwiftUI
import AuthenticationServices

struct AuthView: View {

    // MARK: - View Model

    @StateObject private var vm =
        AuthViewModel()

    // MARK: - Environment

    @EnvironmentObject var session:
        SessionManager

    // MARK: - State

    @State private var isLogin = true

    @State private var confirmPassword = ""

    @State private var showPassword = false

    @State private var showConfirmPassword = false

    @FocusState private var focusedField: Field?

    // MARK: - Constants

    private let primary = Color("AccentColor")

    // MARK: - Focus Field

    enum Field {
        case email
        case password
    }

    // MARK: - Validation

    private var passwordChecks: [PasswordCheck] {

        [
            PasswordCheck(
                title: "At least 8 characters",
                passed: vm.password.count >= 8
            ),

            PasswordCheck(
                title: "One uppercase letter",
                passed:
                    vm.password.range(
                        of: "[A-Z]",
                        options: .regularExpression
                    ) != nil
            ),

            PasswordCheck(
                title: "One number",
                passed:
                    vm.password.range(
                        of: "[0-9]",
                        options: .regularExpression
                    ) != nil
            )
        ]
    }

    private var passwordStrongEnough: Bool {

        passwordChecks.allSatisfy(\.passed)
    }

    private var passwordsMatch: Bool {

        vm.password == confirmPassword
    }

    private var canSubmit: Bool {

        if isLogin {
            return vm.isValid
        }

        return
            vm.isValid
            && passwordStrongEnough
            && passwordsMatch
            && !confirmPassword.isEmpty
    }

    // MARK: - Body

    var body: some View {

        ZStack {

            backgroundGradient

            ScrollView(showsIndicators: false) {

                VStack(spacing: 28) {

                    Spacer(minLength: 30)

                    headerSection

                    authCard

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .disabled(vm.isLoading)

            loadingOverlay
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: vm.isLoading
        )
    }
}

// MARK: - Sections

private extension AuthView {

    var backgroundGradient: some View {

        LinearGradient(
            colors: [
                Color("AccentColor").opacity(0.3),
                Color("inversePrimary")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    var headerSection: some View {

        VStack(spacing: 22) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 42,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            Color(
                                red: 187 / 255,
                                green: 186 / 255,
                                blue: 255 / 255
                            ),

                            Color(
                                red: 110 / 255,
                                green: 102 / 255,
                                blue: 240 / 255
                            )
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 138, height: 138)
                .shadow(
                    color: Color("AccentColor").opacity(0.25),
                    radius: 24,
                    y: 14
                )

                Image(systemName: "trophy.fill")
                    .font(
                        .system(
                            size: 62,
                            weight: .black
                        )
                    )
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
                    .shadow(
                        color: .white.opacity(0.35),
                        radius: 12
                    )
            }

            VStack(spacing: 10) {

                Text("SportMap")
                    .font(
                        .system(
                            size: 42,
                            weight: .bold
                        )
                    )
                    .fontDesign(.rounded)

                Text(
                    isLogin
                    ? "Find players. Join games. Compete."
                    : "Create your account and start competing."
                )
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 16)
    }

    var authCard: some View {

        VStack(spacing: 22) {

            formSection

            errorSection

            mainButton

            dividerSection

            appleButton

            switchModeButton
        }
        .padding(24)
        .glassEffect(
            .regular
                .tint(
                    Color("inversePrimary").opacity(0.55)
                )
                .interactive(true),

            in: RoundedRectangle(
                cornerRadius: 34,
                style: .continuous
            )
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 20,
            y: 12
        )
    }

    var formSection: some View {

        VStack(spacing: 18) {

            emailField

            passwordField

            if !isLogin {
                confirmPasswordField
            }

            if !isLogin && !vm.password.isEmpty {
                passwordValidationSection
            }
        }
    }

    var emailField: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Email")
                .font(.headline)

            HStack(spacing: 12) {

                Image(systemName: "envelope.fill")
                    .foregroundStyle(primary)

                TextField(
                    "Enter your email",
                    text: $vm.email
                )
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .focused(
                    $focusedField,
                    equals: .email
                )
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(Color("inversePrimary").opacity(0.85))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
        }
    }

    var passwordField: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Password")
                .font(.headline)

            HStack(spacing: 12) {

                Image(systemName: "lock.fill")
                    .foregroundStyle(Color("AccentColor"))

                Group {

                    if showPassword {

                        TextField(
                            "Enter your password",
                            text: $vm.password
                        )

                    } else {

                        SecureField(
                            "Enter your password",
                            text: $vm.password
                        )
                    }
                }
                .focused(
                    $focusedField,
                    equals: .password
                )

                Button {

                    showPassword.toggle()

                } label: {

                    Image(
                        systemName:
                            showPassword
                        ? "eye.slash.fill"
                        : "eye.fill"
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(Color("inversePrimary").opacity(0.85))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )
        }
    }

    var confirmPasswordField: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Confirm Password")
                .font(.headline)

            HStack(spacing: 12) {

                Image(systemName: "lock.rotation")
                    .foregroundStyle(Color("AccentColor"))

                Group {

                    if showConfirmPassword {

                        TextField(
                            "Repeat your password",
                            text: $confirmPassword
                        )

                    } else {

                        SecureField(
                            "Repeat your password",
                            text: $confirmPassword
                        )
                    }
                }

                Button {

                    showConfirmPassword.toggle()

                } label: {

                    Image(
                        systemName:
                            showConfirmPassword
                        ? "eye.slash.fill"
                        : "eye.fill"
                    )
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(Color("inversePrimary").opacity(0.85))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
            )

            if !confirmPassword.isEmpty {

                HStack(spacing: 8) {

                    Image(
                        systemName:
                            passwordsMatch
                        ? "checkmark.circle.fill"
                        : "xmark.circle.fill"
                    )
                    .foregroundStyle(
                        passwordsMatch
                        ? .green
                        : .red
                    )

                    Text(
                        passwordsMatch
                        ? "Passwords match"
                        : "Passwords do not match"
                    )
                    .font(.subheadline)
                    .foregroundStyle(
                        passwordsMatch
                        ? .green
                        : .red
                    )
                }
                .padding(.top, 2)
            }
        }
    }

    var passwordValidationSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            ForEach(passwordChecks) { check in

                HStack(spacing: 10) {

                    Image(
                        systemName:
                            check.passed
                        ? "checkmark.circle.fill"
                        : "circle"
                    )
                    .foregroundStyle(
                        check.passed
                        ? .green
                        : .secondary
                    )

                    Text(check.title)
                        .font(.subheadline)
                        .foregroundStyle(
                            check.passed
                            ? .primary
                            : .secondary
                        )
                }
            }
        }
        .padding(.top, 2)
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    var errorSection: some View {

        Group {

            if let error = vm.errorMessage {

                HStack(spacing: 10) {

                    Image(
                        systemName:
                            "exclamationmark.circle.fill"
                    )

                    Text(error)
                        .font(.subheadline)
                }
                .foregroundStyle(.red)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
        }
    }

    var mainButton: some View {

        Button {

            if isLogin {

                vm.signIn(session: session)

            } else {

                vm.signUp(session: session)
            }

        } label: {

            ZStack {

                Text(
                    isLogin
                    ? "Sign In"
                    : "Create Account"
                )
                .font(.headline)
                .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
        }
        .buttonStyle(.glassProminent)
        .tint(Color("AccentColor"))
        .disabled(
            !canSubmit
            || vm.isLoading
        )
        .opacity(
            canSubmit
            ? 1
            : 0.6
        )
    }

    var dividerSection: some View {

        HStack {

            Rectangle()
                .fill(.gray.opacity(0.25))
                .frame(height: 1)

            Text("or")
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)

            Rectangle()
                .fill(.gray.opacity(0.25))
                .frame(height: 1)
        }
    }

    var appleButton: some View {

        SignInWithAppleButton(
            isLogin
            ? .signIn
            : .signUp
        ) { request in

            request.requestedScopes = [
                .fullName,
                .email
            ]

        } onCompletion: { _ in

            vm.signInWithApple(
                session: session
            )
        }
        .frame(height: 56)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18,
                style: .continuous
            )
        )
        .disabled(true)
    }

    var switchModeButton: some View {

        Button {

            withAnimation(.spring) {
                isLogin.toggle()
            }

        } label: {

            HStack(spacing: 4) {

                Text(
                    isLogin
                    ? "No account?"
                    : "Already have an account?"
                )

                Text(
                    isLogin
                    ? "Sign Up"
                    : "Sign In"
                )
                .fontWeight(.bold)
            }
            .font(.subheadline)
        }
        .foregroundStyle(Color("AccentColor"))
    }

    var loadingOverlay: some View {

        Group {

            if vm.isLoading {

                ZStack {

                    Rectangle()
                        .fill(.black.opacity(0.08))
                        .ignoresSafeArea()

                    LoadingView()
                        .transition(
                            .opacity.combined(
                                with: .scale(scale: 0.96)
                            )
                        )
                }
                .zIndex(999)
            }
        }
    }
}

// MARK: - Password Check

struct PasswordCheck: Identifiable {

    let id = UUID()

    let title: String

    let passed: Bool
}

#Preview {
    AuthView()
}
