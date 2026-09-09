const W = 1480, H = 2030;

// 虛線表示 Rivet 擁有的抽象；實線表示 app surface、Supporting BC 邊界或外部系統。
const PLANES = {
  presentation: { c: '#7DD3FC', label: '呈現層' },
  facade: { c: '#A78BFA', label: 'Facade 層' },
  usecase: { c: '#4ADE80', label: 'BC UseCase 層' },
  port: { c: '#FBBF24', label: '內部 Port 與契約' },
  integration: { c: '#F6821F', label: 'GitHub Integration Supporting BC' },
  outside: { c: '#94A3B8', label: '外部世界' }
};

const BANDS = [
  { id: 'band-presentation', plane: 'presentation', x: 160, y: 200, w: 1260, h: 184, alpha: 0.5,
    hdr: { x: 184, y: 230, t: '使用者與呈現層' }, tagr: { x: 1396, y: 230, t: 'APP SURFACE · SESSION 非 BC', alpha: 0.6 } },
  { id: 'band-facade', plane: 'facade', x: 160, y: 470, w: 1260, h: 150, alpha: 0.55, dash: true,
    hdr: { x: 184, y: 500, t: 'FACADE — 穩定的呈現層入口' }, tagr: { x: 1396, y: 500, t: '內部擁有 · COMPILE-TIME DIRECTION', alpha: 0.6 } },
  { id: 'band-core', plane: null, x: 160, y: 710, w: 1260, h: 460, stroke: '#3A4250', alpha: 1,
    hdr: { x: 184, y: 740, t: 'BOUNDED CONTEXT CORE' }, tagr: { x: 1396, y: 740, t: 'PR INBOX ║ PR READER — 不直接相依', alpha: 0.7 } },
  { id: 'band-integration', plane: 'integration', x: 160, y: 1260, w: 1260, h: 370, alpha: 0.48,
    hdr: { x: 184, y: 1290, t: 'GITHUB INTEGRATION — SUPPORTING BC 邊界' }, tagr: { x: 1396, y: 1290, t: '外部協定 · 身分 · DTO · FAILURE ISOLATION', alpha: 0.6 } },
  { id: 'band-outside', plane: 'outside', x: 160, y: 1720, w: 1260, h: 166, alpha: 0.48,
    hdr: { x: 184, y: 1750, t: '外部世界 — GITHUB.COM' }, tagr: { x: 1396, y: 1750, t: 'OUTSIDE', alpha: 0.6 } }
];

const BOXES = [
  { id: 'reviewer', plane: 'presentation', band: 'band-presentation', x: 200, y: 260, w: 220, h: 88, r: 10,
    name: '審閱者', about: '使用 Rivet 挑選與閱讀 Pull Request 的單一使用者。', texts: [['bl', 224, 288, '審閱者'], ['bs', 224, 310, '個人的 PR 工作流'], ['bn', 224, 332, '啟動分流迴圈']] },
  { id: 'inbox-view', plane: 'presentation', band: 'band-presentation', x: 450, y: 260, w: 280, h: 88, r: 10,
    name: 'PR Inbox View', about: '顯示目前待審閱佇列的原生介面。', texts: [['bl', 474, 288, 'PR Inbox View'], ['bs', 474, 310, '待審閱佇列 · 排序'], ['bn', 474, 332, '不定義佇列規則']] },
  { id: 'session', plane: 'presentation', band: 'band-presentation', x: 760, y: 260, w: 300, h: 88, r: 10,
    name: 'Presentation Session', about: '保存已選 PR 與導覽脈絡的 UI session state。', texts: [['bl', 784, 288, 'Presentation Session'], ['bs', 784, 310, '選取 PR · 切換'], ['bn', 784, 332, '僅是狀態 · 非 BC']] },
  { id: 'reader-view', plane: 'presentation', band: 'band-presentation', x: 1090, y: 260, w: 280, h: 88, r: 10,
    name: 'PR Reader View', about: '閱讀單一 Pull Request 與其變更的介面。', texts: [['bl', 1114, 288, 'PR Reader View'], ['bs', 1114, 310, '背景 · checks · diff'], ['bn', 1114, 332, '唯讀呈現']] },

  { id: 'inbox-facade', plane: 'facade', band: 'band-facade', x: 220, y: 530, w: 540, h: 68, r: 10, dash: true,
    name: 'Inbox Facade', about: '取得待審閱佇列的穩定呈現層入口。', texts: [['bl', 244, 558, 'Inbox Facade'], ['bs', 244, 580, '目前待審閱佇列的穩定入口']] },
  { id: 'reader-facade', plane: 'facade', band: 'band-facade', x: 820, y: 530, w: 540, h: 68, r: 10, dash: true,
    name: 'Reader Facade', about: '載入單一 PR 閱讀快照的穩定呈現層入口。', texts: [['bl', 844, 558, 'Reader Facade'], ['bs', 844, 580, '單一閱讀快照的穩定入口']] },

  { id: 'inbox-usecase', plane: 'usecase', band: 'band-core', x: 200, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: 'PR Inbox UseCase', about: '協調待審閱佇列的更新與排序語意。', texts: [['bl', 224, 823, 'PR Inbox UseCase'], ['bs', 224, 845, '更新佇列 · 套用排序'], ['bn', 224, 867, '空佇列是成功結果']] },
  { id: 'reader-usecase', plane: 'usecase', band: 'band-core', x: 800, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: 'PR Reader UseCase', about: '協調單一 PR 的閱讀快照。', texts: [['bl', 824, 823, 'PR Reader UseCase'], ['bs', 824, 845, '載入背景 · 討論 · diff'], ['bn', 824, 867, '不決定 Inbox 成員']] },
  { id: 'inbox-port', plane: 'port', band: 'band-core', x: 190, y: 1000, w: 280, h: 104, r: 10, dash: true,
    name: 'Inbox Port', about: '由 PR Inbox 擁有的資料需求。', texts: [['bl', 214, 1028, 'Review Request Source'], ['bs', 214, 1050, 'Inbox 擁有的資料需求'], ['bn', 214, 1074, '不是 GitHub query']] },
  { id: 'inbox-failure', plane: 'port', band: 'band-core', x: 490, y: 1000, w: 250, h: 104, r: 10, dash: true,
    name: 'Inbox Failure Contract', about: 'PR Inbox 對呼叫端公開的語意失敗。', texts: [['bl', 514, 1028, 'Inbox Failure Contract'], ['bs', 514, 1050, '無法更新佇列'], ['bn', 514, 1074, '不洩漏 HTTP status']] },
  { id: 'reader-port', plane: 'port', band: 'band-core', x: 800, y: 1000, w: 280, h: 104, r: 10, dash: true,
    name: 'Reader Port', about: '由 PR Reader 擁有的資料需求。', texts: [['bl', 824, 1028, 'PR Content Source Port'], ['bs', 824, 1050, 'Reader 擁有的資料需求'], ['bn', 824, 1074, '不是 GitHub DTO']] },
  { id: 'reader-failure', plane: 'port', band: 'band-core', x: 1100, y: 1000, w: 250, h: 104, r: 10, dash: true,
    name: 'Reader Failure Contract', about: 'PR Reader 對呼叫端公開的語意失敗。', texts: [['bl', 1124, 1028, 'Reader Failure Contract'], ['bs', 1124, 1050, 'PR 內容不可讀'], ['bn', 1124, 1074, '不洩漏 GitHub error']] },

  { id: 'github-integration', plane: 'integration', band: 'band-integration', x: 200, y: 1320, w: 1140, h: 88, r: 10,
    name: 'GitHub Integration Supporting BC', about: '集中隔離 GitHub 外部協定、身分、DTO 與 infrastructure failure 的 Supporting BC。', texts: [['bl', 224, 1348, 'GitHub Integration Supporting BC'], ['bs', 224, 1370, '集中外部協定 · 身分 · DTO · infrastructure failure 邊界'], ['bn', 224, 1392, '不使外部細節進入 Core、UseCase 或 Port']] },
  { id: 'integration-adapter', plane: 'integration', band: 'band-integration', x: 200, y: 1440, w: 540, h: 88, r: 10, dash: true,
    name: 'Integration Adapter Boundary', about: '在 Supporting BC 內轉換外部資料以符合各核心 BC 自己擁有的 Port。', texts: [['bl', 224, 1468, 'Integration Adapter Boundary'], ['bs', 224, 1490, '外部資料 → 各 BC 自己的 Port'], ['bn', 224, 1512, '不建立 BC-to-BC 依賴']] },
  { id: 'failure-normalizer', plane: 'integration', band: 'band-integration', x: 800, y: 1440, w: 540, h: 88, r: 10, dash: true,
    name: 'Failure Normalizer', about: '在 Integration Adapter 邊界正規化 GitHub 與 infrastructure failure。', texts: [['bl', 824, 1468, 'Failure Normalizer'], ['bs', 824, 1490, '分類外部 infrastructure failure'], ['bn', 824, 1512, '跨 Port 前映射為 BC 語意']] },
  { id: 'infra-unknown', plane: 'integration', band: 'band-integration', x: 800, y: 1548, w: 540, h: 68, r: 10, dash: true,
    name: 'InfraUnknownError', about: '無法安全分類之外部失敗的標準化結果。', texts: [['bl', 824, 1576, 'InfraUnknownError'], ['bs', 824, 1598, '不跨越 core Port']] },

  { id: 'github-outside', plane: 'outside', band: 'band-outside', x: 200, y: 1780, w: 1140, h: 68, r: 10,
    name: 'GitHub.com', about: 'GitHub 的 API、身分與授權皆屬 Rivet 的外部世界。', texts: [['bl', 224, 1808, 'GitHub.com'], ['bs', 224, 1830, '外部 API · 身分 · 授權']] }
];

// 所有連線僅表示編譯期方向與 ownership；此 canvas 不描述 runtime request 或 dataflow。
const EDGES = [
  { from: 'inbox-view', to: 'inbox-facade', pts: [[590,352],[590,524]], label: { s: 'al', x: 604, y: 440, t: '編譯期依賴', rot: -90, anchor: 'center' } },
  { from: 'reader-view', to: 'reader-facade', pts: [[1230,352],[1230,524]], label: { s: 'al', x: 1244, y: 440, t: '編譯期依賴', rot: -90, anchor: 'center' } },
  { from: 'inbox-facade', to: 'inbox-usecase', pts: [[490,602],[490,789]], label: { s: 'al', x: 504, y: 700, t: '編譯期依賴', rot: -90, anchor: 'center' } },
  { from: 'reader-facade', to: 'reader-usecase', pts: [[1090,602],[1090,789]], label: { s: 'al', x: 1104, y: 700, t: '編譯期依賴', rot: -90, anchor: 'center' } },
  { from: 'inbox-usecase', to: 'inbox-port', pts: [[470,887],[470,940],[330,940],[330,994]], label: { s: 'al', x: 400, y: 932, t: 'Inbox 擁有 Port', anchor: 'center' } },
  { from: 'reader-usecase', to: 'reader-port', pts: [[1070,887],[1070,940],[940,940],[940,994]], label: { s: 'al', x: 1005, y: 932, t: 'Reader 擁有 Port', anchor: 'center' } }
];

const TEXTS = [
  { s: 'title', x: 160, y: 86, t: 'Rivet — Bounded Context 地圖' },
  { s: 'sub', x: 160, y: 118, t: '個人 GitHub PR 工作台：分流 → 選取 → 閱讀；Integration 隔離 GitHub 外部世界' },
  { s: 'tag', x: 160, y: 146, runs: [{ t: 'PR Inbox', fill: C.green }, { t: ' ║ ', fill: '#4A5462' }, { t: 'PR Reader', fill: C.green }, { t: ' ← boundary: ', fill: '#4A5462' }, { t: 'GitHub Integration', fill: C.orange }] },
  { s: 'legend', x: 1082, y: 86, t: '虛線 — 內部擁有的抽象' },
  { s: 'legend', x: 1082, y: 110, t: '實線 — app surface、Supporting BC 與 Outside' },
  { s: 'legend', x: 1143, y: 134, t: '顏色 — 所屬的 plane' },
  { s: 'plane', x: 470, y: 775, t: 'PR INBOX', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 1070, y: 775, t: 'PR READER', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 620, y: 985, t: '內部擁有的 PORT 與 FAILURE CONTRACT', anchor: 'center', fill: planeColor('port') },
  { s: 'bn', x: 160, y: 1976, t: '不變量：Core、UseCase、Port 不依賴 GitHub 外部協定；PR Inbox 與 PR Reader 沒有 compile-time dependency' },
  { s: 'bn', x: 160, y: 1996, t: '不變量：GitHub Integration 隔離外部資料與 failure；每個 core BC 保有自己的 failure contract' },
  { s: 'bn', x: 160, y: 2016, t: '此圖僅表達 ownership 與 compile-time boundary，不表達 runtime、REST、GraphQL 或 authorization dataflow' }
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: '#8B93A1', alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
];

const CHIPS = ['presentation', 'facade', 'usecase', 'port', 'integration', 'outside']
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
