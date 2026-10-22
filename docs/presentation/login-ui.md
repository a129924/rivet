# Rivet 登入 UI

本元件屬 non-BC `RivetPresentation`。Parent 提供 `RivetLoginPhase`、footer 與 `RivetLoginIntent` callback；View 不建立 authentication、network、Keychain 或 BC dependency。這次提供 UI 與假流程，沒有正式 GitHub 登入整合。

## 執行與操作

在 feature checkout 執行 `swift run RivetLoginDemo`。主視窗初始 content 780×500 pt，40／60 雙欄，可增大；操作區可垂直捲動。保持系統 titlebar、traffic lights、拖曳與原生輸入控制。

獨立 Demo Controls 提供 System／Light／Dark、七態、failure origin、模擬返回、完成結果與 Reset。使用範例輸入即可；沒有 timer、外部連結或 credential storage。Connected 停留展示，不打開 PR；Cancel 回 Welcome；PAT failure 保留可重填表單。

PAT 僅在 View 本地記憶體編輯，外圍 whitespace trim、不驗 prefix。Show／Hide 保留文字並重設編輯 focus；送出、離開表單、Reset 清除並隱藏。Mock model 不保存輸入。沒有覆寫系統全域鍵盤、TCC、VoiceOver 或使用者設定。

## 素材來源

接收日期：2026-10-22；使用者提供 `rivet_login_ui` 七份原件，已原樣歸檔在 `prototypes/rivet-login-ui/`。PNG 為外觀依據，Spec 補行為；原 scaffold 不參與編譯。素材內真登入／Keychain／PR 導覽敘述沒有當作本次已交付能力。

分支 mark geometry 來自 HTML 的三 circles／vertical stem／branch curve；dots、gradient、diff 使用原生 SwiftUI。`GitHubMark.pdf` 將該 HTML 內嵌 `githubIcon` path 轉為 24×24 pt 單色 PDF（SVG elliptical arcs 分段為 cubic Bezier、翻轉 Y 軸），以 `Bundle.module` 載入並標 template；不誤稱額外查證過官方品牌來源。未封裝系統字體。

| 原件 | SHA-256 | 原件 mtime（Asia/Taipei） |
| --- | --- | --- |
| `Rivet-Login-Dark.png` | `44823e32891e379b738e3a8d587dd8ccc6c153a6f89e3e406d8d75ace4e0e400` | 2026-10-21T12:06:54+08:00 |
| `Rivet-Login-Light.png` | `c02d1e3c857fd76af64936166886f0ed4431ee363f8be873ed8623d9b6f3f42a` | 2026-10-21T12:07:30+08:00 |
| `Rivet-Login-OAuth-Dark.png` | `aa84b79540f02199fdf99d075cd5df6219e0465a0cfb67059535180611f277df` | 2026-10-21T12:06:55+08:00 |
| `Rivet-Login-PAT-Dark.png` | `9a0e0b2e22ea2cc668f5aeffb62ff5d8948afd83631fc8985106ddf05bf15abc` | 2026-10-21T12:06:54+08:00 |
| `Rivet-Login-Prototype.html` | `bfef67912c39d39d07fffcebb5cd2924f9be8a9960b6a0be33d33fee01cacf9e` | 2026-10-21T12:06:50+08:00 |
| `Rivet-Login-Spec.md` | `e91487dfb126af40a838013d6bad2d53cbd571ccd6e30fbedb20bcd9480f336f` | 2026-10-21T12:05:55+08:00 |
| `RivetLoginView.swift` | `7906af649cca21e66f47b1bff1e662665365df7fbdd2adff95c009d53c11a2ce` | 2026-10-21T12:06:50+08:00 |

## 驗證與限制

Focused 9 tests、自我 debug／release build 與 production/tests scoped strict lint／format 通過。正式PR-02後最小同步target graph expected sets，root284tests全通過；rootlint仍有37既有experiment＋2原樣scaffold findings，production/tests scoped0。原生 UI 曾啟動並實看首次 Welcome，後續 wrapper 重選回 `cgWindowNotFound`；最新 safe-area／PDF 修正及四份對照圖、鍵盤、VoiceOver、高對比仍待獨立驗證，不冒稱通過。

[執行證據與待辦](../../plan/rivet-login-ui/evidence/verification.md)／[七態 lifecycle](diagrams/rivet-login-ui/login-lifecycle.html)／[圖面 build receipt](diagrams/rivet-login-ui/BUILD.md)。Lifecycle第1輪修正後deterministic showcase、四尺寸containment及四圖明暗實看均自驗通過；仍待獨立驗證與native evidence。
