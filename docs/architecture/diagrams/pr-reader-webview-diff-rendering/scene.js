const W = 1480, H = 1770;

// 此圖只呈現已鎖定的 declaration-only boundary；虛線是 Rivet 擁有的
// TypeScript abstraction，實線是 Swift 或 Presentation surface。
const PLANES = {
  swift: { c: "#94A3B8", label: "Swift 外部邊界" },
  adapter: { c: "#22D3EE", label: "介接邊界" },
  contract: { c: "#A78BFA", label: "資料契約" },
  core: { c: "#F6821F", label: "管線核心" },
  presentation: { c: "#7DD3FC", label: "呈現層" },
};

const BANDS = [
  {
    id: "band-swift", plane: "swift", x: 160, y: 200, w: 1260, h: 150,
    alpha: 0.5,
    hdr: { x: 184, y: 230, t: "SWIFT — 快照與 viewed 權威" },
    tagr: { x: 1396, y: 230, t: "外部世界", alpha: 0.6 },
  },
  {
    id: "band-adapter", plane: "adapter", x: 160, y: 430, w: 1260, h: 170,
    alpha: 0.5, dash: true,
    hdr: { x: 184, y: 460, t: "介接邊界" },
    tagr: { x: 1396, y: 460, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 },
  },
  {
    id: "band-contract", plane: "contract", x: 160, y: 680, w: 1260, h: 188,
    alpha: 0.5, dash: true,
    hdr: { x: 184, y: 710, t: "PR READER 差異契約" },
    tagr: { x: 1396, y: 710, t: "RIVET 擁有 — 公開資料", alpha: 0.6 },
  },
  {
    id: "band-core", plane: "core", x: 160, y: 948, w: 1260, h: 350,
    alpha: 0.5, dash: true,
    hdr: { x: 184, y: 978, t: "管線 PORTS 與 USECASE" },
    tagr: { x: 1396, y: 978, t: "RIVET 擁有 — 僅有宣告", alpha: 0.6 },
  },
  {
    id: "band-presentation", plane: "presentation", x: 160, y: 1378, w: 1260, h: 190,
    alpha: 0.5,
    hdr: { x: 184, y: 1408, t: "呈現層入口" },
    tagr: { x: 1396, y: 1408, t: "WEBVIEW 介面", alpha: 0.6 },
  },
];

const BOXES = [
  {
    id: "swift-snapshot", plane: "swift", band: "band-swift", x: 200, y: 260, w: 500, h: 70, r: 10,
    name: "Swift 快照發送端", about: "Swift 提供完整且有序的 DiffViewModel 快照。",
    texts: [["bl", 224, 288, "Swift 快照發送端"], ["bs", 224, 310, "完整、有序的 DiffViewModel[]"]],
  },
  {
    id: "swift-viewed", plane: "swift", band: "band-swift", x: 780, y: 260, w: 600, h: 70, r: 10,
    name: "Swift viewed 權威", about: "Swift 持久化 viewed 狀態，並可忽略過期通知。",
    texts: [["bl", 804, 288, "Swift viewed 權威"], ["bs", 804, 310, "唯一持久化權威 · 忽略過期通知"]],
  },
  {
    id: "snapshot-adapter", plane: "adapter", band: "band-adapter", x: 200, y: 490, w: 500, h: 78, r: 10, dash: true,
    name: "DiffSnapshotAdapter", about: "宣告 Swift 快照輸入邊界，不包含橋接行為。",
    texts: [["bl", 224, 518, "DiffSnapshotAdapter"], ["bs", 224, 540, "Swift 快照輸入邊界"]],
  },
  {
    id: "viewed-adapter", plane: "adapter", band: "band-adapter", x: 780, y: 490, w: 600, h: 78, r: 10, dash: true,
    name: "ViewedStateChangeAdapter", about: "宣告回傳 Swift 的單向 viewed 通知邊界。",
    texts: [["bl", 804, 518, "ViewedStateChangeAdapter"], ["bs", 804, 540, "單向 viewed 通知邊界"]],
  },
  {
    id: "diff-model", plane: "contract", band: "band-contract", x: 200, y: 740, w: 360, h: 94, r: 10, dash: true,
    name: "DiffViewModel", about: "Swift 傳入差異管線的完整檔案快照契約。",
    texts: [["bl", 224, 768, "DiffViewModel"], ["bs", 224, 790, "fileId · patch · viewed"], ["bn", 224, 816, "快照內的檔案身分"]],
  },
  {
    id: "viewed-change", plane: "contract", band: "band-contract", x: 610, y: 740, w: 360, h: 94, r: 10, dash: true,
    name: "ViewedStateChange", about: "以 PR、快照、檔案與布林狀態識別 viewed 事件。",
    texts: [["bl", 634, 768, "ViewedStateChange"], ["bs", 634, 790, "PR · 快照 · 檔案 · viewed"], ["bn", 634, 816, "Swift 可安全忽略過期事件"]],
  },
  {
    id: "render-outcome", plane: "contract", band: "band-contract", x: 1020, y: 740, w: 360, h: 94, r: 10, dash: true,
    name: "DiffRenderOutcome", about: "公開結果區分驗證、剖析、渲染與輸出失敗。",
    texts: [["bl", 1044, 768, "DiffRenderOutcome"], ["bs", 1044, 790, "success 或四類失敗"], ["bn", 1044, 816, "output-error 是獨立階段"]],
  },
  {
    id: "validator-port", plane: "core", band: "band-core", x: 190, y: 1018, w: 220, h: 82, r: 10, dash: true,
    name: "驗證 Port", about: "宣告完整檔案快照的驗證。",
    texts: [["bl", 210, 1046, "驗證 Port"], ["bs", 210, 1068, "檔案 → 已驗證輸入"]],
  },
  {
    id: "parser-port", plane: "core", band: "band-core", x: 435, y: 1018, w: 220, h: 82, r: 10, dash: true,
    name: "剖析 Port", about: "宣告從已驗證輸入到已剖析輸入的轉換。",
    texts: [["bl", 455, 1046, "剖析 Port"], ["bs", 455, 1068, "已驗證 → 已剖析"]],
  },
  {
    id: "renderer-port", plane: "core", band: "band-core", x: 680, y: 1018, w: 220, h: 82, r: 10, dash: true,
    name: "渲染 Port", about: "宣告從已剖析輸入到不透明 RenderPlan 的轉換。",
    texts: [["bl", 700, 1046, "渲染 Port"], ["bs", 700, 1068, "已剖析 → RenderPlan"]],
  },
  {
    id: "output-port", plane: "core", band: "band-core", x: 925, y: 1018, w: 220, h: 82, r: 10, dash: true,
    name: "輸出 Port", about: "宣告最終輸出階段與其 output-error 失敗。",
    texts: [["bl", 945, 1046, "輸出 Port"], ["bs", 945, 1068, "計畫 → output-error"]],
  },
  {
    id: "viewed-port", plane: "core", band: "band-core", x: 1170, y: 1018, w: 220, h: 82, r: 10, dash: true,
    name: "Viewed 通知 Port", about: "宣告無確認回覆的單向 viewed 狀態通知。",
    texts: [["bl", 1190, 1046, "Viewed 通知 Port"], ["bs", 1190, 1068, "通知 → void"]],
  },
  {
    id: "usecase", plane: "core", band: "band-core", x: 350, y: 1150, w: 480, h: 108, r: 10, dash: true,
    name: "DiffRenderUseCase", about: "唯一被宣告的 Validator、Parser、Renderer 與 Output Ports 協調者。",
    texts: [["bl", 374, 1178, "DiffRenderUseCase"], ["bs", 374, 1200, "唯一協調 Validator → Parser"], ["bs", 374, 1216, "→ Renderer → Output"], ["bn", 374, 1238, "Output Port 的唯一 caller"]],
  },
  {
    id: "facade", plane: "presentation", band: "band-presentation", x: 290, y: 1448, w: 460, h: 86, r: 10, dash: true,
    name: "DiffFacade", about: "呈現層入口與 viewed 通知委派的擁有者。",
    texts: [["bl", 314, 1476, "DiffFacade"], ["bs", 314, 1498, "present · requestViewedStateChange"], ["bn", 314, 1518, "不依賴 Output Port"]],
  },
  {
    id: "webview", plane: "presentation", band: "band-presentation", x: 830, y: 1448, w: 460, h: 86, r: 10, r: 10,
    name: "WebView 呈現層", about: "使用 Facade 契約的原生呈現介面。",
    texts: [["bl", 854, 1476, "WebView 呈現層"], ["bs", 854, 1498, "呼叫 Facade 的公開入口"]],
  },
];

const EDGES = [
  { from: "swift-snapshot", to: "snapshot-adapter", pts: [[450,334], [450,484]], label: { s: "al", x: 464, y: 412, t: "快照" } },
  { from: "snapshot-adapter", to: "diff-model", pts: [[450,572], [450,734]], label: { s: "al", x: 464, y: 650, t: "宣告輸入" } },
  { from: "diff-model", to: "validator-port", pts: [[380,838], [380,1012]], label: { s: "al", x: 394, y: 930, t: "檔案" } },
  { from: "validator-port", to: "parser-port", pts: [[414,1059], [429,1059]] },
  { from: "parser-port", to: "renderer-port", pts: [[659,1059], [674,1059]] },
  { from: "renderer-port", to: "output-port", pts: [[904,1059], [919,1059]] },
  { from: "usecase", to: "validator-port", pts: [[450,1144], [450,1110], [300,1110], [300,1104]], label: { s: "al", x: 464, y: 1134, t: "協調" } },
  { from: "usecase", to: "output-port", pts: [[730,1144], [730,1118], [1035,1118], [1035,1104]], label: { s: "al", x: 744, y: 1134, t: "唯一呼叫端" } },
  { from: "usecase", to: "facade", pts: [[590,1262], [590,1442]], label: { s: "al", x: 604, y: 1360, t: "DiffRenderOutcome" } },
  { from: "facade", to: "webview", pts: [[754,1491], [824,1491]], label: { s: "al", x: 789, y: 1479, t: "公開入口", anchor: "center" } },
  { from: "webview", to: "facade", pts: [[1050,1442], [1050,1418], [770,1418], [770,1478]], label: { s: "al", x: 1064, y: 1410, t: "viewed 操作" } },
  { from: "facade", to: "viewed-port", pts: [[750,1460], [1150,1460], [1150,1110], [1280,1110], [1280,1104]], label: { s: "al", x: 1136, y: 1270, t: "單向通知", rot: -90, anchor: "center" } },
  { from: "viewed-port", to: "viewed-change", pts: [[1280,1012], [1280,900], [790,900], [790,838]], label: { s: "al", x: 1294, y: 936, t: "身分", rot: -90, anchor: "center" } },
  { from: "viewed-change", to: "viewed-adapter", pts: [[790,734], [790,574]], label: { s: "al", x: 804, y: 650, t: "通知" } },
  { from: "viewed-adapter", to: "swift-viewed", pts: [[1080,484], [1080,334]], label: { s: "al", x: 1094, y: 412, t: "傳送" } },
  { from: "output-port", to: "render-outcome", pts: [[1035,1012], [1035,838]], label: { s: "al", x: 1049, y: 930, t: "output-error" } },
];

const TEXTS = [
  { s: "title", x: 160, y: 86, t: "PR Reader — WebView 差異管線" },
  { s: "sub", x: 160, y: 118, t: "Swift 快照 → 已宣告管線 → Facade → WebView · viewed 通知回傳 Swift" },
  { s: "tag", x: 160, y: 146, runs: [
    { t: "快照", fill: C.slate }, { t: " → ", fill: "#4A5462" },
    { t: "契約", fill: C.violet }, { t: " → ", fill: "#4A5462" },
    { t: "管線", fill: C.orange }, { t: " → ", fill: "#4A5462" },
    { t: "呈現層", fill: C.sky },
  ] },
  { s: "legend", x: 1082, y: 86, t: "虛線 — Rivet 擁有的抽象" },
  { s: "legend", x: 1082, y: 110, t: "實線 — Swift 或呈現層介面" },
  { s: "legend", x: 1143, y: 134, t: "顏色 — 所屬責任平面" },
  { s: "bn", x: 160, y: 1664, t: "不變量：Swift 是 viewed 的唯一持久化權威；WebView 不等待確認回覆，也不修改快照" },
  { s: "bn", x: 160, y: 1684, t: "不變量：DiffRenderUseCase 是 Validator → Parser → Renderer → Output 的唯一協調者與 Output 呼叫端" },
  { s: "bn", x: 160, y: 1704, t: "邊界：本圖只描述介面；未定義具體 Adapter、Parser、Renderer、Output、DOM 或 Swift 橋接" },
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: "#8B93A1", alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill },
];

const CHIPS = ["swift", "adapter", "contract", "core", "presentation"]
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
