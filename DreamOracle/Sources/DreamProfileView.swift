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
            Text("Profil")
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
            Text("Kredi Cüzdanı")
                .font(DreamTheme.medium(23))
                .foregroundStyle(Color.white)

            HStack(spacing: 12) {
                statTile(title: "Ucretsiz Hak", value: "\(viewModel.freeRemaining)/2")
                statTile(title: "Kredi", value: "\(viewModel.credits)")
            }
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("İstatistik")
                .font(DreamTheme.medium(23))
                .foregroundStyle(Color.white)

            HStack(spacing: 12) {
                statTile(title: "Toplam Ruya", value: "\(viewModel.dreamRecords.count)")
                statTile(
                    title: "Ucretli Soru",
                    value: "\(viewModel.dreamRecords.reduce(0) { $0 + $1.followUps.count })"
                )
            }
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private var creditsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kredi Satın Al")
                .font(DreamTheme.medium(23))
                .foregroundStyle(Color.white)

            Button("+5 Kredi") {
                viewModel.purchaseCredits(5)
            }
            .dreamGoldButton()

            HStack(spacing: 10) {
                Button("+15 Kredi") {
                    viewModel.purchaseCredits(15)
                }
                .dreamGoldButton()

                Button("+40 Kredi") {
                    viewModel.purchaseCredits(40)
                }
                .dreamGoldButton()
            }
        }
        .dreamCard(light: false, cornerRadius: 22)
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bilgi")
                .font(DreamTheme.medium(20))
                .foregroundStyle(Color.white)
            Text("İlk 2 rüya yorumu ücretsizdir. Sonraki her yorum ve her takip sorusu 1 kredi kullanır.")
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
