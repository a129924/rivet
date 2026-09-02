const W = 1480, H = 1538;

// 此圖只呈現已鎖定 declarations 的層級所有權、編譯期依賴與 Swift／WebView
// 邊界。虛線表示 Rivet 擁有的 TypeScript 抽象；實線表示 Swift 或 WebView
// 介面。既定 runtime render dataflow 由同資料夾的 Archify artifact 表達。
const PLANES = {
  swift: { c: "#94A3B8", label: "Swift 外部邊界" },
  presentation: { c: "#7DD3FC", label: "呈現層" },
  core: { c: "#A78BFA", label: "管線核心" },
  pipeline: { c: "#F6821F", label: "階段 Port" },
  boundary: { c: "#22D3EE", label: "邊界契約" },
};

const BANDS = [
  { id: "band-swift", plane: "swift", x: 160, y: 200, w: 1260, h: 150, alpha: 0.5,
    hdr: { x: 184, y: 230, t: "SWIFT — 快照與已檢視狀態權威" }, tagr: { x: 1396, y: 230, t: "外部世界", alpha: 0.6 } },
  { id: "band-presentation", plane: "presentation", x: 160, y: 430, w: 1260, h: 160, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 460, t: "呈現層 — WEBVIEW 公開入口" }, tagr: { x: 1396, y: 460, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 } },
  { id: "band-core", plane: "core", x: 160, y: 670, w: 1260, h: 160, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 700, t: "核心 — 協調責任" }, tagr: { x: 1396, y: 700, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 } },
  { id: "band-pipeline", plane: "pipeline", x: 160, y: 910, w: 1260, h: 190, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 940, t: "管線 — 四個 STAGE PORT" }, tagr: { x: 1396, y: 940, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 } },
  { id: "band-boundary", plane: "boundary", x: 160, y: 1180, w: 1260, h: 250, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 1210, t: "SWIFT／WEBVIEW 邊界契約" }, tagr: { x: 1396, y: 1210, t: "RIVET 擁有 — 不含具體 BRIDGE", alpha: 0.6 } },
];

const BOXES = [
  { id: "swift-snapshot", plane: "swift", band: "band-swift", x: 200, y: 260, w: 520, h: 70, r: 10,
    name: "Swift 快照發送端", about: "Swift 提供完整、有序且帶 PR 與快照身分的 DiffSnapshot。",
    texts: [["bl", 224, 288, "Swift 快照發送端"], ["bs", 224, 310, "完整 DiffSnapshot · PR · 快照 · 有序檔案"]] },
  { id: "swift-viewed", plane: "swift", band: "band-swift", x: 800, y: 260, w: 580, h: 70, r: 10,
    name: "Swift 已檢視狀態權威", about: "Swift 持久化已檢視狀態，並可安全忽略過期通知。",
    texts: [["bl", 824, 288, "Swift 已檢視狀態權威"], ["bs", 824, 310, "唯一持久化權威 · 可忽略過期通知"]] },
  { id: "facade", plane: "presentation", band: "band-presentation", x: 200, y: 490, w: 600, h: 78, r: 10, dash: true,
    name: "DiffFacade", about: "呈現層的公開契約，宣告 render 與已檢視狀態通知入口。",
    texts: [["bl", 224, 518, "DiffFacade"], ["bs", 224, 540, "present(snapshot) · requestViewedStateChange(change)"], ["bn", 224, 558, "不依賴 Output Port"]] },
  { id: "webview", plane: "presentation", band: "band-presentation", x: 870, y: 490, w: 510, h: 78, r: 10,
    name: "WebView 呈現層", about: "使用 DiffFacade 公開契約的 WebView 呈現介面。",
    texts: [["bl", 894, 518, "WebView 呈現層"], ["bs", 894, 540, "使用 Facade 的公開入口與結果"]] },
  { id: "usecase", plane: "core", band: "band-core", x: 200, y: 730, w: 1180, h: 78, r: 10, dash: true,
    name: "DiffRenderUseCase", about: "唯一依賴並協調四個 stage Port，且是 Output Port 唯一 caller。",
    texts: [["bl", 224, 758, "DiffRenderUseCase"], ["bs", 224, 780, "四個 stage Port 的唯一協調者 · Output Port 唯一 caller"], ["bn", 224, 798, "不定義具體 stage 實作或組裝"]] },
  { id: "validator-port", plane: "pipeline", band: "band-pipeline", x: 190, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "驗證 Port", about: "宣告 DiffSnapshot 驗證與 invalid-input failure 的 Port。",
    texts: [["bl", 214, 1008, "驗證 Port"], ["bs", 214, 1030, "DiffSnapshot 驗證"], ["bn", 214, 1048, "invalid-input"]] },
  { id: "parser-port", plane: "pipeline", band: "band-pipeline", x: 490, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "剖析 Port", about: "宣告已驗證輸入剖析與 parse-error failure 的 Port。",
    texts: [["bl", 514, 1008, "剖析 Port"], ["bs", 514, 1030, "已驗證輸入"], ["bn", 514, 1048, "parse-error"]] },
  { id: "renderer-port", plane: "pipeline", band: "band-pipeline", x: 790, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "渲染 Port", about: "宣告不透明 RenderPlan 與 render-error failure 的 Port。",
    texts: [["bl", 814, 1008, "渲染 Port"], ["bs", 814, 1030, "不透明 RenderPlan"], ["bn", 814, 1048, "render-error"]] },
  { id: "output-port", plane: "pipeline", band: "band-pipeline", x: 1090, y: 980, w: 270, h: 82, r: 10, dash: true,
    name: "輸出 Port", about: "宣告獨立 output-error failure 的 Port；只有 UseCase 呼叫它。",
    texts: [["bl", 1114, 1008, "輸出 Port"], ["bs", 1114, 1030, "Output Port"], ["bn", 1114, 1048, "output-error"]] },
  { id: "snapshot-adapter", plane: "boundary", band: "band-boundary", x: 190, y: 1250, w: 360, h: 84, r: 10, dash: true,
    name: "DiffSnapshotAdapter", about: "只宣告 Swift 快照輸入邊界，不包含具體 bridge。",
    texts: [["bl", 214, 1278, "DiffSnapshotAdapter"], ["bs", 214, 1300, "receiveSnapshot(snapshot): void"], ["bn", 214, 1318, "Swift 輸入邊界"]] },
  { id: "snapshot-contract", plane: "boundary", band: "band-boundary", x: 590, y: 1250, w: 360, h: 84, r: 10, dash: true,
    name: "DiffSnapshot", about: "完整 render input envelope，帶 PR、snapshot identity 與有序檔案集合。",
    texts: [["bl", 614, 1278, "DiffSnapshot"], ["bs", 614, 1300, "pullRequestId · snapshotId · files"], ["bn", 614, 1318, "fileId 只在 snapshot 內唯一"]] },
  { id: "viewed-port", plane: "boundary", band: "band-boundary", x: 990, y: 1250, w: 370, h: 84, r: 10, dash: true,
    name: "ViewedStateChangePort", about: "宣告無確認回覆的盡力而為 void 已檢視狀態通知。",
    texts: [["bl", 1014, 1278, "ViewedStateChangePort"], ["bs", 1014, 1300, "notify(change): void"], ["bn", 1014, 1318, "沒有 retry 或可靠傳輸"]] },
  { id: "viewed-change", plane: "boundary", band: "band-boundary", x: 390, y: 1360, w: 360, h: 50, r: 10, dash: true,
    name: "ViewedStateChange", about: "以 PR、snapshot、file 與 viewed 值識別通知所屬資料。",
    texts: [["bl", 414, 1388, "ViewedStateChange"], ["bs", 414, 1406, "PR · snapshot · fileId · viewed"]] },
  { id: "viewed-adapter", plane: "boundary", band: "band-boundary", x: 820, y: 1360, w: 440, h: 50, r: 10, dash: true,
    name: "ViewedStateChangeAdapter", about: "直接符合 ViewedStateChangePort 的 Swift 通知邊界宣告。",
    texts: [["bl", 844, 1388, "ViewedStateChangeAdapter"], ["bs", 844, 1406, "extends ViewedStateChangePort"]] },
];

const EDGES = [
  { from: "webview", to: "facade", pts: [[864,529], [804,529]], label: { s: "al", x: 834, y: 517, t: "使用公開契約", anchor: "center" } },
  { from: "facade", to: "usecase", pts: [[500,574], [500,724]], label: { s: "al", x: 514, y: 654, t: "編譯期依賴" } },
  { from: "usecase", to: "validator-port", pts: [[325,814], [325,974]], label: { s: "al", x: 339, y: 900, t: "依賴 Port" } },
  { from: "usecase", to: "parser-port", pts: [[625,814], [625,974]], label: { s: "al", x: 639, y: 900, t: "依賴 Port" } },
  { from: "usecase", to: "renderer-port", pts: [[925,814], [925,974]], label: { s: "al", x: 939, y: 900, t: "依賴 Port" } },
  { from: "usecase", to: "output-port", pts: [[1225,814], [1225,974]], label: { s: "al", x: 1239, y: 900, t: "唯一 caller" } },
  { from: "snapshot-adapter", to: "snapshot-contract", pts: [[554,1292], [584,1292]], label: { s: "al", x: 569, y: 1280, t: "輸入型別", anchor: "center" } },
  { from: "viewed-adapter", to: "viewed-port", pts: [[1040,1354], [1175,1354], [1175,1340]], label: { s: "al", x: 1189, y: 1350, t: "符合 Port" } },
];

const TEXTS = [
  { s: "title", x: 160, y: 86, t: "PR Reader — WebView 差異宣告邊界" },
  { s: "sub", x: 160, y: 118, t: "層級所有權、編譯期依賴與 Swift／WebView 邊界" },
  { s: "tag", x: 160, y: 146, runs: [{ t: "呈現層", fill: C.sky }, { t: " · ", fill: "#4A5462" }, { t: "核心", fill: C.violet }, { t: " · ", fill: "#4A5462" }, { t: "Stage Ports", fill: C.orange }, { t: " · ", fill: "#4A5462" }, { t: "邊界契約", fill: C.cyan }] },
  { s: "legend", x: 1082, y: 86, t: "虛線 — Rivet 擁有的抽象" },
  { s: "legend", x: 1082, y: 110, t: "實線 — Swift 或 WebView 介面" },
  { s: "legend", x: 1143, y: 134, t: "顏色 — 所屬責任平面" },
  { s: "bn", x: 160, y: 1480, t: "此圖只表達所有權、編譯期依賴與 Swift／WebView 邊界。" },
  { s: "bn", x: 160, y: 1500, t: "既定 render dataflow 由同資料夾的 Archify dataflow artifact 表達。" },
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: "#8B93A1", alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill },
];
const CHIPS = ["swift", "presentation", "core", "pipeline", "boundary"]
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
