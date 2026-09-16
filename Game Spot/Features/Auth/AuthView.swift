import SwiftUI

struct AuthView: View {

    // MARK: - View Model

    @StateObject private var vm =
        AuthViewModel()

    // MARK: - Environment

    @EnvironmentObject var session:
        SessionManager

    @EnvironmentObject var authLinks:
        AuthLinkCoordinator

    // MARK: - State

    @State private var isLogin = true

    @State private var confirmPassword = ""

    @State private var showPassword = false

    @State private var showConfirmPassword = false

    @State private var showsPasswordReset = false

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

        PasswordPolicy.checks(
            for: vm.password
        )
    }

    private var passwordStrongEnough: Bool {

        PasswordPolicy.isValid(vm.password)
    }

    private var passwordsMatch: Bool {

        PasswordPolicy.passwordsMatch(
            vm.password,
            confirmation: confirmPassword
        )
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
        .sheet(isPresented: $showsPasswordReset) {
            PasswordResetRequestView(
                initialEmail: vm.email
            )
        }
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

            if let email = vm.pendingConfirmationEmail {

                confirmationRequiredSection(email: email)

            } else {

                formSection

                feedbackSection

                mainButton

                switchModeButton
            }
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

            if isLogin {
                forgotPasswordButton
            }

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

    var feedbackSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            if let notice = session.authNotice {

                Label(
                    notice,
                    systemImage: "checkmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.green)
                .accessibilityIdentifier("auth.notice")
            }

            if let confirmationError = authLinks.emailConfirmationError {

                Label(
                    confirmationError,
                    systemImage: "exclamationmark.circle.fill"
                )
                .font(.subheadline)
                .foregroundStyle(.red)
                .accessibilityIdentifier("auth.confirmation.error")
            }

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
                .accessibilityIdentifier("auth.error")
            }
        }
    }

    var forgotPasswordButton: some View {

        Button("Forgot password?") {
            session.clearAuthNotice()
            showsPasswordReset = true
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color("AccentColor"))
        .frame(maxWidth: .infinity, alignment: .trailing)
        .accessibilityIdentifier("auth.forgotPassword")
    }

    @ViewBuilder
    func confirmationRequiredSection(
        email: String
    ) -> some View {

        Image(systemName: "envelope.badge")
            .font(.system(size: 44, weight: .semibold))
            .foregroundStyle(primary)

        Text("Check Your Email")
            .font(.title2.bold())

        Text(
            "We sent a confirmation link to \(email). Open it on this device to finish creating your account."
        )
        .multilineTextAlignment(.center)
        .foregroundStyle(.secondary)

        if let statusMessage = vm.statusMessage {
            Label(
                statusMessage,
                systemImage: "checkmark.circle.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.green)
        }

        if let errorMessage = vm.errorMessage {
            Label(
                errorMessage,
                systemImage: "exclamationmark.circle.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.red)
        }

        Button("Resend Confirmation Email") {
            vm.resendSignUpConfirmation()
        }
        .buttonStyle(.glassProminent)
        .tint(primary)
        .disabled(vm.isLoading)
        .accessibilityIdentifier("auth.confirmation.resend")

        Button("Back to Sign In") {
            vm.returnToSignIn()
            isLogin = true
        }
        .disabled(vm.isLoading)
        .accessibilityIdentifier("auth.confirmation.back")
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
            .frame(
                maxWidth: isLogin ? .infinity : 260
            )
            .frame(height: isLogin ? 58 : 50)
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

    var switchModeButton: some View {

        Button {

            withAnimation(.spring) {
                isLogin.toggle()
                confirmPassword = ""
                vm.resetFeedback()
                session.clearAuthNotice()
                authLinks.reset()
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

#Preview {
    AuthView()
        .environmentObject(
            SessionManager(restoreSessionOnInit: false)
        )
        .environmentObject(AuthLinkCoordinator())
}
