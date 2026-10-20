# Magic Card · iOS 初版

原生 SwiftUI 工程，iOS 17 及以上，仅 iPhone 竖屏，无第三方依赖。

## 打开与运行

1. 用 Xcode 打开 `MagicCard.xcodeproj`。
2. 顶部 Scheme 选择 MagicCard，运行设备选一个已安装的 iPhone 模拟器。
3. 按 Command + R 运行。

### 安装到自己的 iPhone

1. 数据线连接 iPhone，解锁并信任 Mac；按 Xcode 提示在手机开启开发者模式。
2. 点击左侧蓝色工程 → TARGETS / MagicCard → Signing & Capabilities。
3. 勾选 Automatically manage signing，Team 选择你的 Personal Team。
4. Bundle Identifier 改成自己唯一的值，例如 `com.你的英文标识.magiccard`，使用英文字母和数字。
5. 顶部运行设备选择你的 iPhone，按 Command + R。

仓库版工程没有写入个人开发团队或签名信息；首次真机运行请选择自己的 Team 和唯一 Bundle Identifier。免费账号的安装有效期受 Apple Personal Team 限制。

## 功能与操作

- 内置参考工程的 54 张牌面 PNG，离线运行。
- 首页提供教程、练习模式、震动开关、0 / 0.2 / 0.5 / 2 秒揭晓延迟（默认 0.2 秒）。
- 练习模式显示 3×5 网格。网格只覆盖照片区域，不包含顶部和底部工具栏。
- 起始按下位置选择点数，按以下顺序从左到右、从上到下：

| | | |
|---|---|---|
|A|2|3|
|4|5|6|
|7|8|9|
|10|J|Q|
|K|小王|大王|

- 方向：右上 ↗ 黑桃；右下 ↘ 红桃；左下 ↙ 梅花；左上 ↖ 方块。
- 普通牌需要滑动至少 8 点；大小王可直接点击。建议向斜方向滑动，避开轴线边界。
- 松手后等待配置的时间揭晓，等待期间不再接收新选牌。
- 表演模式隐藏网格，在照片风格的界面中揭晓。选牌前的照片区域为纯黑，装饰缩略图是 App 自带内容，不读取个人相册。
- 双击牌面放大 / 还原；左上角或右下角重新选牌；右上角菜单结束表演。
- 分享按钮可打开系统分享面板。收藏心形仅用于本轮视觉呈现，不修改系统照片的收藏状态。

## 保存照片

1. 表演前在首页点“允许添加照片”，接受系统的添加照片授权。
2. 打开“揭晓后自动保存”。每次表演揭晓后保存一次。
3. 也可以在照片详情点击底部保存按钮。保存成功变为勾号，本轮禁止重复保存。
4. 未授权或保存失败会显示提示，可以授权后重试。初次权限请求只在首页主动触发，不在表演中突然弹出。
5. 练习模式始终不保存。

只申请 `NSPhotoLibraryAddUsageDescription` 对应的 addOnly 权限，不申请读取照片、麦克风或网络权限。切到后台会取消尚未完成的延迟揭晓。保存图片是 PhotoKit 本地写入，无需网络下载。

## 范围与限制

本版实现手势选牌、练习、相册风格揭晓、相册保存和分享。未移植参考工程的离线语音识别和随机演示模式。界面属于 Magic Card，并非系统“照片”App；不接管系统照片界面，不读取用户照片。

这是开发初版，尚未作为 App Store 提交版本：需补正式应用图标、商店素材、公开隐私政策地址，并核实第三方牌面素材独立授权。真机震动、权限和相册写入应在目标 iPhone 上最终验收。

## 素材和许可

参考工程：https://github.com/HuaweiREN/Wombat_Magic_Poker

参考版本：`c7199765dfb4c2bbd20a152baa59d6372307a649`

手势规则参考 `lib/grid_swipe_selector.dart`；PNG 复制自 `assets/images`。保留原工程 MIT 许可证，位于 `MagicCard/Resources/Wombat-LICENSE.txt`，App 内“关于与素材来源”也提供该声明。

原作者 README 将牌面来源标注为 https://gitcode.com/open-source-toolkit/77d38/ 。本项目沿用这些素材作为用户指定的初版开发资源，未独立确认该第三方素材的商业授权范围。

## 可重复检查

在工程目录执行：

```sh
swiftc MagicCard/Card.swift Checks/main.swift -o /tmp/magiccard-check
/tmp/magiccard-check MagicCard/Resources
```

该检查覆盖 52 种点数 / 花色组合、普通牌误触、大小王、无效区域大小和全部 54 张资源路径。
