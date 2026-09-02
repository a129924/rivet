# 圖表交付交易

本資料夾只能透過 `bash build-diagram.sh` 重建兩個 generated artifact：canvas 的 `index.html` 與 Archify dataflow 的 `diff-render-flow.html`。它會先在兩個 committed target 所在的同一資料夾建立 temporary outputs，依序完成 canvas validate／build／accessibility enhance／verify，以及 Archify validate／deliver；接著第二次完整產生兩份候選並比對 hash，確認重跑輸出一致後才進入交付。

POSIX 沒有可把兩個檔案視為一個原子的 rename 操作。因此交付不宣稱「兩檔同時 atomic」：它會在第一次 publish 前以 hash 驗證的 backups 與 journal 保留兩個舊輸出，再以同 filesystem 的單檔 atomic rename 依序替換 canvas 與 dataflow，最後驗證新 target hashes。任何交付階段失敗，以及第一個 rename 後收到 `SIGINT` 或 `SIGTERM`，都會以 backups 對兩個 targets 執行 restore；只有兩個 target 均回到原始 hash，temporary、backup 與 journal 才會清除。

若 restore 本身失敗，script 會以非零結束並保留同資料夾的 `.pr-reader-diff-*` backups 與候選檔，輸出其確切位置供人工復原；它不會假稱輸出已一致或清掉唯一復原材料。這是無 multi-file rollback primitive 下的 failure policy，不是 cross-file atomicity 主張。

可用 `bash verify-build-transaction.sh` 驗證兩個受控失敗點，以及第一個 rename 後的受控 `SIGINT`／`SIGTERM`。每一項都必須實際觸發 rollback，並確認兩個 committed outputs 的 hashes 均未變更且沒有 temporary、backup 或 journal residue。build entry 也會執行 dataflow contract verifier：只有 `success` 可進下一個 stage，每個既定 failure kind 都只終止於對應的 Facade outcome。
