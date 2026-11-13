# E016：本地 OAuth 登出精確刪除與新程序讀回

## 驗證什麼
設計日期 2026-11-13。主要問題：正式 DPK adapter 清除 exact credential 後，新程序是否讀不到且 configuration／相鄰 sentinel 保持？假設為有效簽章與同 namespace 唯一 writer 下成立。建立前確認 E016 未占用。

## 為什麼
來源基線 2973150；正式本次 provider signOut／DPK clear 原始碼及受控測試支持 ordering，Apple SecItemDelete 文件支持 selector，但不能證明指定 signer 的實際提示與跨程序 absence。決策位置為 github-oauth-local-sign-out T09；既有保存實驗不證明清除。

## 成功與失敗判準
執行前固定：成功為 credential absent 且 configuration／sentinel 完整保持；失敗為 credential 存在、舊寫入恢復或誤改其他 item；簽章／程序終止／觀察不足則無法判定。最多一次隔離 seed→logout→fresh-read，不自動重試，不操作真 OAuth 或既有項目。

## 環境與前置條件
預定同機同 GUI 使用者、有效簽章／entitlement／explicit private group。資料為完整假 credential，DPK 為真依賴；唯一 writer 是獨立假設。實際簽章前提本輪未檢查，工具版本及 signer 尚未凍結。

## 重現步驟
設計：獨立隔離 namespace 保存 fake credential、configuration 與相鄰 sentinel；透過正式 provider.signOut；程序結束後 fresh process load/inspect 驗證 absence 與其他 item 相符。必要 harness、可執行命令及安全 receipt schema 尚未建立，因此此 README 不是可執行驗證入口。本輪只建立設計紀錄，未執行 seed／delete／fresh-read。

## 是否成功
實驗狀態：未執行。本輪驗證任務完成：否。缺少已凍結 harness、簽章前提與跨程序證據，不能宣稱 T09 通過。

## 結果與證據
無系統實驗觀察。正式 tests 的 fake Security 與 gate 結果只支持受控條件，不當作本實驗成功。沒有真憑證或秘密資料。

## 結論與限制
T09 保持 pending；指定環境重啟不還原仍未實證。不影響受限 src 能力可供 code review，但不能把本紀錄完成當驗收完成。下一步須凍結獨立 signed harness／安全命令，確認前提後由 Tester 執行一次序列；不自動核准採用或擴張範圍。
