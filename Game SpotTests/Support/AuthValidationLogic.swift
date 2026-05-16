//
//  AuthValidationLogic.swift
//  Game SpotTests
//
//  Mirrors sign-up password rules from `AuthView` (passwordChecks / canSubmit).
//

import Foundation

enum AuthValidationLogic {

    struct PasswordCheck: Identifiable {
        let id = UUID()
        let title: String
        let passed: Bool
    }

    // MARK: - Sign Up Rules (AuthView)

    static func passwordChecks(for password: String) -> [PasswordCheck] {
        [
            PasswordCheck(
                title: "At least 8 characters",
                passed: password.count >= 8
            ),
            PasswordCheck(
                title: "One uppercase letter",
                passed: password.range(
                    of: "[A-Z]",
                    options: .regularExpression
                ) != nil
            ),
            PasswordCheck(
                title: "One number",
                passed: password.range(
                    of: "[0-9]",
                    options: .regularExpression
                ) != nil
            )
        ]
    }

    static func passwordStrongEnough(for password: String) -> Bool {
        passwordChecks(for: password).allSatisfy(\.passed)
    }

    static func passwordsMatch(
        password: String,
        confirmPassword: String
    ) -> Bool {
        password == confirmPassword
    }

    static func canSubmitSignUp(
        email: String,
        password: String,
        confirmPassword: String,
        viewModelIsValid: Bool
    ) -> Bool {
        viewModelIsValid
            && passwordStrongEnough(for: password)
            && passwordsMatch(
                password: password,
                confirmPassword: confirmPassword
            )
            && !confirmPassword.isEmpty
    }
}
