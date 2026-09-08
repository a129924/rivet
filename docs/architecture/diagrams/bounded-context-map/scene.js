const W = 1480, H = 2030;

// 虛線表示 Rivet 擁有的抽象；實線表示 app surface、技術面或外部系統。
const PLANES = {
  presentation: { c: '#7DD3FC', label: '呈現層' },
  facade: { c: '#A78BFA', label: 'Facade 層' },
  usecase: { c: '#4ADE80', label: 'BC UseCase 層' },
  port: { c: '#FBBF24', label: '內部 Port 與契約' },
  infra: { c: '#F6821F', label: '各 BC 的 GitHub Infra' },
  outside: { c: '#94A3B8', label: '外部世界' }
};

const BANDS = [
  { id: 'band-presentation', plane: 'presentation', x: 160, y: 200, w: 1260, h: 184, alpha: 0.5,
    hdr: { x: 184, y: 230, t: '使用者與呈現層' }, tagr: { x: 1396, y: 230, t: 'APP SURFACE · SESSION 非 BC', alpha: 0.6 } },
  { id: 'band-facade', plane: 'facade', x: 160, y: 470, w: 1260, h: 150, alpha: 0.55, dash: true,
    hdr: { x: 184, y: 500, t: 'FACADE — 穩定的呈現層入口' }, tagr: { x: 1396, y: 500, t: '內部擁有 · UI 從此進入', alpha: 0.6 } },
  { id: 'band-usecase', plane: null, x: 160, y: 710, w: 1260, h: 460, stroke: '#3A4250', alpha: 1,
    hdr: { x: 184, y: 740, t: 'BOUNDED CONTEXT APPLICATION' }, tagr: { x: 1396, y: 740, t: 'PR INBOX ║ PR READER — 不直接相依', alpha: 0.7 } },
  { id: 'band-infra', plane: 'infra', x: 160, y: 1260, w: 1260, h: 370, alpha: 0.48,
    hdr: { x: 184, y: 1290, t: '各 BC 的 GITHUB INFRA — 未來外部協定邊界' }, tagr: { x: 1396, y: 1290, t: '不設集中 GITHUB 邊界', alpha: 0.6 } },
  { id: 'band-outside', plane: 'outside', x: 160, y: 1720, w: 1260, h: 166, alpha: 0.48,
    hdr: { x: 184, y: 1750, t: '外部世界 — GITHUB.COM' }, tagr: { x: 1396, y: 1750, t: '外部系統', alpha: 0.6 } }
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
  { id: 'inbox-usecase', plane: 'usecase', band: 'band-usecase', x: 200, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: 'PR Inbox UseCase', about: '協調待審閱佇列的更新與排序語意。', texts: [['bl', 224, 823, 'PR Inbox UseCase'], ['bs', 224, 845, '更新佇列 · 套用排序'], ['bn', 224, 867, '空佇列是成功結果']] },
  { id: 'reader-usecase', plane: 'usecase', band: 'band-usecase', x: 800, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: 'PR Reader UseCase', about: '協調單一 PR 的閱讀快照。', texts: [['bl', 824, 823, 'PR Reader UseCase'], ['bs', 824, 845, '載入背景 · 討論 · diff'], ['bn', 824, 867, '不決定 Inbox 成員']] },
  { id: 'inbox-port', plane: 'port', band: 'band-usecase', x: 190, y: 1000, w: 280, h: 104, r: 10, dash: true,
    name: 'Inbox Port', about: '由 PR Inbox 擁有的資料需求。', texts: [['bl', 214, 1028, 'Review Request Source'], ['bs', 214, 1050, 'Inbox 擁有的資料需求'], ['bn', 214, 1074, '不是 GitHub query']] },
  { id: 'inbox-failure', plane: 'port', band: 'band-usecase', x: 490, y: 1000, w: 250, h: 104, r: 10, dash: true,
    name: 'Inbox Failure Contract', about: 'PR Inbox 對呼叫端公開的語意失敗。', texts: [['bl', 514, 1028, 'Inbox Failure Contract'], ['bs', 514, 1050, '無法更新佇列'], ['bn', 514, 1074, '不洩漏 HTTP status']] },
  { id: 'reader-port', plane: 'port', band: 'band-usecase', x: 800, y: 1000, w: 280, h: 104, r: 10, dash: true,
    name: 'Reader Port', about: '由 PR Reader 擁有的資料需求。', texts: [['bl', 824, 1028, 'PR Content Source Port'], ['bs', 824, 1050, 'Reader 擁有的資料需求'], ['bn', 824, 1074, '不是 GitHub DTO']] },
  { id: 'reader-failure', plane: 'port', band: 'band-usecase', x: 1100, y: 1000, w: 250, h: 104, r: 10, dash: true,
    name: 'Reader Failure Contract', about: 'PR Reader 對呼叫端公開的語意失敗。', texts: [['bl', 1124, 1028, 'Reader Failure Contract'], ['bs', 1124, 1050, 'PR 內容不可讀'], ['bn', 1124, 1074, '不洩漏 GitHub error']] },
  { id: 'inbox-infra', plane: 'infra', band: 'band-infra', x: 200, y: 1320, w: 540, h: 88, r: 10,
    name: 'PR Inbox GitHub Infra', about: 'PR Inbox 未來獨自擁有的 GitHub adapter、endpoint、DTO 與 failure mapping 邊界。', texts: [['bl', 224, 1348, 'PR Inbox GitHub Infra'], ['bs', 224, 1370, 'adapter · endpoint · DTO mapping'], ['bn', 224, 1392, '只服務 Inbox 自己的 Port']] },
  { id: 'reader-infra', plane: 'infra', band: 'band-infra', x: 800, y: 1320, w: 540, h: 88, r: 10,
    name: 'PR Reader GitHub Infra', about: 'PR Reader 未來獨自擁有的 GitHub adapter、operation、DTO 與 failure mapping 邊界。', texts: [['bl', 824, 1348, 'PR Reader GitHub Infra'], ['bs', 824, 1370, 'adapter · operation · DTO mapping'], ['bn', 824, 1392, '只服務 Reader 自己的 Port']] },
  { id: 'github-transport', plane: 'infra', band: 'band-infra', x: 560, y: 1440, w: 360, h: 88, r: 10, dash: true,
    name: 'GitHubTransport', about: '尚未實作的 non-BC technical boundary；未來只供各 BC Infra 執行 GitHub request。', texts: [['bl', 584, 1468, 'GitHubTransport'], ['bs', 584, 1490, 'request · auth · rate limit'], ['bn', 584, 1512, 'future technical boundary · 未實作']] },
  { id: 'inbox-infra-failure', plane: 'infra', band: 'band-infra', x: 200, y: 1548, w: 540, h: 68, r: 10,
    name: 'Inbox Infra Failure Mapping', about: '僅在 PR Inbox Infra 將外部與技術層 failure 映射為 Inbox 語意。', texts: [['bl', 224, 1576, 'Inbox Infra Failure Mapping'], ['bs', 224, 1598, '外部 failure → Inbox 語意']] },
  { id: 'reader-infra-failure', plane: 'infra', band: 'band-infra', x: 800, y: 1548, w: 540, h: 68, r: 10,
    name: 'Reader Infra Failure Mapping', about: '僅在 PR Reader Infra 將外部與技術層 failure 映射為 Reader 語意。', texts: [['bl', 824, 1576, 'Reader Infra Failure Mapping'], ['bs', 824, 1598, '外部 failure → Reader 語意']] },
  { id: 'github-rest', plane: 'outside', band: 'band-outside', x: 200, y: 1780, w: 340, h: 68, r: 10,
    name: 'GitHub REST API', about: '各 BC Infra 可依需要採用的外部 REST 協定。', texts: [['bl', 224, 1808, 'GitHub REST API'], ['bs', 224, 1830, '外部 endpoint · response']] },
  { id: 'github-graphql', plane: 'outside', band: 'band-outside', x: 580, y: 1780, w: 340, h: 68, r: 10,
    name: 'GitHub GraphQL API', about: '各 BC Infra 可依需要採用的外部 GraphQL 協定。', texts: [['bl', 604, 1808, 'GitHub GraphQL API'], ['bs', 604, 1830, '外部 schema · operation']] },
  { id: 'github-auth', plane: 'outside', band: 'band-outside', x: 960, y: 1780, w: 380, h: 68, r: 10,
    name: 'GitHub Authorization', about: 'GitHub 存取權屬於外部授權世界。', texts: [['bl', 984, 1808, 'GitHub Authorization'], ['bs', 984, 1830, '外部授權系統']] }
];

const EDGES = [
  { from: 'reviewer', to: 'inbox-view', pts: [[424,304],[444,304]] },
  { from: 'inbox-view', to: 'session', pts: [[734,304],[754,304]] },
  { from: 'reader-view', to: 'session', pts: [[1086,304],[1066,304]] },
  { from: 'session', to: 'inbox-facade', pts: [[880,352],[880,414],[490,414],[490,524]], label: { s: 'al', x: 694, y: 406, t: '請求佇列', anchor: 'center' } },
  { from: 'session', to: 'reader-facade', pts: [[1000,352],[1000,524]] },
  { from: 'inbox-facade', to: 'inbox-usecase', pts: [[490,602],[490,789]] },
  { from: 'reader-facade', to: 'reader-usecase', pts: [[1090,602],[1090,789]] },
  { from: 'inbox-usecase', to: 'inbox-port', pts: [[470,887],[470,940],[330,940],[330,994]] },
  { from: 'reader-usecase', to: 'reader-port', pts: [[1070,887],[1070,940],[940,940],[940,994]] },
  { from: 'inbox-port', to: 'inbox-infra', pts: [[330,1108],[330,1314]], label: { s: 'al', x: 344, y: 1216, t: 'Inbox Port', rot: -90, anchor: 'center' } },
  { from: 'reader-port', to: 'reader-infra', pts: [[940,1108],[940,1314]], label: { s: 'al', x: 954, y: 1216, t: 'Reader Port', rot: -90, anchor: 'center' } },
  { from: 'band-outside', to: 'inbox-infra-failure', pts: [[156,1802],[116,1802],[116,1582],[194,1582]], label: { s: 'al', x: 100, y: 1692, t: '外部 failure', rot: -90, anchor: 'center' } },
  { from: 'band-outside', to: 'reader-infra-failure', pts: [[1424,1802],[1436,1802],[1436,1582],[1346,1582]], label: { s: 'al', x: 1452, y: 1692, t: '外部 failure', rot: -90, anchor: 'center' } },
  { from: 'inbox-infra-failure', to: 'inbox-failure', pts: [[470,1542],[116,1542],[116,1052],[484,1052]] },
  { from: 'reader-infra-failure', to: 'reader-failure', pts: [[1070,1542],[1436,1542],[1436,1052],[1356,1052]] }
];

const TEXTS = [
  { s: 'title', x: 160, y: 86, t: 'Rivet — Bounded Context 地圖' },
  { s: 'sub', x: 160, y: 118, t: '個人 GitHub PR 工作台：分流 → 選取 → 閱讀；每個 BC 自己隔離 GitHub 外部協定' },
  { s: 'tag', x: 160, y: 146, runs: [{ t: 'PR Inbox', fill: C.green }, { t: ' ║ ', fill: '#4A5462' }, { t: 'PR Reader', fill: C.green }, { t: ' → 各自的 ', fill: '#4A5462' }, { t: 'GitHub Infra', fill: C.orange }] },
  { s: 'legend', x: 1082, y: 86, t: '虛線 — 內部擁有的抽象' },
  { s: 'legend', x: 1082, y: 110, t: '實線 — app surface、技術面與外部系統' },
  { s: 'legend', x: 1143, y: 134, t: '顏色 — 所屬的 plane' },
  { s: 'plane', x: 470, y: 775, t: 'PR INBOX', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 1070, y: 775, t: 'PR READER', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 620, y: 985, t: '內部擁有的 PORT 與 FAILURE CONTRACT', anchor: 'center', fill: planeColor('port') },
  { s: 'bn', x: 160, y: 1976, t: '不變量：Core、UseCase、Port 不依賴 GitHub protocol 或 GitHubTransport；BC 之間沒有 compile-time dependency' },
  { s: 'bn', x: 160, y: 1996, t: '不變量：各 BC Infra 自己映射 GitHub DTO、HTTP status 與 technical failure；不會交給集中 Integration BC' },
  { s: 'bn', x: 160, y: 2016, t: 'GitHubTransport 是未實作的 non-BC technical boundary；RivetHTTPClient 維持 generic technical HTTP foundation' }
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: '#8B93A1', alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
];

const CHIPS = ['presentation', 'facade', 'usecase', 'port', 'infra', 'outside']
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
