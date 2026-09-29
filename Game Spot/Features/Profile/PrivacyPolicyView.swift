import SwiftUI

struct PrivacyPolicyView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                introduction

                policySection(
                    title: "Information We Collect",
                    text: "GameSpot stores the email address and user ID needed for your account. If you complete your profile, it also stores your username, avatar, favorite sport, ratings, match history, team membership, MVP votes, and park reviews. When you use safety features, GameSpot stores reports you submit, optional report details, a snapshot of the reported profile, and your private blocked users list. Supabase may retain technical request logs such as IP address, IP-derived country, user-agent, timestamp, route, and response status for service operation and security."
                )

                policySection(
                    title: "Location",
                    text: "With your permission, GameSpot uses your precise location while the app is open to show your position on the map and help you find nearby sports parks. Your precise device location is processed on your device and is not sent to or stored by GameSpot or Supabase. Like most internet services, Supabase may process your IP address and an approximate country derived from it in technical logs. You can change precise location access at any time in iOS Settings."
                )

                policySection(
                    title: "How We Use Information",
                    text: "We use account, profile, gameplay, and safety information only to provide authentication, profiles, games, teams, rankings, MVP voting, park ratings, account support, report review, abuse prevention, and blocking preferences. GameSpot does not use this information for advertising or cross-app tracking."
                )

                policySection(
                    title: "Sharing and Visibility",
                    text: "Supabase processes account and app data as GameSpot’s backend service provider. Your username, avatar, ratings, gameplay statistics, game participation, and reviews may be visible to other signed-in GameSpot users where required by the app’s social and multiplayer features. We do not sell personal information."
                )

                policySection(
                    title: "Retention and Deletion",
                    text: "We retain account and app data while your account is active. You can request deletion directly in Profile by choosing Delete Account. When deletion completes, your authentication account, profile, avatar, participation records, MVP votes, reports, blocking records, and reviews are deleted or anonymized where a game record must remain consistent. Limited moderation records may be retained when reasonably necessary for security, abuse prevention, or legal compliance. Service-provider backups and security logs may remain temporarily under the provider’s retention schedule."
                )

                policySection(
                    title: "Security",
                    text: "GameSpot uses authenticated connections and database access controls to protect app data. No internet service can guarantee absolute security, so please use a unique password and keep your device secure."
                )

                policySection(
                    title: "Children",
                    text: "GameSpot is not directed to children under 13, and we do not knowingly collect personal information from children under 13."
                )

                policySection(
                    title: "Contact",
                    text: "For privacy questions, deletion assistance, or support, email gamespot.support@icloud.com."
                )
            }
            .padding(20)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("privacyPolicy.screen")
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GameSpot Privacy Policy")
                .font(.largeTitle)
                .bold()

            Text("Last updated: September 14, 2026")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(
                "This policy explains what information GameSpot handles and how it is used when you use the iOS app."
            )
            .font(.body)
        }
    }

    private func policySection(
        title: String,
        text: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2)
                .bold()

            Text(text)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
