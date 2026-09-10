const W = 1480, H = 2240;

// 虛線表示 Rivet 擁有的抽象；實線表示應用介面、技術機制與外部系統。
const PLANES = {
  presentation: { c: '#7DD3FC', label: '呈現層' },
  facade: { c: '#A78BFA', label: 'Facade 層' },
  usecase: { c: '#4ADE80', label: 'BC 使用案例層' },
  port: { c: '#FBBF24', label: '內部 Port 與契約' },
  adapter: { c: '#F6821F', label: '各 BC 的 GitHub 轉接器' },
  integration: { c: '#22D3EE', label: '共享 GitHub 技術整合' },
  outside: { c: '#94A3B8', label: '外部世界' }
};

const BANDS = [
  { id: 'band-presentation', plane: 'presentation', x: 160, y: 200, w: 1260, h: 184, alpha: 0.5,
    hdr: { x: 184, y: 230, t: '使用者與呈現層' }, tagr: { x: 1396, y: 230, t: '應用介面 · 工作階段非 BC', alpha: 0.6 } },
  { id: 'band-facade', plane: 'facade', x: 160, y: 470, w: 1260, h: 150, alpha: 0.55, dash: true,
    hdr: { x: 184, y: 500, t: 'Facade — 穩定的呈現層入口' }, tagr: { x: 1396, y: 500, t: '內部擁有 · UI 從此進入', alpha: 0.6 } },
  { id: 'band-application', plane: null, x: 160, y: 710, w: 1260, h: 460, stroke: '#3A4250', alpha: 1,
    hdr: { x: 184, y: 740, t: '限界上下文的應用層' }, tagr: { x: 1396, y: 740, t: 'PR Inbox ║ PR Reader — 不直接相依', alpha: 0.7 } },
  { id: 'band-adapter', plane: 'adapter', x: 160, y: 1260, w: 1260, h: 250, alpha: 0.48,
    hdr: { x: 184, y: 1290, t: '各 BC 的 GitHub 轉接器 — BC 內部的外部轉換邊界' }, tagr: { x: 1396, y: 1290, t: '轉接器可依賴共享模組', alpha: 0.6 } },
  { id: 'band-integration', plane: 'integration', x: 160, y: 1600, w: 1260, h: 200, alpha: 0.5,
    hdr: { x: 184, y: 1630, t: 'GitHub 專用共享整合模組' }, tagr: { x: 1396, y: 1630, t: '非 BC · 尚未實作 · 對 BC 無知', alpha: 0.6 } },
  { id: 'band-outside', plane: 'outside', x: 160, y: 1890, w: 1260, h: 166, alpha: 0.48,
    hdr: { x: 184, y: 1920, t: '外部世界 — GitHub.com' }, tagr: { x: 1396, y: 1920, t: '外部系統', alpha: 0.6 } }
];

const BOXES = [
  { id: 'reviewer', plane: 'presentation', band: 'band-presentation', x: 200, y: 260, w: 220, h: 88, r: 10,
    name: '審閱者', about: '使用 Rivet 挑選與閱讀 Pull Request 的單一使用者。', texts: [['bl', 224, 288, '審閱者'], ['bs', 224, 310, '個人的 PR 工作流'], ['bn', 224, 332, '啟動分流迴圈']] },
  { id: 'inbox-view', plane: 'presentation', band: 'band-presentation', x: 450, y: 260, w: 280, h: 88, r: 10,
    name: 'PR Inbox 檢視', about: '顯示目前待審閱佇列的原生介面。', texts: [['bl', 474, 288, 'PR Inbox 檢視'], ['bs', 474, 310, '待審閱佇列 · 排序'], ['bn', 474, 332, '不定義佇列規則']] },
  { id: 'session', plane: 'presentation', band: 'band-presentation', x: 760, y: 260, w: 300, h: 88, r: 10,
    name: '呈現工作階段', about: '保存已選 PR 與導覽脈絡的 UI 工作階段狀態。', texts: [['bl', 784, 288, '呈現工作階段'], ['bs', 784, 310, '選取 PR · 切換'], ['bn', 784, 332, '僅是狀態 · 非 BC']] },
  { id: 'reader-view', plane: 'presentation', band: 'band-presentation', x: 1090, y: 260, w: 280, h: 88, r: 10,
    name: 'PR Reader 檢視', about: '閱讀單一 Pull Request 與其變更的介面。', texts: [['bl', 1114, 288, 'PR Reader 檢視'], ['bs', 1114, 310, '背景 · 檢查 · 差異'], ['bn', 1114, 332, '唯讀呈現']] },
  { id: 'inbox-facade', plane: 'facade', band: 'band-facade', x: 220, y: 530, w: 540, h: 68, r: 10, dash: true,
    name: 'Inbox Facade', about: '取得待審閱佇列的穩定呈現層入口。', texts: [['bl', 244, 558, 'Inbox Facade'], ['bs', 244, 580, '目前待審閱佇列的穩定入口']] },
  { id: 'reader-facade', plane: 'facade', band: 'band-facade', x: 820, y: 530, w: 540, h: 68, r: 10, dash: true,
    name: 'Reader Facade', about: '載入單一 PR 閱讀快照的穩定呈現層入口。', texts: [['bl', 844, 558, 'Reader Facade'], ['bs', 844, 580, '單一閱讀快照的穩定入口']] },
  { id: 'inbox-usecase', plane: 'usecase', band: 'band-application', x: 200, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: 'PR Inbox UseCase', about: '協調待審閱佇列的更新與排序語意。', texts: [['bl', 224, 823, 'PR Inbox UseCase'], ['bs', 224, 845, '更新佇列 · 套用排序'], ['bn', 224, 867, '空佇列是成功結果']] },
  { id: 'reader-usecase', plane: 'usecase', band: 'band-application', x: 800, y: 795, w: 540, h: 88, r: 10, dash: true,
    name: 'PR Reader UseCase', about: '協調單一 PR 的閱讀快照。', texts: [['bl', 824, 823, 'PR Reader UseCase'], ['bs', 824, 845, '載入背景 · 討論 · 差異'], ['bn', 824, 867, '不決定 Inbox 成員']] },
  { id: 'inbox-port', plane: 'port', band: 'band-application', x: 190, y: 1000, w: 280, h: 104, r: 10, dash: true,
    name: 'Inbox Port', about: '由 PR Inbox 擁有的資料需求。', texts: [['bl', 214, 1028, '審閱請求來源'], ['bs', 214, 1050, 'Inbox 擁有的資料需求'], ['bn', 214, 1074, '不是 GitHub 查詢']] },
  { id: 'inbox-failure', plane: 'port', band: 'band-application', x: 490, y: 1000, w: 250, h: 104, r: 10, dash: true,
    name: 'Inbox 失敗契約', about: 'PR Inbox 對呼叫端公開的語意失敗。', texts: [['bl', 514, 1028, 'Inbox 失敗契約'], ['bs', 514, 1050, '無法更新佇列'], ['bn', 514, 1074, '不洩漏 HTTP 狀態']] },
  { id: 'reader-port', plane: 'port', band: 'band-application', x: 800, y: 1000, w: 280, h: 104, r: 10, dash: true,
    name: 'Reader Port', about: '由 PR Reader 擁有的資料需求。', texts: [['bl', 824, 1028, 'PR 內容來源 Port'], ['bs', 824, 1050, 'Reader 擁有的資料需求'], ['bn', 824, 1074, '不是 GitHub DTO']] },
  { id: 'reader-failure', plane: 'port', band: 'band-application', x: 1100, y: 1000, w: 250, h: 104, r: 10, dash: true,
    name: 'Reader 失敗契約', about: 'PR Reader 對呼叫端公開的語意失敗。', texts: [['bl', 1124, 1028, 'Reader 失敗契約'], ['bs', 1124, 1050, 'PR 內容不可讀'], ['bn', 1124, 1074, '不洩漏 GitHub 錯誤']] },
  { id: 'inbox-adapter', plane: 'adapter', band: 'band-adapter', x: 200, y: 1320, w: 540, h: 120, r: 10,
    name: 'PR Inbox GitHub 轉接器', about: '僅為 Inbox Port 將 GitHub 外部資料與技術分類轉換成 Inbox 詞彙。', texts: [['bl', 224, 1348, 'PR Inbox GitHub 轉接器'], ['bs', 224, 1370, '端點媒體型別 · DTO 轉換'], ['bs', 224, 1386, 'GitHub 技術分類 → Inbox 失敗契約'], ['bn', 224, 1408, 'Inbox 業務意義只留在此處']] },
  { id: 'reader-adapter', plane: 'adapter', band: 'band-adapter', x: 800, y: 1320, w: 540, h: 120, r: 10,
    name: 'PR Reader GitHub 轉接器', about: '僅為 Reader Port 將 GitHub node 與技術分類轉換成 Reader 詞彙。', texts: [['bl', 824, 1348, 'PR Reader GitHub 轉接器'], ['bs', 824, 1370, '端點媒體型別 · node 轉換'], ['bs', 824, 1386, 'GitHub 技術分類 → Reader 失敗契約'], ['bn', 824, 1408, 'Reader 業務意義只留在此處']] },
  { id: 'github-integration', plane: 'integration', band: 'band-integration', x: 260, y: 1670, w: 1060, h: 104, r: 10,
    name: 'GithubIntegration', about: '尚未實作的 GitHub 專用共享整合模組，只集中可跨 BC 共用的 raw 技術機制。', texts: [['bl', 284, 1698, 'GithubIntegration（未來邊界）'], ['bs', 284, 1720, 'raw 傳輸 · 認證 · 共通標頭／API version'], ['bs', 284, 1736, '分頁 · 速率限制 · 重試 · GitHub 技術分類'], ['bn', 284, 1758, '不定義 BC 詞彙、失敗契約或 GithubService']] },
  { id: 'github-rest', plane: 'outside', band: 'band-outside', x: 190, y: 1950, w: 580, h: 68, r: 10,
    name: 'GitHub REST API', about: '各 BC 轉接器經由共享技術機制可使用的外部 REST 協定。', texts: [['bl', 214, 1978, 'GitHub REST API'], ['bs', 214, 2000, '外部端點 · 回應']] },
  { id: 'github-graphql', plane: 'outside', band: 'band-outside', x: 810, y: 1950, w: 580, h: 68, r: 10,
    name: 'GitHub GraphQL API', about: '各 BC 轉接器經由共享技術機制可使用的外部 GraphQL 協定。', texts: [['bl', 834, 1978, 'GitHub GraphQL API'], ['bs', 834, 2000, '外部結構描述 · 操作']] }
];

const EDGES = [
  // 本圖只表達編譯期依賴；不表達 Reviewer、View 或 Session 的 runtime navigation／request flow。
  { from: 'inbox-view', to: 'inbox-facade', pts: [[590,352],[590,414],[490,414],[490,524]] },
  { from: 'reader-view', to: 'reader-facade', pts: [[1230,352],[1230,414],[1090,414],[1090,524]] },
  { from: 'inbox-facade', to: 'inbox-usecase', pts: [[490,602],[490,789]] },
  { from: 'reader-facade', to: 'reader-usecase', pts: [[1090,602],[1090,789]] },
  { from: 'inbox-usecase', to: 'inbox-port', pts: [[470,887],[470,940],[330,940],[330,994]] },
  { from: 'reader-usecase', to: 'reader-port', pts: [[1070,887],[1070,940],[940,940],[940,994]] },
  { from: 'inbox-adapter', to: 'inbox-port', pts: [[330,1314],[330,1110]], label: { s: 'al', x: 344, y: 1216, t: '實作 Inbox Port', rot: -90, anchor: 'center' } },
  { from: 'reader-adapter', to: 'reader-port', pts: [[940,1314],[940,1110]], label: { s: 'al', x: 954, y: 1216, t: '實作 Reader Port', rot: -90, anchor: 'center' } },
  { from: 'inbox-adapter', to: 'github-integration', pts: [[470,1444],[470,1550],[700,1550],[700,1664]], label: { s: 'al', x: 714, y: 1600, t: '共享技術機制', rot: -90, anchor: 'center' } },
  { from: 'reader-adapter', to: 'github-integration', pts: [[1070,1444],[1070,1550],[880,1550],[880,1664]] },
  { from: 'github-integration', to: 'github-rest', pts: [[600,1778],[600,1860],[480,1860],[480,1944]], label: { s: 'al', x: 494, y: 1876, t: 'REST', anchor: 'center' } },
  { from: 'github-integration', to: 'github-graphql', pts: [[980,1778],[980,1860],[1100,1860],[1100,1944]], label: { s: 'al', x: 1114, y: 1876, t: 'GraphQL', anchor: 'center' } }
];

const TEXTS = [
  { s: 'title', x: 160, y: 86, t: 'Rivet — 限界上下文地圖' },
  { s: 'sub', x: 160, y: 118, t: '個人 GitHub PR 工作台：BC 轉接器 → 共享技術機制 → GitHub API' },
  { s: 'tag', x: 160, y: 146, runs: [{ t: 'PR Inbox', fill: C.green }, { t: ' ║ ', fill: '#4A5462' }, { t: 'PR Reader', fill: C.green }, { t: ' → 各自的轉接器 → ', fill: '#4A5462' }, { t: 'GithubIntegration', fill: planeColor('integration') }] },
  { s: 'legend', x: 1082, y: 86, t: '虛線 — 內部擁有的抽象' },
  { s: 'legend', x: 1082, y: 110, t: '實線 — 應用介面、技術機制與外部系統' },
  { s: 'legend', x: 1143, y: 134, t: '顏色 — 所屬層級' },
  { s: 'plane', x: 470, y: 775, t: 'PR Inbox', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 1070, y: 775, t: 'PR Reader', anchor: 'center', fill: planeColor('usecase') },
  { s: 'plane', x: 620, y: 985, t: '內部擁有的 Port 與失敗契約', anchor: 'center', fill: planeColor('port') },
  { s: 'bn', x: 160, y: 2144, t: '不變量：BC Domain、UseCase、Port 不依賴 GithubIntegration；BC 之間沒有編譯期相依' },
  { s: 'bn', x: 160, y: 2164, t: '不變量：各 BC 轉接器擁有端點媒體型別、DTO／node 轉換、失敗映射與業務意義' },
  { s: 'bn', x: 160, y: 2184, t: 'GithubIntegration 對所有 BC 無知、尚未實作；RivetHTTPClient 維持通用且不知 GitHub 的基礎' },
  { s: 'bn', x: 160, y: 2204, t: '本圖只表達編譯期依賴；不表達 Reviewer、View 或 Session 的 runtime navigation／request flow' }
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: '#8B93A1', alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
];

const CHIPS = ['presentation', 'facade', 'usecase', 'port', 'adapter', 'integration', 'outside']
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
