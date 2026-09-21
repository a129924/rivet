const W = 1480, H = 1748;

// 這張圖只陳述責任與依賴；虛線表示 Rivet 擁有的責任契約，實線表示應用表面、技術基礎或外部系統。
const PLANES = {
  composition: { c: '#94A3B8', label: '組裝責任平面' },
  clients: { c: '#7DD3FC', label: '用戶端基礎設施責任平面' },
  integration: { c: '#A78BFA', label: '共享整合責任平面' },
  foundation: { c: '#F6821F', label: '通用 HTTP 基礎' },
  outside: { c: '#4ADE80', label: '外部系統平面' }
};

const BANDS = [
  { id: 'band-composition', plane: 'composition', x: 160, y: 200, w: 1260, h: 152, alpha: 0.55,
    hdr: { x: 184, y: 230, t: '組裝根節點' }, tagr: { x: 1396, y: 230, t: '建立唯一共享提供者', alpha: 0.6 } },
  { id: 'band-clients', plane: 'clients', x: 160, y: 440, w: 1260, h: 182, alpha: 0.45, dash: true,
    hdr: { x: 184, y: 470, t: 'GitHub 用戶端基礎設施' }, tagr: { x: 1396, y: 470, t: 'Rivet 擁有 — 各自保留原工作', alpha: 0.6 } },
  { id: 'band-integration', plane: 'integration', x: 160, y: 710, w: 1260, h: 310, alpha: 0.52, dash: true,
    hdr: { x: 184, y: 740, t: 'GithubIntegration — 共享機制，非限界上下文' }, tagr: { x: 1396, y: 740, t: 'Rivet 擁有的責任契約', alpha: 0.6 } },
  { id: 'band-foundation', plane: 'foundation', x: 160, y: 1110, w: 1260, h: 190, alpha: 0.45,
    hdr: { x: 184, y: 1140, t: '通用 HTTP 基礎' }, tagr: { x: 1396, y: 1140, t: '不認識 GitHub', alpha: 0.6 } },
  { id: 'band-outside', plane: 'outside', x: 160, y: 1390, w: 1260, h: 180, alpha: 0.42,
    hdr: { x: 184, y: 1420, t: '外部系統 — Keychain 與 GitHub' }, tagr: { x: 1396, y: 1420, t: '可替換的外部系統', alpha: 0.6 } }
];

const BOXES = [
  { id: 'facade', plane: 'composition', band: 'band-composition', x: 210, y: 260, w: 1160, h: 70, r: 10,
    name: '外觀層 — 層級外的應用程式組裝根節點', about: '後續由應用程式組裝根節點建立已交付的 OAuthTokenProvider，並注入尚未交付的兩個 GitHub 用戶端。',
    texts: [['bl', 454, 288, '外觀層 — 層級外的應用程式組裝根節點'], ['bs', 454, 310, '後續組裝 HTTP／轉接器與已交付提供者；用戶端注入仍延後']] },

  { id: 'rest-client', plane: 'clients', band: 'band-clients', x: 230, y: 500, w: 500, h: 88, r: 10, dash: true,
    name: 'GitHub REST 用戶端', about: '由外觀層注入純 HTTP 傳送器／請求執行器與權杖提供者，保有自己的原 HTTPRequest 並只重送該請求。',
    texts: [['bl', 254, 528, 'GitHub REST 用戶端'], ['bs', 254, 550, '純 HTTP 執行器 + 權杖提供者'], ['bn', 254, 572, '保有 HTTPRequest；401 後只重送一次']] },
  { id: 'graphql-client', plane: 'clients', band: 'band-clients', x: 800, y: 500, w: 390, h: 88, r: 10, dash: true,
    name: 'GitHub GraphQL 用戶端', about: '以 Apollo 只重送自己的操作；不呼叫 REST 用戶端。',
    texts: [['bl', 824, 528, 'GitHub GraphQL 用戶端'], ['bs', 824, 550, '權杖提供者 + Apollo'], ['bn', 824, 572, '不經 REST 路徑；保有原操作']] },

  { id: 'github-integration', plane: 'integration', band: 'band-integration', x: 230, y: 780, w: 390, h: 92, r: 10, dash: true,
    name: 'GithubIntegration', about: '所有限界上下文之外、已交付既定契約的 GitHub 專屬共享整合模組。',
    texts: [['bl', 254, 808, 'GithubIntegration'], ['bs', 254, 830, '限界上下文外的 GitHub 專屬共享整合模組'], ['bn', 254, 852, '不是限界上下文；不擁有介面、DTO 或失敗對應']] },
  { id: 'provider', plane: 'integration', band: 'band-integration', x: 670, y: 780, w: 510, h: 126, r: 10, dash: true,
    name: 'OAuthTokenProvider', about: '已交付的唯一生命週期擁有者，封裝 OAuth 憑證狀態、版本、輪替持久化與單飛；不處理用戶端重試。',
    texts: [['bl', 694, 808, 'OAuthTokenProvider — 已交付'], ['bs', 694, 830, '記憶體快照 · 還原 · 到期判定 · 更新'], ['bs', 694, 846, '輪替持久化 · 版本 · 相同版本單飛'], ['bs', 694, 862, '不符合 GitHubAccessTokenProvider'], ['bn', 694, 884, '不持有 HTTPRequest／Apollo；不處理重試']] },
  { id: 'snapshot', plane: 'integration', band: 'band-integration', x: 230, y: 910, w: 390, h: 74, r: 10, dash: true,
    name: 'TokenSnapshot', about: '已交付的不可變、Equatable、Sendable 用戶端輸入，只暴露存取權杖與版本。',
    texts: [['bl', 254, 938, 'TokenSnapshot — 已交付'], ['bs', 254, 960, '存取權杖 + 版本；不暴露更新權杖']] },
  { id: 'token-store', plane: 'integration', band: 'band-integration', x: 670, y: 920, w: 240, h: 64, r: 10, dash: true,
    name: 'OAuthCredentialStore', about: '已交付的供轉接器使用介面，可讀寫完整 OAuth 憑證組合；Keychain 轉接器尚未交付。',
    texts: [['bl', 694, 948, 'OAuthCredentialStore — 已交付'], ['bs', 694, 970, '完整憑證組合；轉接器延後']] },
  { id: 'fetcher', plane: 'integration', band: 'band-integration', x: 950, y: 920, w: 230, h: 64, r: 10, dash: true,
    name: 'OAuthTokenFetcher', about: '已交付的供轉接器使用介面，更新後回傳完整 OAuth 憑證組合；純 HTTP 轉接器尚未交付。',
    texts: [['bl', 974, 948, 'OAuthTokenFetcher — 已交付'], ['bs', 974, 970, '完整憑證組合；HTTP 轉接器延後']] },

  { id: 'http-client', plane: 'foundation', band: 'band-foundation', x: 230, y: 1170, w: 330, h: 88, r: 10,
    name: 'RivetHTTPClient', about: '通用、純粹、不認識 GitHub 的 HTTP 基礎；不帶 OAuth 生命週期策略。',
    texts: [['bl', 254, 1198, 'RivetHTTPClient'], ['bs', 254, 1220, '通用 · 純粹 · 不認識 GitHub'], ['bn', 254, 1242, '不認識 OAuth、401 復原或重試']] },
  { id: 'transport', plane: 'foundation', band: 'band-foundation', x: 630, y: 1170, w: 260, h: 88, r: 10,
    name: 'URLSessionTransport', about: '供通用 HTTP 基礎使用的純 URLSession 傳輸。',
    texts: [['bl', 654, 1198, 'URLSessionTransport'], ['bs', 654, 1220, '純 URLSession 傳輸'], ['bn', 654, 1242, '沒有 GitHub 認證策略']] },
  { id: 'auth-flow', plane: 'foundation', band: 'band-foundation', x: 960, y: 1170, w: 250, h: 88, r: 10,
    name: 'AuthRequester', about: '既有內部執行元件注入 Requester 與呼叫端提供的 Auth，並驅動通用 AuthFlow；它不承擔 GitHub OAuth 生命週期。',
    texts: [['bl', 984, 1198, 'AuthRequester'], ['bs', 984, 1220, '注入 Requester + 呼叫端 Auth'], ['bn', 984, 1242, '驅動通用 AuthFlow；非 GitHub OAuth']] },

  { id: 'keychain', plane: 'outside', band: 'band-outside', x: 230, y: 1450, w: 270, h: 82, r: 10,
    name: 'Keychain', about: 'OAuth 憑證儲存轉接器後續使用的外部安全儲存；本主題未交付轉接器。',
    texts: [['bl', 254, 1478, 'Keychain'], ['bs', 254, 1500, 'OAuth 轉接器延後'], ['bn', 254, 1522, '外部系統']] },
  { id: 'oauth-endpoint', plane: 'outside', band: 'band-outside', x: 570, y: 1450, w: 270, h: 82, r: 10,
    name: 'GitHub OAuth 端點', about: '後續由純 HTTP 取得器轉接器呼叫的權杖端點，回傳完整輪替後的 OAuth 憑證組合。',
    texts: [['bl', 594, 1478, 'GitHub OAuth 端點'], ['bs', 594, 1500, 'HTTP 轉接器延後'], ['bn', 594, 1522, '外部系統']] },
  { id: 'github-rest-api', plane: 'outside', band: 'band-outside', x: 910, y: 1450, w: 220, h: 82, r: 10,
    name: 'GitHub REST API', about: '只由 REST 用戶端使用的 REST 路徑，可能回傳 401。',
    texts: [['bl', 934, 1478, 'GitHub REST API'], ['bs', 934, 1500, 'REST 路徑'], ['bn', 934, 1522, '外部系統']] },
  { id: 'github-graphql-api', plane: 'outside', band: 'band-outside', x: 1170, y: 1450, w: 210, h: 82, r: 10,
    name: 'GitHub GraphQL API', about: '只由 Apollo 使用的 GraphQL 路徑，可能回傳 401。',
    texts: [['bl', 1194, 1478, 'GitHub GraphQL API'], ['bs', 1194, 1500, 'Apollo 路徑'], ['bn', 1194, 1522, '外部系統']] }
];

const EDGES = [
  { from: 'facade', to: 'rest-client', pts: [[650,334], [480,334], [480,494]], label: { s: 'al', x: 494, y: 410, t: '注入共享提供者' } },
  { from: 'facade', to: 'graphql-client', pts: [[930,334], [995,334], [995,494]], label: { s: 'al', x: 1009, y: 410, t: '注入共享提供者' } },
  { from: 'rest-client', to: 'provider', pts: [[620,592], [620,750], [820,750], [820,774]], label: { s: 'al', x: 634, y: 742, t: '依賴快照復原' } },
  { from: 'rest-client', to: 'http-client', pts: [[224,544], [200,544], [200,1214], [224,1214]], label: { s: 'al', x: 186, y: 900, t: '使用純 HTTP 執行器', rot: -90, anchor: 'center' } },
  { from: 'graphql-client', to: 'provider', pts: [[995,592], [995,774]], label: { s: 'al', x: 1009, y: 690, t: '依賴快照復原' } },
  { from: 'github-integration', to: 'provider', pts: [[624,826], [664,826]], label: { s: 'al', x: 644, y: 814, t: '共享機制', anchor: 'center' } },
  { from: 'provider', to: 'snapshot', pts: [[668,836], [630,836], [630,947], [624,947]], label: { s: 'al', x: 644, y: 900, t: '回傳不可變輸入', rot: -90, anchor: 'center' } },
  { from: 'provider', to: 'token-store', pts: [[790,894], [790,914]], label: { s: 'al', x: 804, y: 908, t: '讀寫憑證組合' } },
  { from: 'provider', to: 'fetcher', pts: [[1050,894], [1050,914]], label: { s: 'al', x: 1064, y: 908, t: '更新' } },
  { from: 'token-store', to: 'keychain', pts: [[790,988], [790,1350], [365,1350], [365,1444]], label: { s: 'al', x: 804, y: 1328, t: '安全保存' } },
  { from: 'fetcher', to: 'http-client', pts: [[948,952], [920,952], [920,1080], [395,1080], [395,1164]], label: { s: 'al', x: 934, y: 1048, t: '使用純 HTTP', rot: -90, anchor: 'center' } },
  { from: 'http-client', to: 'transport', pts: [[564,1214], [624,1214]], label: { s: 'al', x: 594, y: 1202, t: '執行', anchor: 'center' } },
  { from: 'auth-flow', to: 'http-client', pts: [[956,1214], [900,1214], [900,1080], [560,1080], [560,1200]], label: { s: 'al', x: 886, y: 1100, t: '注入 Requester' } },
  { from: 'fetcher', to: 'oauth-endpoint', pts: [[1060,988], [1060,1360], [705,1360], [705,1444]], label: { s: 'al', x: 1074, y: 1270, t: '權杖端點', rot: -90, anchor: 'center' } },
  { from: 'rest-client', to: 'github-rest-api', pts: [[420,592], [420,1340], [1020,1340], [1020,1444]], label: { s: 'al', x: 434, y: 1040, t: 'REST 路徑', rot: -90, anchor: 'center' } },
  { from: 'graphql-client', to: 'github-graphql-api', pts: [[1188,544], [1350,544], [1350,1444]], label: { s: 'al', x: 1364, y: 1000, t: 'Apollo GraphQL 路徑', rot: -90, anchor: 'center' } }
];

const TEXTS = [
  { s: 'title', x: 160, y: 86, t: 'GitHub OAuth — 雙用戶端架構' },
  { s: 'sub', x: 160, y: 118, t: '同一個提供者擁有權杖生命週期；兩個用戶端各自保有並重送自己的原工作' },
  { s: 'tag', x: 160, y: 146, runs: [
    { t: '組裝', fill: C.slate }, { t: ' → ', fill: '#4A5462' }, { t: '共享權杖生命週期', fill: planeColor('integration') }, { t: ' → ', fill: '#4A5462' }, { t: '原工作所有權留在用戶端', fill: C.sky } ] },
  { s: 'legend', x: 1082, y: 86, t: '虛線 — Rivet 擁有的責任契約' },
  { s: 'legend', x: 1082, y: 110, t: '實線 — 應用表面、基礎或外部系統' },
  { s: 'legend', x: 1143, y: 134, t: '顏色 — 所屬責任平面' },
  { s: 'bn', x: 160, y: 1644, t: '不變量：OAuthTokenProvider 不持有請求／操作；REST 與 Apollo GraphQL 用戶端不互相呼叫。' },
  { s: 'bn', x: 160, y: 1664, t: '不變量：HTTPClient 不驅動流程；內部 AuthRequester 僅驅動通用 AuthFlow，不承擔 GitHub OAuth 生命週期。' },
  { s: 'bn', x: 160, y: 1684, t: '不變量：403、儲存庫權限與資源可見性不是權杖更新訊號。' },
  { s: 'bn', x: 160, y: 1704, t: '已交付 OAuth 提供者／介面；OAuth 轉接器、用戶端 401 復原／重試與 HTTP 傳送器均延後。' }
];

const SWATCHES = [
  { x: 1046, y: 75, w: 26, h: 13, stroke: '#8B93A1', alpha: 0.8, dash: true },
  { x: 1046, y: 99, w: 26, h: 13, stroke: C.boxStroke, alpha: 1, fill: C.boxFill }
];

const CHIPS = ['composition', 'clients', 'integration', 'foundation', 'outside']
  .map((id, i) => ({ x: 1046 + i * 13, y: 123, w: 9, h: 13, fill: planeColor(id) }));
