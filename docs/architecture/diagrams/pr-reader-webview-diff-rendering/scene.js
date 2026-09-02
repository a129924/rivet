const W = 1480, H = 1708;

// 此圖只呈現已鎖定的僅宣告邊界。虛線表示 Rivet 擁有的 TypeScript
// 抽象；實線表示 Swift 或 WebView 介面。主渲染路徑不經過介接器：介接器
// 只宣告跨 Swift／WebView 邊界的契約。
const PLANES = {
  swift: { c: "#94A3B8", label: "Swift 外部邊界" },
  presentation: { c: "#7DD3FC", label: "呈現層" },
  core: { c: "#A78BFA", label: "管線核心" },
  pipeline: { c: "#F6821F", label: "渲染階段" },
  boundary: { c: "#22D3EE", label: "邊界契約" },
};

const BANDS = [
  { id: "band-swift", plane: "swift", x: 160, y: 200, w: 1260, h: 150, alpha: 0.5,
    hdr: { x: 184, y: 230, t: "SWIFT — 快照與已檢視狀態權威" }, tagr: { x: 1396, y: 230, t: "外部世界", alpha: 0.6 } },
  { id: "band-presentation", plane: "presentation", x: 160, y: 430, w: 1260, h: 160, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 460, t: "呈現層 — WebView 入口" }, tagr: { x: 1396, y: 460, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 } },
  { id: "band-core", plane: "core", x: 160, y: 670, w: 1260, h: 160, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 700, t: "核心 — 渲染協調" }, tagr: { x: 1396, y: 700, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 } },
  { id: "band-pipeline", plane: "pipeline", x: 160, y: 910, w: 1260, h: 190, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 940, t: "渲染管線 — 四個階段 Port" }, tagr: { x: 1396, y: 940, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 } },
  { id: "band-boundary", plane: "boundary", x: 160, y: 1180, w: 1260, h: 370, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 1210, t: "Swift／WebView 邊界契約" }, tagr: { x: 1396, y: 1210, t: "RIVET 擁有 — 不在主路徑", alpha: 0.6 } },
];

const BOXES = [
  { id: "swift-snapshot", plane: "swift", band: "band-swift", x: 200, y: 260, w: 520, h: 70, r: 10,
    name: "Swift 快照發送端", about: "Swift 提供完整、有序且帶 PR 與快照身分的 DiffSnapshot。",
    texts: [["bl", 224, 288, "Swift 快照發送端"], ["bs", 224, 310, "完整 DiffSnapshot · PR · 快照 · 有序檔案"]] },
  { id: "swift-viewed", plane: "swift", band: "band-swift", x: 800, y: 260, w: 580, h: 70, r: 10,
    name: "Swift 已檢視狀態權威", about: "Swift 持久化已檢視狀態，並可安全忽略過期通知。",
    texts: [["bl", 824, 288, "Swift 已檢視狀態權威"], ["bs", 824, 310, "唯一持久化權威 · 可忽略過期通知"]] },
  { id: "facade", plane: "presentation", band: "band-presentation", x: 200, y: 490, w: 600, h: 78, r: 10, dash: true,
    name: "DiffFacade", about: "呈現層的公開渲染入口，將快照交給 UseCase 並委派已檢視狀態通知。",
    texts: [["bl", 224, 518, "DiffFacade"], ["bs", 224, 540, "present(snapshot) · requestViewedStateChange(change)"], ["bn", 224, 558, "不依賴 Output Port"]] },
  { id: "webview", plane: "presentation", band: "band-presentation", x: 870, y: 490, w: 510, h: 78, r: 10,
    name: "WebView 呈現層", about: "使用 DiffFacade 公開契約的 WebView 呈現介面。",
    texts: [["bl", 894, 518, "WebView 呈現層"], ["bs", 894, 540, "使用 Facade 的公開入口與結果"]] },
  { id: "usecase", plane: "core", band: "band-core", x: 200, y: 730, w: 1180, h: 78, r: 10, dash: true,
    name: "DiffRenderUseCase", about: "唯一協調 Validator、Parser、Renderer 與輸出 Ports，並是輸出 Port 唯一呼叫端。",
    texts: [["bl", 224, 758, "DiffRenderUseCase"], ["bs", 224, 780, "execute(snapshot) · 唯一協調 Validator → Parser → Renderer → Output"], ["bn", 224, 798, "輸出 Port 的唯一呼叫端"]] },
  { id: "validator-port", plane: "pipeline", band: "band-pipeline", x: 190, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "驗證 Port", about: "宣告 DiffSnapshot 的驗證階段與 invalid-input 失敗。",
    texts: [["bl", 214, 1008, "驗證 Port"], ["bs", 214, 1030, "DiffSnapshot → 已驗證輸入"], ["bn", 214, 1048, "invalid-input"]] },
  { id: "parser-port", plane: "pipeline", band: "band-pipeline", x: 490, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "剖析 Port", about: "宣告從已驗證輸入到已剖析輸入的階段與 parse-error 失敗。",
    texts: [["bl", 514, 1008, "剖析 Port"], ["bs", 514, 1030, "已驗證輸入 → 已剖析輸入"], ["bn", 514, 1048, "parse-error"]] },
  { id: "renderer-port", plane: "pipeline", band: "band-pipeline", x: 790, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "渲染 Port", about: "宣告從已剖析輸入到不透明 RenderPlan 的階段與 render-error 失敗。",
    texts: [["bl", 814, 1008, "渲染 Port"], ["bs", 814, 1030, "已剖析輸入 → RenderPlan"], ["bn", 814, 1048, "render-error"]] },
  { id: "output-port", plane: "pipeline", band: "band-pipeline", x: 1090, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "輸出 Port", about: "宣告最終輸出階段與其獨立的 output-error 失敗。",
    texts: [["bl", 1114, 1008, "輸出 Port"], ["bs", 1114, 1030, "RenderPlan → 輸出"], ["bn", 1114, 1048, "output-error"]] },
  { id: "snapshot-adapter", plane: "boundary", band: "band-boundary", x: 190, y: 1250, w: 360, h: 84, r: 10, dash: true,
    name: "DiffSnapshotAdapter", about: "只宣告 Swift 快照輸入邊界；它不轉送或執行渲染主路徑。",
    texts: [["bl", 214, 1278, "DiffSnapshotAdapter"], ["bs", 214, 1300, "receiveSnapshot(snapshot): void"], ["bn", 214, 1318, "只描述 Swift 輸入邊界"]] },
  { id: "snapshot-contract", plane: "boundary", band: "band-boundary", x: 590, y: 1250, w: 360, h: 84, r: 10, dash: true,
    name: "DiffSnapshot", about: "完整渲染輸入封套，帶 PR、快照身分與完整有序檔案集合。",
    texts: [["bl", 614, 1278, "DiffSnapshot"], ["bs", 614, 1300, "pullRequestId · snapshotId · files"], ["bn", 614, 1318, "fileId 只在快照內唯一"]] },
  { id: "outcome-contract", plane: "boundary", band: "band-boundary", x: 990, y: 1250, w: 370, h: 84, r: 10, dash: true,
    name: "DiffRenderOutcome", about: "公開結果區分驗證、剖析、渲染與輸出四個階段的失敗。",
    texts: [["bl", 1014, 1278, "DiffRenderOutcome"], ["bs", 1014, 1300, "success 或四類階段失敗"], ["bn", 1014, 1318, "output-error 是獨立失敗"]] },
  { id: "viewed-change", plane: "boundary", band: "band-boundary", x: 190, y: 1410, w: 360, h: 84, r: 10, dash: true,
    name: "ViewedStateChange", about: "以 PR、快照、檔案與已檢視值識別單向通知所屬的資料。",
    texts: [["bl", 214, 1438, "ViewedStateChange"], ["bs", 214, 1460, "PR 身分 · 快照身分 · fileId · viewed"], ["bn", 214, 1478, "Swift 可忽略過期事件"]] },
  { id: "viewed-port", plane: "boundary", band: "band-boundary", x: 590, y: 1410, w: 360, h: 84, r: 10, dash: true,
    name: "ViewedStateChangePort", about: "宣告無確認回覆的盡力而為 void 已檢視狀態通知。",
    texts: [["bl", 614, 1438, "ViewedStateChangePort"], ["bs", 614, 1460, "notify(change): void"], ["bn", 614, 1478, "沒有確認回覆、重試或可靠傳輸"]] },
  { id: "viewed-adapter", plane: "boundary", band: "band-boundary", x: 990, y: 1410, w: 370, h: 84, r: 10, dash: true,
    name: "ViewedStateChangeAdapter", about: "直接符合 ViewedStateChangePort 的 Swift 通知邊界宣告。",
    texts: [["bl", 1014, 1438, "ViewedStateChangeAdapter"], ["bs", 1014, 1460, "extends ViewedStateChangePort"], ["bn", 1014, 1478, "只描述回傳 Swift 的邊界"]] },
];

const EDGES = [
  { from: "swift-snapshot", to: "facade", pts: [[460,334], [460,484]], label: { s: "al", x: 474, y: 412, t: "DiffSnapshot → present" } },
  { from: "facade", to: "usecase", pts: [[500,574], [500,724]], label: { s: "al", x: 514, y: 654, t: "execute(snapshot)" } },
  { from: "usecase", to: "validator-port", pts: [[325,814], [325,974]], label: { s: "al", x: 339, y: 900, t: "Validator" } },
  { from: "validator-port", to: "parser-port", pts: [[464,1021], [484,1021]], label: { s: "al", x: 474, y: 1009, t: "成功", anchor: "center" } },
  { from: "parser-port", to: "renderer-port", pts: [[764,1021], [784,1021]], label: { s: "al", x: 774, y: 1009, t: "成功", anchor: "center" } },
  { from: "renderer-port", to: "output-port", pts: [[1064,1021], [1084,1021]], label: { s: "al", x: 1074, y: 1009, t: "成功", anchor: "center" } },
  { from: "facade", to: "webview", pts: [[804,529], [864,529]], label: { s: "al", x: 834, y: 517, t: "DiffRenderOutcome", anchor: "center" } },
  { from: "facade", to: "viewed-port", pts: [[804,550], [930,550], [930,1404], [770,1404]], label: { s: "al", x: 944, y: 980, t: "已檢視狀態：盡力而為 void", rot: -90, anchor: "center" } },
  { from: "viewed-port", to: "viewed-adapter", pts: [[954,1452], [984,1452]], label: { s: "al", x: 969, y: 1440, t: "notify", anchor: "center" } },
  { from: "viewed-adapter", to: "swift-viewed", pts: [[1364,1452], [1440,1452], [1440,295], [1386,295]], label: { s: "al", x: 1454, y: 876, t: "單向通知", rot: -90, anchor: "center" } },
];

const TEXTS = [
  { s: "title", x: 160, y: 86, t: "PR Reader — WebView 差異管線" },
  { s: "sub", x: 160, y: 118, t: "Swift 快照 → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output" },
  { s: "tag", x: 160, y: 146, runs: [{ t: "Swift 快照", fill: C.slate }, { t: " → ", fill: "#4A5462" }, { t: "Facade", fill: C.sky }, { t: " → ", fill: "#4A5462" }, { t: "UseCase", fill: C.violet }, { t: " → ", fill: "#4A5462" }, { t: "四個階段", fill: C.orange }] },
  { s: "legend", x: 1082, y: 86, t: "虛線 — Rivet 擁有的抽象" },
  { s: "legend", x: 1082, y: 110, t: "實線 — Swift 或 WebView 介面" },
  { s: "legend", x: 1143, y: 134, t: "顏色 — 所屬責任平面" },
  { s: "bn", x: 160, y: 1610, t: "主路徑：Swift 快照 → DiffFacade.present → DiffRenderUseCase.execute → Validator → Parser → Renderer → Output" },
  { s: "bn", x: 160, y: 1630, t: "例外：已檢視狀態只發送盡力而為的 void 單向通知；沒有確認回覆、重試或可靠傳輸。" },
  { s: "bn", x: 160, y: 1650, t: "前提：Swift 是快照與已檢視狀態的權威；WebView 不進行樂觀更新。" },
  { s: "bn", x: 160, y: 1670, t: "邊界：介接器只宣告 Swift／WebView 契約，不加入或反向轉送渲染主路徑。" },
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: "#8B93A1", alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill },
];
const CHIPS = ["swift", "presentation", "core", "pipeline", "boundary"]
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
