const W = 1480, H = 1800;

// 此圖描述 repository 的知識責任，而非產品程式碼。虛線表示 Rivet
// 擁有並可演進的文件契約；實線表示閱讀者或 agent 這類使用表面。
const PLANES = {
  actors: { c: '#94A3B8', label: '閱讀者與協作代理' },
  governance: { c: '#7DD3FC', label: '入口與設計原則' },
  truth: { c: '#A78BFA', label: '長期架構真相' },
  topic: { c: '#4ADE80', label: '正式主題工件' },
  baseline: { c: '#FBBF24', label: '工具鏈與未來實作' }
};

const BANDS = [
  { id: 'band-actors', plane: 'actors', x: 160, y: 200, w: 1260, h: 150, alpha: 0.5,
    hdr: { x: 184, y: 230, t: '閱讀者與協作代理' },
    tagr: { x: 1396, y: 230, t: '從同一組真相開始', alpha: 0.6 } },
  { id: 'band-governance', plane: 'governance', x: 160, y: 430, w: 1260, h: 180, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 460, t: '入口與設計原則' },
    tagr: { x: 1396, y: 460, t: '先讀，再改變', alpha: 0.6 } },
  { id: 'band-truth', plane: 'truth', x: 160, y: 690, w: 1260, h: 270, alpha: 0.52, dash: true,
    hdr: { x: 184, y: 720, t: '文件 — 長期成立的設計真相' },
    tagr: { x: 1396, y: 720, t: '每個 BC 一份主文件', alpha: 0.6 } },
  { id: 'band-topic', plane: 'topic', x: 160, y: 1040, w: 1260, h: 300, alpha: 0.52, dash: true,
    hdr: { x: 184, y: 1070, t: '分析 + 計畫 — 正式主題契約' },
    tagr: { x: 1396, y: 1070, t: '同 slug · 有界變更', alpha: 0.6 } },
  { id: 'band-baseline', plane: 'baseline', x: 160, y: 1420, w: 1260, h: 230, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 1450, t: '工具鏈基線與未來實作區域' },
    tagr: { x: 1396, y: 1450, t: '一次一個 BC', alpha: 0.6 } }
];

const BOXES = [
  { id: 'reader', plane: 'actors', band: 'band-actors', x: 220, y: 258, w: 500, h: 68, r: 10,
    name: '公開讀者', about: '從 README、架構文件與圖理解 Rivet 的產品與邊界。',
    texts: [['bl', 244, 286, '公開讀者'], ['bs', 244, 308, '理解產品 · 架構 · 設計決策']] },
  { id: 'agent', plane: 'actors', band: 'band-actors', x: 860, y: 258, w: 500, h: 68, r: 10,
    name: '協作代理', about: '先讀入口與相關契約，再以有界主題提出或實作改變。',
    texts: [['bl', 884, 286, '協作代理'], ['bs', 884, 308, '先讀文件 · 再處理主題']] },

  { id: 'readme', plane: 'governance', band: 'band-governance', x: 200, y: 490, w: 340, h: 88, r: 10, dash: true,
    name: 'README.md', about: 'Repository 的首讀入口，說明 Rivet 的定位與文件導覽。',
    texts: [['bl', 224, 518, 'README.md'], ['bs', 224, 540, '首讀入口 · 文件導覽'], ['bn', 224, 562, '從此開始定位任務']] },
  { id: 'agents', plane: 'governance', band: 'band-governance', x: 570, y: 490, w: 340, h: 88, r: 10, dash: true,
    name: 'AGENTS.md', about: '將讀取順序、主題工件與圖形 skill 路由交給協作代理。',
    texts: [['bl', 594, 518, 'AGENTS.md'], ['bs', 594, 540, '讀取順序 · skill 路由'], ['bn', 594, 562, '不取代設計文件']] },
  { id: 'principles', plane: 'governance', band: 'band-governance', x: 940, y: 490, w: 340, h: 88, r: 10, dash: true,
    name: '設計原則', about: '保存產品取捨、架構取捨與正式主題的工作方法。',
    texts: [['bl', 964, 518, '設計原則'], ['bs', 964, 540, '產品取捨 · 工作方法'], ['bn', 964, 562, '避免過早實作']] },

  { id: 'product', plane: 'truth', band: 'band-truth', x: 200, y: 755, w: 270, h: 88, r: 10, dash: true,
    name: '產品規範', about: '定義個人 GitHub PR 工作台的目標、成功標準與範圍。',
    texts: [['bl', 224, 783, '產品規範'], ['bs', 224, 805, '目標 · 範圍 · 成功標準'], ['bn', 224, 827, '產品真相']] },
  { id: 'architecture', plane: 'truth', band: 'band-truth', x: 500, y: 755, w: 270, h: 88, r: 10, dash: true,
    name: '架構索引', about: '保存跨 BC 不變量，並連結 BC 文件與圖。',
    texts: [['bl', 524, 783, '架構索引'], ['bs', 524, 805, '不變量 · 文件索引'], ['bn', 524, 827, '跨 BC 真相']] },
  { id: 'bc-docs', plane: 'truth', band: 'band-truth', x: 800, y: 755, w: 270, h: 88, r: 10, dash: true,
    name: 'BC 文件', about: '每個 Bounded Context 的唯一主文件，記錄責任與失敗契約。',
    texts: [['bl', 824, 783, 'BC 文件'], ['bs', 824, 805, '責任 · Port · 失敗契約'], ['bn', 824, 827, '一個 BC 一份文件']] },
  { id: 'diagrams', plane: 'truth', band: 'band-truth', x: 1100, y: 755, w: 270, h: 88, r: 10, dash: true,
    name: '互動式圖', about: '以可互動圖呈現全景責任邊界與正式工作流程。',
    texts: [['bl', 1124, 783, '互動式圖'], ['bs', 1124, 805, '全景圖 · 工作流程'], ['bn', 1124, 827, '不是裝飾']] },
  { id: 'docs-writeback', plane: 'truth', band: 'band-truth', x: 440, y: 865, w: 600, h: 68, r: 10, dash: true,
    name: '文件回寫', about: '完成後仍成立的決策回寫文件，使公開真相不只留在主題計畫。',
    texts: [['bl', 464, 893, '文件回寫'], ['bs', 464, 915, '完成後仍成立的結論回寫文件與圖']] },

  { id: 'requirements', plane: 'topic', band: 'band-topic', x: 200, y: 1110, w: 270, h: 88, r: 10, dash: true,
    name: '需求釐清', about: '界定本次主題的目標、範圍、非目標與成功標準。',
    texts: [['bl', 224, 1138, '需求釐清'], ['bs', 224, 1160, '目標 · 範圍 · 非目標'], ['bn', 224, 1182, '研究入口']] },
  { id: 'technical-spec', plane: 'topic', band: 'band-topic', x: 500, y: 1110, w: 270, h: 88, r: 10, dash: true,
    name: '技術規格', about: '記錄選項比較、技術判斷與需要鎖定的設計決策。',
    texts: [['bl', 524, 1138, '技術規格'], ['bs', 524, 1160, '選項 · 取捨 · 證據'], ['bn', 524, 1182, '鎖定前研究']] },
  { id: 'topic-plan', plane: 'topic', band: 'band-topic', x: 800, y: 1110, w: 270, h: 88, r: 10, dash: true,
    name: '主題計畫', about: '將鎖定決策變成有 artifact path、步驟與驗收的執行契約。',
    texts: [['bl', 824, 1138, '主題計畫'], ['bs', 824, 1160, '步驟 · 驗收 · 邊界'], ['bn', 824, 1182, '可執行契約']] },
  { id: 'scope-return', plane: 'topic', band: 'band-topic', x: 1100, y: 1110, w: 270, h: 88, r: 10, dash: true,
    name: '範圍回退', about: '若實作需要改變鎖定範圍，回到分析與計畫，而不是即興擴張。',
    texts: [['bl', 1124, 1138, '範圍回退'], ['bs', 1124, 1160, '範圍改變 → 再分析'], ['bn', 1124, 1182, '拒絕即興擴張']] },
  { id: 'topic-validation', plane: 'topic', band: 'band-topic', x: 440, y: 1220, w: 600, h: 68, r: 10, dash: true,
    name: '主題驗證', about: '以驗收、圖形驗證與人類審查確認本次改變符合契約。',
    texts: [['bl', 464, 1248, '主題驗證'], ['bs', 464, 1270, '驗收 · 圖形驗證 · staged 審查 · 人類關卡']] },

  { id: 'toolchain', plane: 'baseline', band: 'band-baseline', x: 200, y: 1490, w: 520, h: 88, r: 10, dash: true,
    name: '工具鏈基線', about: '保存 Swift、Node、Bun、formatter、lint 與檢查 scripts 的版本基線。',
    texts: [['bl', 224, 1518, '工具鏈基線'], ['bs', 224, 1540, 'Swift · Node · Bun · scripts'], ['bn', 224, 1562, '可重現的品質基礎']] },
  { id: 'future-bc', plane: 'baseline', band: 'band-baseline', x: 860, y: 1490, w: 520, h: 88, r: 10, dash: true,
    name: '下一個 BC 切片', about: '僅在正式 topic 完成分析與計畫後，才建立受限的產品實作。',
    texts: [['bl', 884, 1518, '下一個 BC 切片'], ['bs', 884, 1540, '一次一個 · 有界實作'], ['bn', 884, 1562, '尚未建立程式碼']] }
];

const EDGES = [
  { from: 'reader', to: 'readme', pts: [[470,330],[470,484]], label: { s: 'al', x: 484, y: 412, t: '閱讀入口' } },
  { from: 'agent', to: 'agents', pts: [[1110,330],[1110,400],[740,400],[740,484]], label: { s: 'al', x: 925, y: 392, t: '依規範路由', anchor: 'center' } },
  { from: 'readme', to: 'architecture', pts: [[370,582],[370,660],[635,660],[635,749]], label: { s: 'al', x: 502, y: 652, t: '找到架構入口', anchor: 'center' } },
  { from: 'agents', to: 'principles', pts: [[740,582],[740,640],[1110,640],[1110,484]], label: { s: 'al', x: 925, y: 632, t: '先讀原則', anchor: 'center' } },
  { from: 'principles', to: 'architecture', pts: [[1110,582],[1110,680],[635,680],[635,749]], label: { s: 'al', x: 872, y: 672, t: '約束設計', anchor: 'center' } },
  { from: 'architecture', to: 'bc-docs', pts: [[774,799],[794,799]], label: { s: 'al', x: 784, y: 787, t: '索引', anchor: 'center' } },
  { from: 'architecture', to: 'diagrams', pts: [[635,847],[635,900],[1235,900],[1235,847]], label: { s: 'al', x: 935, y: 892, t: '連結互動式圖', anchor: 'center' } },
  { from: 'requirements', to: 'technical-spec', pts: [[474,1154],[494,1154]], label: { s: 'al', x: 484, y: 1142, t: '研究', anchor: 'center' } },
  { from: 'technical-spec', to: 'topic-plan', pts: [[774,1154],[794,1154]], label: { s: 'al', x: 784, y: 1142, t: '鎖定', anchor: 'center' } },
  { from: 'topic-plan', to: 'topic-validation', pts: [[935,1202],[935,1214]], label: { s: 'al', x: 949, y: 1208, t: '執行', anchor: 'center' } },
  { from: 'topic-validation', to: 'scope-return', pts: [[1044,1254],[1070,1254],[1070,1154],[1094,1154]], label: { s: 'al', x: 1084, y: 1204, t: '範圍改變', rot: -90, anchor: 'center' } },
  { from: 'topic-validation', to: 'docs-writeback', pts: [[740,1216],[740,939]], label: { s: 'al', x: 754, y: 1080, t: '回寫長期真相', rot: -90, anchor: 'center' } },
  { from: 'scope-return', to: 'requirements', pts: [[1096,1154],[116,1154],[116,1110],[194,1110]], label: { s: 'al', x: 100, y: 1132, t: '範圍改變', anchor: 'center' } },
  { from: 'docs-writeback', to: 'toolchain', pts: [[440,899],[116,899],[116,1534],[194,1534]], label: { s: 'al', x: 100, y: 1216, t: '依基線驗證', rot: -90, anchor: 'center' } },
  { from: 'toolchain', to: 'future-bc', pts: [[724,1534],[854,1534]], label: { s: 'al', x: 789, y: 1522, t: '支援下一個切片', anchor: 'center' } },
  { from: 'future-bc', to: 'requirements', pts: [[1234,1534],[1436,1534],[1436,1110],[1376,1110]], label: { s: 'al', x: 1452, y: 1322, t: '新的正式 topic', rot: -90, anchor: 'center' } }
];

const TEXTS = [
  { s: 'title', x: 160, y: 86, t: 'Rivet — 儲存庫知識地圖' },
  { s: 'sub', x: 160, y: 118, t: '從研究到計畫、回寫文件，再開始一個有界的 Bounded Context 切片' },
  { s: 'tag', x: 160, y: 146, runs: [
    { t: '分析', fill: C.green }, { t: ' → ', fill: '#4A5462' },
    { t: '計畫', fill: C.green }, { t: ' → ', fill: '#4A5462' },
    { t: '文件', fill: C.violet }, { t: ' → ', fill: '#4A5462' },
    { t: '一個 BC 切片', fill: C.amber }
  ] },
  { s: 'legend', x: 1082, y: 86, t: '虛線 — Rivet 擁有的知識契約' },
  { s: 'legend', x: 1082, y: 110, t: '實線 — 人與協作代理的閱讀表面' },
  { s: 'legend', x: 1143, y: 134, t: '顏色 — 所屬責任平面' },
  { s: 'bn', x: 160, y: 1710, t: '不變量：分析不取代文件；計畫不取代 BC 文件；完成後仍成立的結論必須回寫。' },
  { s: 'bn', x: 160, y: 1730, t: '本圖描述知識與治理結構，不表示 app、context 或產品程式碼已存在。' },
  { s: 'bn', x: 160, y: 1750, t: '每個正式主題都以同一 slug 對應分析與計畫，並由 AGENTS.md 導引協作代理。' }
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: '#8B93A1', alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
];

const CHIPS = ['actors', 'governance', 'truth', 'topic', 'baseline']
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
