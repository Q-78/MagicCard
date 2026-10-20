import SwiftUI

@main
struct MagicCardApp: App {
    var body: some Scene { WindowGroup { HomeView().preferredColorScheme(.light) } }
}

struct HomeView: View {
    @StateObject private var photos = PhotoStore()
    @AppStorage("autoSave") private var autoSave = false
    @AppStorage("revealDelayV2") private var delay = 0.2
    @AppStorage("haptics") private var haptics = true
    @Environment(\.scenePhase) private var scenePhase
    @State private var session: Session?
    @State private var showCredits = false
    struct Session: Identifiable { let id = UUID(); let practice: Bool }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("MAGIC CARD").font(.caption.weight(.bold)).tracking(3).foregroundStyle(.secondary)
                            Text("让心中的牌，\n出现在照片里。").font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("一个只属于你的掌上魔术。").foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "suit.spade.fill").font(.system(size: 50)).rotationEffect(.degrees(12)).padding(.top, 32)
                    }
                    HStack(spacing: -14) {
                        ForEach(Array([Card(rank: 1, suit: 0), Card(rank: 12, suit: 1), Card(rank: 13, suit: 0)].enumerated()), id: \.offset) { index, card in
                            Image(uiImage: card.image).resizable().scaledToFit().frame(height: 170)
                                .clipShape(RoundedRectangle(cornerRadius: 9))
                                .shadow(color: .black.opacity(0.13), radius: 12, y: 6)
                                .rotationEffect(.degrees(Double(index - 1) * 9))
                        }
                    }.frame(maxWidth: .infinity).padding(.vertical, 12).accessibilityHidden(true)
                    VStack(spacing: 12) {
                        Button { session = Session(practice: false) } label: {
                            Label("开始表演", systemImage: "sparkles").frame(maxWidth: .infinity).padding(10)
                        }.buttonStyle(.borderedProminent).tint(.black)
                        Button { session = Session(practice: true) } label: {
                            Label("先练习秘密手势", systemImage: "hand.draw").frame(maxWidth: .infinity).padding(7)
                        }.buttonStyle(.bordered).tint(.black)
                    }
                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label("表演前准备", systemImage: "checkmark.circle").font(.headline)
                            Text("先授权，再开启自动保存。练习模式不会保存图片，也不会弹出权限请求。")
                                .font(.subheadline).foregroundStyle(.secondary)
                            if photos.allowed {
                                Label("已允许添加照片", systemImage: "checkmark.shield.fill").foregroundStyle(.green)
                            } else {
                                Button("允许添加照片") { Task { await photos.authorize() } }.buttonStyle(.bordered)
                                if photos.authorization == .denied || photos.authorization == .restricted {
                                    Button("打开系统设置") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                                    }
                                }
                            }
                            Toggle("揭晓后自动保存", isOn: $autoSave)
                            Toggle("选牌震动反馈", isOn: $haptics)
                            HStack {
                                Text("揭晓延迟")
                                Spacer()
                                Picker("揭晓延迟", selection: $delay) {
                                    Text("立即").tag(0.0)
                                    Text("0.2 秒").tag(0.2)
                                    Text("0.5 秒").tag(0.5)
                                    Text("2 秒").tag(2.0)
                                }.labelsHidden()
                            }
                            if autoSave && !photos.allowed {
                                Text("自动保存尚不可用，请先允许添加照片。").font(.caption).foregroundStyle(.orange)
                            }
                        }.padding(4)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("秘密藏在指尖").font(.title3.bold())
                        Text("在照片区域的隐形 3×5 网格中按下，位置决定点数；向右上 ↗ 滑动为黑桃，右下 ↘ 红桃，左下 ↙ 梅花，左上 ↖ 方块。最后一行依次为 K、小王、大王。")
                        Text("揭晓后点左上角返回，可重新选牌；点右上角菜单结束表演。自动保存失败会显示可重试的提示。")
                    }.font(.subheadline).foregroundStyle(.secondary)
                    Button("关于与素材来源") { showCredits = true }.font(.footnote)
                    Text("照片风格界面由 Magic Card 提供。仅添加你揭晓的牌面，不读取个人相册。")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(24)
            }.background(Color(uiColor: .systemGroupedBackground))
                .navigationBarHidden(true)
        }
        .fullScreenCover(item: $session) { session in
            PerformanceView(practice: session.practice, autoSave: autoSave, delay: delay, haptics: haptics, photos: photos)
        }
        .sheet(isPresented: $showCredits) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Magic Card · 初版").font(.title.bold())
                        Text("手势逻辑参考 HuaweiREN/Wombat_Magic_Poker，牌面图片来自该工程。原工程声明图片来自 GitCode open-source-toolkit/77d38。")
                        Link("查看参考工程", destination: URL(string: "https://github.com/HuaweiREN/Wombat_Magic_Poker")!)
                        Text("本 App 无需注册，不联网，不读取相册，不使用麦克风。照片仅在用户开启自动保存或手动保存时写入系统照片库。")
                        Text((try? String(contentsOf: Bundle.main.url(forResource: "Wombat-LICENSE", withExtension: "txt")!, encoding: .utf8)) ?? "MIT License · Copyright (c) 2026 Huawei")
                            .font(.caption.monospaced())
                    }.padding(24)
                }.navigationTitle("关于").toolbar { Button("完成") { showCredits = false } }
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { photos.refresh() } }
    }
}
