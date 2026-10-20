import SwiftUI

struct PerformanceView: View {
    let practice: Bool
    let autoSave: Bool
    let delay: Double
    let haptics: Bool
    @ObservedObject var photos: PhotoStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var card: Card?
    @State private var pending = false
    @State private var revealTask: Task<Void, Never>?
    @State private var saved = false
    @State private var favorite = false
    @State private var failure: String?
    @State private var date = Date()
    @State private var zoom = false
    @State private var activeCell: Int?
    private var canReset: Bool { !photos.busy }
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { reset() } label: { Image(systemName: "chevron.left").font(.title3.weight(.semibold)).frame(width: 40, height: 44) }
                    .disabled(!canReset).accessibilityLabel("重新选牌")
                Spacer()
                VStack(spacing: 3) {
                    Text(practice ? "手势练习" : date.formatted(.dateTime.month().day())).font(.subheadline.bold())
                    Text(practice ? "↗ ♠  ↘ ♥  ↙ ♣  ↖ ♦" : date.formatted(.dateTime.hour().minute()))
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("重新选牌", systemImage: "arrow.counterclockwise") { reset() }.disabled(!canReset)
                    Button("结束表演", systemImage: "xmark") { cancel(); dismiss() }.disabled(!canReset)
                } label: { Image(systemName: "ellipsis.circle").font(.title3).frame(width: 40, height: 44) }.accessibilityLabel("表演菜单")
            }.padding(.horizontal, 12).padding(.vertical, 5).foregroundStyle(.primary)
            GeometryReader { geometry in
                ZStack {
                    Color.black
                    if let card {
                        Image(uiImage: card.image).resizable().scaledToFit()
                            .scaleEffect(zoom ? 1.6 : 1)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .onTapGesture(count: 2) { withAnimation { zoom.toggle() } }
                            .accessibilityLabel(card.name)
                    } else {
                        if practice {
                            VStack(spacing: 0) {
                                ForEach(0..<5) { row in
                                    HStack(spacing: 0) {
                                        ForEach(0..<3) { column in
                                            let index = row * 3 + column
                                            Text(Card.ranks[index]).font(.title2.bold())
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .background(activeCell == index ? Color.white.opacity(0.25) : .clear)
                                                .border(.white.opacity(0.35), width: 0.5)
                                        }
                                    }
                                }
                            }.foregroundStyle(.white)
                        }
                    }
                }.contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in
                            guard practice, card == nil, !pending else { return }
                            let column = min(2, max(0, Int(value.startLocation.x / (geometry.size.width / 3))))
                            let row = min(4, max(0, Int(value.startLocation.y / (geometry.size.height / 5))))
                            activeCell = row * 3 + column
                        }
                        .onEnded { value in
                            activeCell = nil
                            guard card == nil, !pending else { return }
                            if let result = CardGesture.resolve(x: value.startLocation.x, y: value.startLocation.y, width: geometry.size.width, height: geometry.size.height, dx: value.translation.width, dy: value.translation.height) {
                                select(result)
                            }
                        })
            }
            if practice {
                Text(card.map { "已选中：\($0.name) · 点左上角继续练习" } ?? (pending ? "已接收手势，等待揭晓…" : "在格子内按下，再向斜方向滑动；大小王可直接点按。"))
                    .font(.footnote).multilineTextAlignment(.center).padding(12).frame(maxWidth: .infinity).background(.thinMaterial)
            }
            HStack(spacing: 3) {
                ForEach(0..<9) { index in
                    if index == 4, let card {
                        Image(uiImage: card.image).resizable().scaledToFit().frame(width: 29, height: 39).background(.white).clipShape(RoundedRectangle(cornerRadius: 3))
                    } else {
                        RoundedRectangle(cornerRadius: 3).fill(Color(hue: Double(index) * 0.035 + 0.08, saturation: 0.12, brightness: 0.55 + Double(index % 3) * 0.1)).frame(width: 24, height: 32)
                    }
                }
            }.frame(maxWidth: .infinity).padding(.vertical, 14).accessibilityHidden(true)
            HStack {
                if let card {
                    ShareLink(item: Image(uiImage: card.image), preview: SharePreview(card.name, image: Image(uiImage: card.image))) {
                        Image(systemName: "square.and.arrow.up").frame(width: 44, height: 44)
                    }.accessibilityLabel("分享牌面")
                } else {
                    Image(systemName: "square.and.arrow.up").foregroundStyle(.tertiary).frame(width: 44, height: 44)
                }
                Spacer()
                Button { favorite.toggle() } label: { Image(systemName: favorite ? "heart.fill" : "heart").frame(width: 44, height: 44) }.disabled(card == nil).accessibilityLabel("收藏")
                Spacer()
                Button { Task { await save() } } label: {
                    Group {
                        if photos.busy { ProgressView() } else { Image(systemName: saved ? "checkmark.circle" : "square.and.arrow.down") }
                    }.frame(width: 44, height: 44)
                }.disabled(card == nil || saved || photos.busy || practice).accessibilityLabel(saved ? "已保存到相册" : "保存到相册")
                Spacer()
                Button { reset() } label: { Image(systemName: "arrow.counterclockwise").frame(width: 44, height: 44) }.disabled(!canReset).accessibilityLabel("重新选牌")
            }.font(.title3).padding(.horizontal, 24)
        }.background(.white).interactiveDismissDisabled().persistentSystemOverlays(.hidden)
            .alert("照片未保存", isPresented: Binding(get: { failure != nil }, set: { if !$0 { failure = nil } })) {
                Button("知道了", role: .cancel) { failure = nil }
            } message: { Text(failure ?? "") }
            .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
            .onDisappear { cancel(); UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of: scenePhase) { _, phase in if phase != .active { cancel() } }
    }
    private func select(_ result: Card) {
        pending = true
        if haptics { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
        revealTask = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard !Task.isCancelled else { return }
            card = result
            date = Date()
            pending = false
            if autoSave && !practice { await save() }
        }
    }
    private func save() async {
        guard let card, !saved, !practice else { return }
        if await photos.save(card) { saved = true }
        else { failure = photos.message }
    }
    private func cancel() { revealTask?.cancel(); revealTask = nil; pending = false; activeCell = nil }
    private func reset() { cancel(); card = nil; saved = false; favorite = false; zoom = false; failure = nil }
}
