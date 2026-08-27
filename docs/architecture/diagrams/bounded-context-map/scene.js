const W = 1480, H = 1980;

// Rivet's map is intentionally an orientation map: dashed boxes are owned
// abstractions; solid boxes are app surfaces or swappable external concerns.
const PLANES = {
  presentation: { c: '#7DD3FC', label: '呈現層' },
  facade:       { c: '#A78BFA', label: 'Facade 層' },
  usecase:      { c: '#4ADE80', label: '核心 UseCase 層' },
  port:         { c: '#FBBF24', label: '內部 Port 與契約' },
  integration:  { c: '#F6821F', label: 'GitHub Integration 層' },
  outside:      { c: '#94A3B8', label: '外部世界' }
};

const BANDS = [
  { id: 'band-presentation', plane: 'presentation', x: 160, y: 200, w: 1260, h: 184, alpha: 0.5,
    hdr:  { x: 184, y: 230, t: '使用者與呈現層' },
    tagr: { x: 1396, y: 230, t: 'APP SURFACE · SESSION 非 BC', alpha: 0.6 } },

  { id: 'band-facade', plane: 'facade', x: 160, y: 470, w: 1260, h: 150, alpha: 0.55, dash: true,
    hdr:  { x: 184, y: 500, t: 'FACADE — 穩定的呈現層入口' },
    tagr: { x: 1396, y: 500, t: '內部擁有 · UI 從此進入', alpha: 0.6 } },

  // The neutral core band keeps the two parallel BCs visually equal while
  // separating their use cases from the ports and failure contracts they own.
  { id: 'band-core', plane: null, x: 160, y: 710, w: 1260, h: 460, stroke: '#3A4250', alpha: 1,
    hdr:  { x: 184, y: 740, t: '核心 BOUNDED CONTEXT', fill: C.slate },
    tagr: { x: 1396, y: 740, t: 'PR INBOX ║ PR READER — 不直接相依', fill: C.slate, alpha: 0.7 } },

  { id: 'band-integration', plane: 'integration', x: 160, y: 1260, w: 1260, h: 370, alpha: 0.48,
    hdr:  { x: 184, y: 1290, t: 'GITHUB INTEGRATION — SUPPORTING BC' },
    tagr: { x: 1396, y: 1290, t: 'ANTI-CORRUPTION BOUNDARY', alpha: 0.6 } },

  { id: 'band-outside', plane: 'outside', x: 160, y: 1720, w: 1260, h: 166, alpha: 0.48,
    hdr:  { x: 184, y: 1750, t: '外部世界 — GITHUB.COM' },
    tagr: { x: 1396, y: 1750, t: '外部系統', alpha: 0.6 } }
];

const BOXES = [
  // Actor & presentation -----------------------------------------------------
  { id: 'reviewer', plane: 'presentation', band: 'band-presentation', x: 200, y: 260, w: 220, h: 88, r: 10,
    name: '審閱者', about: '使用 Rivet 挑選與閱讀 Pull Request 的單一使用者。',
    texts: [ ['bl', 224, 288, '審閱者'], ['bs', 224, 310, '個人的 PR 工作流'], ['bn', 224, 332, '啟動分流迴圈'] ] },

  { id: 'inbox-view', plane: 'presentation', band: 'band-presentation', x: 450, y: 260, w: 280, h: 88, r: 10,
    name: 'PR Inbox View', about: '顯示目前待審閱佇列的原生介面。',
    texts: [ ['bl', 474, 288, 'PR Inbox View'], ['bs', 474, 310, '待審閱佇列 · 排序'], ['bn', 474, 332, '不定義佇列規則'] ] },

  { id: 'session', plane: 'presentation', band: 'band-presentation', x: 760, y: 260, w: 300, h: 88, r: 10,
    name: 'Presentation Session', about: '保存已選 PR 與導覽脈絡的 UI session state。',
    texts: [ ['bl', 784, 288, 'Presentation Session'], ['bs', 784, 310, '選取 PR · 切換'], ['bn', 784, 332, '僅是狀態 · 非 BC'] ] },

  { id: 'reader-view', plane: 'presentation', band: 'band-presentation', x: 1090, y: 260, w: 280, h: 88, r: 10,
    name: 'PR Reader View', about: '閱讀單一 Pull Request 與其變更的介面。',
    texts: [ ['bl', 1114, 288, 'PR Reader View'], ['bs', 1114, 310, '背景 · checks · diff'], ['bn', 1114, 332, '唯讀呈現'] ] },

  // Facades -----------------------------------------------------------------
  { id: 'inbox-facade', plane: 'facade', band: 'band-facade', x: 220, y: 530, w: 540, h: 68, r: 10, dash: true,
    name: 'Inbox Facade', about: '取得待審閱佇列的穩定呈現層入口。',
    texts: [ ['bl', 244, 558, 'Inbox Facade'], ['bs', 244, 580, '目前待審閱佇列的穩定入口'] ] },

  { id: 'reader-facade', plane: 'facade', band: 'band-facade', x: 820, y: 530, w: 540, h: 68, r: 10, dash: true,
    name: 'Reader Facade', about: '載入單一 PR 閱讀快照的穩定呈現層入口。',
    texts: [ ['bl', 844, 558, 'Reader Facade'], ['bs', 844, 580, '單一閱讀快照的穩定入口'] ] },

  // Core bounded contexts ----------------------------------------------------
  { id: 'refresh-queue', plane: 'usecase', band: 'band-core', x: 200, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: '更新待審閱佇列', about: '建立目前明確要求此使用者審閱的 Pull Request 集合。',
    texts: [ ['bl', 224, 823, '更新待審閱佇列'], ['bs', 224, 845, '建立候選 PR 集合'], ['bn', 224, 867, '空佇列是成功結果'] ] },

  { id: 'load-snapshot', plane: 'usecase', band: 'band-core', x: 800, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: '載入 PR 閱讀快照', about: '載入閱讀單一已選 Pull Request 所需的資料。',
    texts: [ ['bl', 824, 823, '載入 PR 閱讀快照'], ['bs', 824, 845, '載入一個已選 PR'], ['bn', 824, 867, '不決定 Inbox 成員'] ] },

  { id: 'queue-rules', plane: 'usecase', band: 'band-core', x: 200, y: 910, w: 540, h: 88, r: 10, dash: true,
    name: '待審閱佇列規則', about: '套用 Rivet 對待審閱佇列的定義與排序。',
    texts: [ ['bl', 224, 938, '待審閱佇列規則'], ['bs', 224, 960, 'open PR · 明確要求審閱'], ['bn', 224, 982, '排序屬於 PR Inbox'] ] },

  { id: 'reading-snapshot', plane: 'usecase', band: 'band-core', x: 800, y: 910, w: 540, h: 88, r: 10, dash: true,
    name: '閱讀快照', about: '組織閱讀所需的 PR 背景、討論、checks、檔案與 diff。',
    texts: [ ['bl', 824, 938, '閱讀快照'], ['bs', 824, 960, '背景 · 討論 · checks · diff'], ['bn', 824, 982, '閱讀模型屬於 PR Reader'] ] },

  { id: 'review-port', plane: 'port', band: 'band-core', x: 190, y: 1035, w: 280, h: 88, r: 10, dash: true,
    name: 'Review Request Source Port', about: '由 PR Inbox 擁有、取得 review request 資料的契約。',
    texts: [ ['bl', 214, 1063, 'Review Request Source'], ['bs', 214, 1085, 'Inbox 擁有的資料需求'], ['bn', 214, 1107, '不是 GitHub query'] ] },

  { id: 'inbox-failure', plane: 'port', band: 'band-core', x: 490, y: 1035, w: 250, h: 88, r: 10, dash: true,
    name: 'Inbox Failure Contract', about: 'PR Inbox 對呼叫端公開的語意失敗。',
    texts: [ ['bl', 514, 1063, 'Inbox Failure Contract'], ['bs', 514, 1085, '無法更新佇列'], ['bn', 514, 1107, '不得洩漏 HTTP status'] ] },

  { id: 'content-port', plane: 'port', band: 'band-core', x: 800, y: 1035, w: 280, h: 88, r: 10, dash: true,
    name: 'PR Content Source Port', about: '由 PR Reader 擁有、取得 PR 閱讀資料的契約。',
    texts: [ ['bl', 824, 1063, 'PR Content Source Port'], ['bs', 824, 1085, 'Reader 擁有的資料需求'], ['bn', 824, 1107, '不是 GitHub DTO'] ] },

  { id: 'reader-failure', plane: 'port', band: 'band-core', x: 1100, y: 1035, w: 250, h: 88, r: 10, dash: true,
    name: 'Reader Failure Contract', about: 'PR Reader 對呼叫端公開的語意失敗。',
    texts: [ ['bl', 1124, 1063, 'Reader Failure Contract'], ['bs', 1124, 1085, 'PR 內容不可讀'], ['bn', 1124, 1107, '不得洩漏 GitHub error'] ] },

  // GitHub Integration supporting BC ----------------------------------------
  { id: 'github-adapter', plane: 'integration', band: 'band-integration', x: 200, y: 1320, w: 1140, h: 88, r: 10,
    name: 'GitHub Data Adapter', about: '為兩個內部 Port 轉換 GitHub 資料的 anti-corruption 邊界。',
    texts: [ ['bl', 224, 1348, 'GitHub Data Adapter'], ['bs', 224, 1370, '為 Inbox 與 Reader Port 轉換外部資料'], ['bn', 224, 1392, 'GitHub DTO 不進入核心 BC'] ] },

  { id: 'identity-context', plane: 'integration', band: 'band-integration', x: 200, y: 1440, w: 540, h: 88, r: 10,
    name: 'GitHub Identity Context', about: 'Integration 邊界使用的外部身分與存取脈絡。',
    texts: [ ['bl', 224, 1468, 'GitHub Identity Context'], ['bs', 224, 1490, '外部身分 · 存取脈絡'], ['bn', 224, 1512, '不是獨立 Auth BC'] ] },

  { id: 'failure-normalizer', plane: 'integration', band: 'band-integration', x: 800, y: 1440, w: 540, h: 88, r: 10, dash: true,
    name: 'Failure Normalizer', about: '在 Adapter 邊界正規化 GitHub 與 transport failure。',
    texts: [ ['bl', 824, 1468, 'Failure Normalizer'], ['bs', 824, 1490, '分類外部 infrastructure failure'], ['bn', 824, 1512, '唯一的正規化邊界'] ] },

  { id: 'infra-unknown', plane: 'integration', band: 'band-integration', x: 800, y: 1548, w: 540, h: 68, r: 10, dash: true,
    name: 'InfraUnknownError', about: '無法安全分類之外部失敗的標準化結果。',
    texts: [ ['bl', 824, 1576, 'InfraUnknownError'], ['bs', 824, 1598, '未分類的外部 infrastructure failure'] ] },

  // Outside -----------------------------------------------------------------
  { id: 'github-api', plane: 'outside', band: 'band-outside', x: 200, y: 1780, w: 540, h: 68, r: 10,
    name: 'GitHub.com API', about: 'Pull Request、討論、check 與 diff 資料的外部來源。',
    texts: [ ['bl', 224, 1808, 'GitHub.com API'], ['bs', 224, 1830, 'PR · 討論 · checks · diff 資料'] ] },

  { id: 'github-auth', plane: 'outside', band: 'band-outside', x: 800, y: 1780, w: 540, h: 68, r: 10,
    name: 'GitHub Authorization', about: '取得 GitHub 資源存取權的外部授權世界。',
    texts: [ ['bl', 824, 1808, 'GitHub Authorization'], ['bs', 824, 1830, '外部授權系統'] ] }
];

const EDGES = [
  { from: 'reviewer', to: 'inbox-view', pts: [[424,304],[444,304]],
    label: { s: 'al', x: 434, y: 292, t: '分流', anchor: 'center' } },
  { from: 'inbox-view', to: 'session', pts: [[734,304],[754,304]],
    label: { s: 'al', x: 744, y: 292, t: '選取', anchor: 'center' } },
  { from: 'reader-view', to: 'session', pts: [[1086,304],[1066,304]] },

  { from: 'session', to: 'inbox-facade', pts: [[880,352],[880,414],[490,414],[490,524]],
    label: { s: 'al', x: 694, y: 406, t: '請求佇列', anchor: 'center' } },
  { from: 'session', to: 'reader-facade', pts: [[1000,352],[1000,524]],
    label: { s: 'al', x: 1014, y: 432, t: '已選 PR', rot: -90, anchor: 'center' } },

  { from: 'inbox-facade', to: 'refresh-queue', pts: [[490,602],[490,789]],
    label: { s: 'al', x: 504, y: 700, t: '更新', rot: -90, anchor: 'center' } },
  { from: 'reader-facade', to: 'load-snapshot', pts: [[1090,602],[1090,789]],
    label: { s: 'al', x: 1104, y: 700, t: '載入', rot: -90, anchor: 'center' } },
  { from: 'refresh-queue', to: 'queue-rules', pts: [[470,887],[470,904]],
    label: { s: 'al', x: 484, y: 897, t: '套用規則' } },
  { from: 'load-snapshot', to: 'reading-snapshot', pts: [[1070,887],[1070,904]],
    label: { s: 'al', x: 1084, y: 897, t: '組合' } },

  { from: 'queue-rules', to: 'review-port', pts: [[470,1002],[470,1018],[330,1018],[330,1029]],
    label: { s: 'al', x: 400, y: 1010, t: '資料需求', anchor: 'center' } },
  { from: 'reading-snapshot', to: 'content-port', pts: [[1070,1002],[1070,1018],[940,1018],[940,1029]],
    label: { s: 'al', x: 1005, y: 1010, t: '內容需求', anchor: 'center' } },

  { from: 'review-port', to: 'github-adapter', pts: [[330,1127],[330,1314]],
    label: { s: 'al', x: 344, y: 1220, t: '內部 Port', rot: -90, anchor: 'center' } },
  { from: 'content-port', to: 'github-adapter', pts: [[940,1127],[940,1314]],
    label: { s: 'al', x: 954, y: 1220, t: '內部 Port', rot: -90, anchor: 'center' } },
  { from: 'github-adapter', to: 'identity-context', pts: [[470,1412],[470,1434]],
    label: { s: 'al', x: 484, y: 1426, t: '存取脈絡' } },
  { from: 'identity-context', to: 'github-auth', pts: [[470,1532],[470,1650],[1070,1650],[1070,1774]],
    label: { s: 'al', x: 780, y: 1642, t: '授權', anchor: 'center' } },
  { from: 'github-adapter', to: 'github-api', pts: [[770,1412],[770,1670],[470,1670],[470,1774]],
    label: { s: 'al', x: 784, y: 1540, t: '讀取 GitHub 資料', rot: -90, anchor: 'center' } },

  { from: 'band-outside', to: 'failure-normalizer', pts: [[1424,1802],[1436,1802],[1436,1484],[1346,1484]],
    label: { s: 'al', x: 1452, y: 1640, t: '外部失敗', rot: -90, anchor: 'center' } },
  { from: 'failure-normalizer', to: 'infra-unknown', pts: [[1070,1532],[1070,1542]],
    label: { s: 'al', x: 1084, y: 1538, t: '正規化' } },
  { from: 'infra-unknown', to: 'inbox-failure', pts: [[794,1582],[116,1582],[116,1079],[484,1079]],
    label: { s: 'al', x: 100, y: 1330, t: '轉為 Inbox 語意', rot: -90, anchor: 'center' } },
  { from: 'infra-unknown', to: 'reader-failure', pts: [[1346,1582],[1436,1582],[1436,1079],[1356,1079]],
    label: { s: 'al', x: 1452, y: 1330, t: '轉為 Reader 語意', rot: -90, anchor: 'center' } }
];

const TEXTS = [
  { s: 'title', x: 160, y: 86, t: 'Rivet — Bounded Context 地圖' },
  { s: 'sub', x: 160, y: 118, t: '個人 GitHub PR 工作台：分流 → 選取 → 閱讀，GitHub 位於核心模型之外' },
  { s: 'tag', x: 160, y: 146, runs: [
    { t: 'PR Inbox', fill: C.green },
    { t: ' ║ ', fill: '#4A5462' },
    { t: 'PR Reader', fill: C.green },
    { t: ' ← 由其隔離：', fill: '#4A5462' },
    { t: 'GitHub Integration', fill: C.orange } ] },

  { s: 'legend', x: 1082, y: 86, t: '虛線 — 內部擁有的抽象' },
  { s: 'legend', x: 1082, y: 110, t: '實線 — app surface 與外部系統' },
  { s: 'legend', x: 1143, y: 134, t: '顏色 — 所屬的 plane' },

  { s: 'plane', x: 470, y: 775, t: 'PR INBOX', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 1070, y: 775, t: 'PR READER', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 620, y: 1020, t: '內部擁有的 PORT 與 FAILURE CONTRACT', anchor: 'center', fill: planeColor('port') },

  { s: 'bn', x: 160, y: 1926, t: '不變量：GitHub DTO、HTTP status 與 infrastructure failure 不直接進入 PR Inbox 或 PR Reader' },
  { s: 'bn', x: 160, y: 1946, t: '不變量：每個 BC 擁有自己的 failure contract；空待審閱佇列是成功結果' },
  { s: 'bn', x: 160, y: 1966, t: '延後而非不存在：Auth · Notification · Repository Catalog · Review Action · Sync/Cache' }
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: '#8B93A1', alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
];

const CHIPS = ['presentation', 'facade', 'usecase', 'port', 'integration', 'outside']
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
