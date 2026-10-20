import SwiftUI
import Photos

@MainActor
final class PhotoStore: ObservableObject {
    @Published var authorization = PHPhotoLibrary.authorizationStatus(for: .addOnly)
    @Published var busy = false
    @Published var message: String?
    var allowed: Bool { authorization == .authorized }
    func refresh() { authorization = PHPhotoLibrary.authorizationStatus(for: .addOnly) }
    func authorize() async {
        authorization = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
    }
    func save(_ card: Card) async -> Bool {
        guard !busy else { return false }
        refresh()
        guard allowed else {
            message = "尚未获得添加照片权限。请先在准备页面授权，或到系统设置中允许添加照片。"
            return false
        }
        guard let url = Bundle.main.url(forResource: card.asset, withExtension: "png"),
              let data = try? Data(contentsOf: url) else {
            message = "无法读取牌面图片，请重新安装 App。"
            return false
        }
        busy = true
        defer { busy = false }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: data, options: nil)
            }
            return true
        } catch {
            message = "保存失败：\(error.localizedDescription)。可以在照片详情中重试。"
            return false
        }
    }
}

// Load copied PNG resources explicitly; no asset catalog lookup is required.
extension Card {
    var image: UIImage {
        guard let path = Bundle.main.path(forResource: asset, ofType: "png"),
              let image = UIImage(contentsOfFile: path) else { return UIImage() }
        return image
    }
}
