import Foundation

struct PasswordCheck: Identifiable, Equatable {

    let id: String

    let title: String

    let passed: Bool
}

enum PasswordPolicy {

    static func checks(
        for password: String
    ) -> [PasswordCheck] {

        [
            PasswordCheck(
                id: "length",
                title: "At least 8 characters",
                passed: password.count >= 8
            ),
            PasswordCheck(
                id: "uppercase",
                title: "One uppercase letter",
                passed: password.range(
                    of: "[A-Z]",
                    options: .regularExpression
                ) != nil
            ),
            PasswordCheck(
                id: "number",
                title: "One number",
                passed: password.range(
                    of: "[0-9]",
                    options: .regularExpression
                ) != nil
            )
        ]
    }

    static func isValid(
        _ password: String
    ) -> Bool {

        checks(for: password).allSatisfy(\.passed)
    }

    static func passwordsMatch(
        _ password: String,
        confirmation: String
    ) -> Bool {

        !confirmation.isEmpty && password == confirmation
    }
}
