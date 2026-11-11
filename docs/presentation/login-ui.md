# Rivet 登入 UI

本元件屬 non-BC `RivetPresentation`。Parent 提供 `RivetLoginPhase`、footer、可選的 `bodyPointSize` 與 `RivetLoginIntent` callback；View 不建立 authentication、network、Keychain 或 BC dependency。這次提供 UI 與假流程，沒有正式 GitHub 登入整合。

## 執行與操作

在feature checkout以 `swift build --product RivetLoginDemo` 建置，再以既有驗收 `.app` wrapper啟動；wrapper使用同一debug執行檔與 `Rivet_RivetPresentation.bundle`。主視窗初始 content 780×500 pt，40／60 雙欄，可增大；操作區可垂直捲動。保持系統 titlebar、traffic lights、拖曳與原生輸入控制。

獨立Demo Controls提供System／Light／Dark、Demo text size 13／17／21 pt、七態、failure origin、模擬返回、完成結果與Reset。使用範例輸入即可；沒有 timer、外部連結或 credential storage。Connected 停留展示，不打開 PR；Cancel 回 Welcome；PAT failure 保留可重填表單。

PAT 僅在 View 本地記憶體編輯，外圍 whitespace trim、不驗 prefix。Show／Hide 保留文字並重設編輯 focus；送出、離開表單、Reset 清除並隱藏。Mock model 不保存輸入。沒有覆寫系統全域鍵盤、TCC、VoiceOver 或使用者設定。

## 文字大小與狀態宣告

`RivetLoginView(phase:footer:bodyPointSize:onIntent:)`的 `bodyPointSize: CGFloat = 13` 置於最後的callback前；省略字級的既有label呼叫與trailing closure仍可用。Finite輸入限制在13...21 pt，NaN或正負infinity使用13。右側heading、eyebrow、欄位、按鈕、說明、error與footer使用有效字級／13的同一比例；左側AX隱藏的品牌／diff裝飾維持固定設計。21 pt Preview使用同一入口，不用Dynamic Type或scaleEffect代替實際font。

Demo的字級三選一直接傳入上述入口；更換字級不重建form identity、不清PAT或重設Show／Hide，Reset demonstration保留字級。這提供可重現的大字排版驗法，**macOS系統文字大小偏好整合尚未交付**。macOS的Dynamic Type環境值不會改變文字大小；原系統13／15點操作及舊ScaledMetric／Dynamic Type Preview不算本Demo的大字證據。使用者可在最小780×500 pt content逐一切換13／17／21 pt，確認表單、footer與操作能垂直捲動到達。

狀態entry使用各自accessibility identity與可取消task，分序處理鍵盤focus、accessibility focus與局部announcement；每次await後確認task未取消且仍屬目前phase。Welcome為主按鈕、PAT為輸入、waiting為Cancel、browser failure為Retry，verifying／connected為對應heading；快速離開不應由舊工作拉回。這是針對HC-02時序候選的修正，不宣稱已證唯一root cause；VoiceOver真朗讀仍須新版Human補驗。

等待授權時，既有 Cancel sign in 連結的 accessibility label 為 `Waiting for simulated authorization. Cancel sign in.`，讓 Welcome 與 browser failure Retry 兩個入口的 Cancel 焦點同時帶出等待狀態與取消動作。Waiting 的狀態由此焦點 label 提供，獨立 announcementRequested 僅用於驗證中、失敗與完成階段。兩個等待入口的朗讀、雙讀情況及 Cancel／Escape 操作交逐項 Human 補驗。

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

HC-02（2026-11-04交接）記錄原binary的七類Human通過；仍有PAT verifying與Welcome／Retry進waiting的自動宣告、有效大字排版三缺口。失敗宣告首次state未定／重跑Human通過、背景送鍵限制及spinner旋轉觀察保留，不能改寫為新缺陷或新版pass。

PC-03／PR-03後已實作上述局部字級與phase協調，完成新的字級／model行為測試；新版focus、三個真入口的聲音、13／17／21 pt原生排版及必要回歸交獨立Tester／Human，尚未全面通過。自動檢查與binary來源見[驗證紀錄](../../plan/rivet-login-ui/evidence/verification.md)，舊focused10／root284等成功不代表新版結果。Root strict lint保留未改experiments與原樣素材的非零findings，沒有宣稱全局通過。

[七態lifecycle](diagrams/rivet-login-ui/login-lifecycle.html)與[圖面build receipt](diagrams/rivet-login-ui/BUILD.md)保持凍結；本輪七態／intent graph不變，不重產圖。舊四張native PNG及本地PR Lens仍保留其source provenance，不能代替新版驗收。最後停HC-03逐項補驗與HC-01 Human採用，不自動merge或release。
