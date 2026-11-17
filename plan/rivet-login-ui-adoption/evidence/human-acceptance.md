# HC01：正式 Login UI／UX Human 接受

- 日期：2026-11-17；decision owner=Human；本文件由agent如實記錄，不以agent／Reviewer判定代替Human。
- Human明確回覆：

> 接受目前這版正式 Login UI／UX

- 交付來源：`3c9baf3d1cebfb58f3356ea8c9ab4d29a09fc26b`，branch `feat/rivet-login-ui-adoption`。預覽程式來源為`42e99fa`；之後只有T05補證文件提交，沒有改preview source。
- 受驗native preview：`.build/clean-preview-i02/RivetLoginPreview.app`，ID `local.rivet.login-ui-preview`；binary SHA-256=`4d4cf13f719e8e609101900074e659928c5acf3790ea8ac527b8a06b720a7eea`。
- 接受範圍：本topic的正式SwiftUI Login元件、組合／呈現與局部互動，以及使用`.standard`的乾淨原生預覽之正式文案與視覺／UI。Footer與failure message由host提供中性文字，不誤稱由`.standard`提供。

## 對驗收的影響

TC06原已取得T03 Human VoiceOver H01–H08；本次明示正式UI接受補足其最終Human部分。因此HC01／HC-FINAL及TC06在本topic受限範圍內完成，不能將原pending留作目前狀態，也不要求Human重做已確認案例。

[T02原生互動](native-ui.md)、[T03實際VoiceOver回報](voiceover-human.md)、[T05乾淨預覽差異](clean-preview-native.md)及其獨立review仍各自支持原受測版本與範圍；本次接受不新增測試結果、逐字語音或精確時序。T05七變體而非全矩陣／verifying-account重驗的限制保持。T01／T04當時incomplete、CUA拒絕與後續取得當下確認的歷史不改判。

## 保持的邊界

- 真正LoginRequest／PersonalAccessToken建構、外層Adapter、LoginAuthenticating接線、認證非同步流程、憑證儲存與session不在本topic；沒有因本次接受而實作或驗收。
- 沒有將接受外推成所有OS／輸入／視覺組合、所有VoiceOver佇列／race，或其他topic／圖面的新Human接受。
- 這是UI接受，不是merge、ready-for-review、tag、release或發布授權。PR #75維持Draft／未merge；原已授權的topic文件commit／push／Draft更新可完成。
- 本輪只記錄Human決策並同步文件，未改source、test、preview binary、系統設定或dev worktree，未重跑既有tests／native操作。沒有新增需Human再確認的gate。

`current_step: HC01 completed`；`status: COMPLETE`（本topic正式Login UI／UX Human接受）；`decision: accepted`（Human明示；非agent計算approval）。
