# v2 視覺與語意檢視（R07 作者）

作者已用view_image真正開啟12張native PNG：每張authorization／restore-refresh／lifecycle各1440×900及2048×1320的light／dark；同批native visual-check亦量測1600×1000與1920×1080。全12PNG親看了title、participant／state、箭頭方向、labels、legend／dock與兩張必要結論cards，最小無遮字裁切，最大縱向構圖平衡、沒有大片空白底帶，light／dark層次可辨。這是作者QA，非獨立R08／R09或Human接受。

新Canvas先validate5bands／19boxes／17edges 0/0，再nativebuild；親看真Chrome1440×1100截圖，含最後compile-time／runtime註記後重build的最終圖。驗證App與正式契約分帶、publicport注入與runtime呼叫分清，relay→session方向正確；初次bundle由Coordinator→stores保存。routes繞開不相關opaque boxes，Canvas仍可pan／zoom，不手改viewer。

lifecycle首版誤改工具保留main／terminal laneIDs，診斷後恢復；再依short-interior-segment將prepare→ready改straight，及四個具體label碰撞逐項調整labelAt，每次真正validate。最終9/9、0error／0warning；沒有刪有意義labels過關，也沒改原版本native圖。兩sequence首candidate即9/9通過。deliver後visual-check全exit0，不以基本4checks冒稱showcase。

作者內容繁中；固定ViewerUI與HTMLlang Englishfallback，classic／still。原生visual-check收據的 `visualReview: pending` 完全保留，截圖不是自動批准。規格、HTML、native收據及全部PNG hashes列 [manifest](../../../../../plan/github-persistent-connection/evidence/verification-host-manifest.md)；原生 [authorization](authorization-sequence.visual-check.html)、[restore／rotation](restore-refresh-reauth-sequence.visual-check.html)、[lifecycle](connection-lifecycle.visual-check.html) contact sheets可重查。

[BUILD](BUILD.md) · [工具與覆蓋界線](tool-evidence.md)。尚未發布artifact.cafe、尚未R10PRLens真map／push／更新DraftPR，最終Humanreview不代填。
