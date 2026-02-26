import SwiftUI

struct DreamProfileView: View {
    @ObservedObject var viewModel: DreamInterpreterViewModel
    @Environment(\.usesSharedTabPanoramaBackground) private var usesSharedTabPanoramaBackground

    var body: some View {
        ZStack {
            if !usesSharedTabPanoramaBackground {
                DreamBackground()
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: DreamLayout.sectionSpacing) {
                    topBar
                    walletCard
                    statsCard
                    creditsCard
                    noteCard
                }
                .padding(.horizontal, DreamLayout.screenHorizontal)
                .padding(.top, DreamLayout.screenTop)
                .padding(.bottom, DreamLayout.screenBottom)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var topBar: some View {
        HStack {
            Text(String(localized: "profile.title"))
                .font(DreamTheme.heading(34))
                .foregroundStyle(Color.white)
            Spacer()
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(Color.white.opacity(0.9))
        }
    }

    private var walletCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "profile.wallet"))
                .font(DreamTheme.medium(23))
                .foregroundStyle(Color.white)

            HStack(spacing: 12) {
                statTile(title: String(localized: "profile.stat.free"), value: "\(viewModel.freeRemaining)/2")
                statTile(title: String(localized: "profile.stat.credit"), value: "\(viewModel.credits)")
            }
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "profile.stats"))
                .font(DreamTheme.medium(23))
                .foregroundStyle(Color.white)

            HStack(spacing: 12) {
                statTile(title: String(localized: "profile.stat.total_dreams"), value: "\(viewModel.dreamRecords.count)")
                statTile(
                    title: String(localized: "profile.stat.paid_questions"),
                    value: "\(viewModel.dreamRecords.reduce(0) { $0 + $1.followUps.count })"
                )
            }
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "profile.buy_credits"))
                .font(DreamTheme.medium(23))
                .foregroundStyle(Color.white)

            Button(String(localized: "profile.pack.5")) {
                viewModel.purchaseCredits(5)
            }
            .dreamGoldButton()

            HStack(spacing: 10) {
                Button(String(localized: "profile.pack.15")) {
                    viewModel.purchaseCredits(15)
                }
                .dreamGoldButton()

                Button(String(localized: "profile.pack.40")) {
                    viewModel.purchaseCredits(40)
                }
                .dreamGoldButton()
            }
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(localized: "profile.info"))
                .font(DreamTheme.medium(20))
                .foregroundStyle(Color.white)
            Text(String(localized: "profile.note.pricing"))
                .font(DreamTheme.body(16))
                .foregroundStyle(Color.white.opacity(0.86))
        }
        .dreamCard(light: false, cornerRadius: 20)
    }

    private func statTile(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DreamTheme.body(14))
                .foregroundStyle(Color.white.opacity(0.72))
            Text(value)
                .font(DreamTheme.medium(26))
                .foregroundStyle(Color.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
