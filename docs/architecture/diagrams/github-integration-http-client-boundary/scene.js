const W = 1480, H = 1710;

// 此圖只記錄已核准的責任與預定編譯期邊界；虛線不是既有 Swift 實作。
const PLANES = {
  core:        { c: '#7DD3FC', label: '核心 Bounded Context' },
  integration: { c: '#F6821F', label: 'GitHub Integration' },
  package:     { c: '#A78BFA', label: '內部 package baseline' },
  outside:     { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id: 'band-core', plane: 'core', x: 160, y: 200, w: 1260, h: 246, alpha: 0.52, dash: true,
    hdr: { x: 184, y: 230, t: '核心 BC — PR INBOX 與 PR READER' },
    tagr: { x: 1396, y: 230, t: '擁有 PORT 與 FAILURE CONTRACT', alpha: 0.6 } },
  { id: 'band-integration', plane: 'integration', x: 160, y: 530, w: 1260, h: 276, alpha: 0.48,
    hdr: { x: 184, y: 560, t: 'GITHUB INTEGRATION — SUPPORTING BC' },
    tagr: { x: 1396, y: 560, t: 'ANTI-CORRUPTION BOUNDARY', alpha: 0.6 } },
  { id: 'band-package', plane: 'package', x: 160, y: 890, w: 1260, h: 356, alpha: 0.5, dash: true,
    hdr: { x: 184, y: 920, t: 'RIVETHTTPCLIENT — DECLARATION-ONLY BASELINE' },
    tagr: { x: 1396, y: 920, t: '尚無 PRODUCT、TARGET 或 SWIFT SOURCE', alpha: 0.6 } },
  { id: 'band-outside', plane: 'outside', x: 160, y: 1330, w: 1260, h: 150, alpha: 0.48,
    hdr: { x: 184, y: 1360, t: 'OUTSIDE — FOUNDATION 與 GITHUB.COM' },
    tagr: { x: 1396, y: 1360, t: '可替換／外部世界', alpha: 0.6 } }
];

const BOXES = [
  { id: 'review-port', plane: 'core', band: 'band-core', x: 200, y: 270, w: 270, h: 88, r: 10, dash: true,
    name: 'Review Request Source Port', about: 'PR Inbox 擁有的資料需求，不認識 GitHub 或 HTTP。',
    texts: [['bl',224,298,'Review Request Source'],['bs',224,320,'PR Inbox 擁有的 Port'],['bn',224,342,'不依賴 GitHub 或 HTTP']] },
  { id: 'content-port', plane: 'core', band: 'band-core', x: 500, y: 270, w: 270, h: 88, r: 10, dash: true,
    name: 'PR Content Source Port', about: 'PR Reader 擁有的內容資料需求，不認識外部 DTO。',
    texts: [['bl',524,298,'PR Content Source'],['bs',524,320,'PR Reader 擁有的 Port'],['bn',524,342,'不接觸外部 DTO']] },
  { id: 'inbox-failure', plane: 'core', band: 'band-core', x: 800, y: 270, w: 270, h: 88, r: 10, dash: true,
    name: 'Inbox Failure Contract', about: 'PR Inbox 對外表達的語意失敗，不含 infrastructure 細節。',
    texts: [['bl',824,298,'Inbox Failure Contract'],['bs',824,320,'待審閱佇列不可取得'],['bn',824,342,'不含 HTTP status']] },
  { id: 'reader-failure', plane: 'core', band: 'band-core', x: 1100, y: 270, w: 270, h: 88, r: 10, dash: true,
    name: 'Reader Failure Contract', about: 'PR Reader 對外表達的閱讀語意失敗，不含 GitHub failure。',
    texts: [['bl',1124,298,'Reader Failure Contract'],['bs',1124,320,'閱讀內容暫時不可得'],['bn',1124,342,'不含 GitHub failure']] },

  { id: 'adapter', plane: 'integration', band: 'band-integration', x: 200, y: 600, w: 360, h: 88, r: 10, dash: true,
    name: 'GitHub Data Adapter', about: '把外部資料轉換為兩個核心 Port 所需的資料。',
    texts: [['bl',224,628,'GitHub Data Adapter'],['bs',224,650,'符合兩個核心 Port'],['bn',224,672,'DTO 不進入核心 BC']] },
  { id: 'dto-mapper', plane: 'integration', band: 'band-integration', x: 590, y: 600, w: 360, h: 88, r: 10, dash: true,
    name: 'GitHub DTO Mapper', about: '預定的外部 DTO 轉換位置，尚未定義資料形狀。',
    texts: [['bl',614,628,'GitHub DTO Mapper'],['bs',614,650,'預定外部資料轉換'],['bn',614,672,'尚未定義 DTO schema']] },
  { id: 'normalizer', plane: 'integration', band: 'band-integration', x: 980, y: 600, w: 390, h: 88, r: 10, dash: true,
    name: 'Failure Normalizer', about: '在 Adapter 邊界正規化外部 infrastructure failure。',
    texts: [['bl',1004,628,'Failure Normalizer'],['bs',1004,650,'Adapter 邊界正規化'],['bn',1004,672,'核心 BC 只取語意 failure']] },
  { id: 'identity-boundary', plane: 'integration', band: 'band-integration', x: 395, y: 710, w: 320, h: 68, r: 10,
    name: 'TokenProvider 實作邊界', about: 'TokenProvider 的未來實作留在 Integration／Outside 邊界。',
    texts: [['bl',419,738,'TokenProvider 實作邊界'],['bs',419,760,'不形成獨立 Auth BC']] },
  { id: 'bc-mapper', plane: 'integration', band: 'band-integration', x: 765, y: 710, w: 320, h: 68, r: 10, dash: true,
    name: 'BC Failure Mapper', about: '在跨越核心 Port 前，映射為每個 BC 自己的 failure contract。',
    texts: [['bl',789,738,'BC Failure Mapper'],['bs',789,760,'不傳遞 InfraUnknownError']] },

  { id: 'manifest', plane: 'package', band: 'band-package', x: 200, y: 960, w: 270, h: 88, r: 10, dash: true,
    name: 'Package Manifest', about: '目前唯一的 package 宣告：沒有 product、target 或 dependency。',
    texts: [['bl',224,988,'Package Manifest'],['bs',224,1010,'Swift 6 · macOS 15'],['bn',224,1032,'沒有 product 或 target']] },
  { id: 'http-client', plane: 'package', band: 'band-package', x: 500, y: 960, w: 270, h: 88, r: 10, dash: true,
    name: 'HTTPClient', about: '預定的 typed HTTP 入口，尚未有 Swift declaration。',
    texts: [['bl',524,988,'HTTPClient'],['bs',524,1010,'預定 typed HTTP 入口'],['bn',524,1032,'尚未有 Swift 宣告']] },
  { id: 'requester', plane: 'package', band: 'band-package', x: 800, y: 960, w: 270, h: 88, r: 10, dash: true,
    name: 'Requester', about: '預定的 request construction abstraction，尚未定義行為。',
    texts: [['bl',824,988,'Requester'],['bs',824,1010,'預定 request construction'],['bn',824,1032,'尚未定義行為']] },
  { id: 'transport', plane: 'package', band: 'band-package', x: 1100, y: 960, w: 270, h: 88, r: 10, dash: true,
    name: 'Transport', about: '預定的 URLSession 可替換邊界，尚未是 protocol。',
    texts: [['bl',1124,988,'Transport'],['bs',1124,1010,'預定 URLSession 邊界'],['bn',1124,1032,'尚未是 protocol']] },
  { id: 'contracts', plane: 'package', band: 'band-package', x: 350, y: 1100, w: 360, h: 88, r: 10, dash: true,
    name: 'Endpoint／Request／Response', about: '預定資料契約族群，尚未定義型別或 wire shape。',
    texts: [['bl',374,1128,'Endpoint／Request／Response'],['bs',374,1150,'預定的資料契約族群'],['bn',374,1172,'尚未定義型別或 wire shape']] },
  { id: 'token-contract', plane: 'package', band: 'band-package', x: 770, y: 1100, w: 360, h: 88, r: 10, dash: true,
    name: 'TokenProvider Contract', about: '預定的 token abstraction，不含 OAuth 或 Keychain 實作。',
    texts: [['bl',794,1128,'TokenProvider Contract'],['bs',794,1150,'預定 token abstraction'],['bn',794,1172,'不含 OAuth 或 Keychain']] },

  { id: 'urlsession', plane: 'outside', band: 'band-outside', x: 200, y: 1400, w: 350, h: 68, r: 10,
    name: 'Foundation URLSession', about: 'Foundation 提供的網路執行 surface。',
    texts: [['bl',224,1428,'Foundation URLSession'],['bs',224,1450,'外部網路 surface']] },
  { id: 'identity-store', plane: 'outside', band: 'band-outside', x: 590, y: 1400, w: 420, h: 68, r: 10,
    name: 'OAuth／Keychain', about: '外部授權與憑證儲存細節，尚未選型或實作。',
    texts: [['bl',614,1428,'OAuth／Keychain'],['bs',614,1450,'外部授權與憑證細節']] },
  { id: 'github-api', plane: 'outside', band: 'band-outside', x: 1040, y: 1400, w: 330, h: 68, r: 10,
    name: 'GitHub.com API', about: 'Rivet 讀取 Pull Request 資料的外部 API。',
    texts: [['bl',1094,1428,'GitHub.com API'],['bs',1094,1450,'外部 PR 資料來源']] }
];

const EDGES = [
  { from: 'review-port', to: 'adapter', pts: [[335,362],[335,594]], label: { s:'al', x:349, y:478, t:'符合 Port', rot:-90, anchor:'center' } },
  { from: 'content-port', to: 'adapter', pts: [[635,362],[635,500],[380,500],[380,594]], label: { s:'al', x:507, y:492, t:'符合 Port', anchor:'center' } },
  { from: 'adapter', to: 'dto-mapper', pts: [[564,644],[584,644]], label: { s:'al', x:574, y:632, t:'內部轉換', anchor:'center' } },
  { from: 'adapter', to: 'normalizer', pts: [[560,660],[740,660],[740,560],[1175,560],[1175,594]], label: { s:'al', x:754, y:648, t:'外部失敗邊界' } },
  { from: 'normalizer', to: 'bc-mapper', pts: [[1175,692],[1175,744],[1089,744]], label: { s:'al', x:1132, y:732, t:'正規化', anchor:'center' } },
  { from: 'bc-mapper', to: 'inbox-failure', pts: [[925,706],[925,402],[935,402],[935,362]], label: { s:'al', x:939, y:534, t:'轉為 Inbox 語意', rot:-90, anchor:'center' } },
  { from: 'bc-mapper', to: 'reader-failure', pts: [[1089,744],[1436,744],[1436,314],[1376,314]], label: { s:'al', x:1452, y:529, t:'轉為 Reader 語意', rot:-90, anchor:'center' } },
  { from: 'adapter', to: 'http-client', pts: [[380,692],[380,844],[635,844],[635,954]], label: { s:'al', x:649, y:898, t:'預定 package 使用者', rot:-90, anchor:'center' } },
  { from: 'http-client', to: 'requester', pts: [[774,1004],[794,1004]], label: { s:'al', x:784, y:992, t:'預定依賴', anchor:'center' } },
  { from: 'requester', to: 'transport', pts: [[1074,1004],[1094,1004]], label: { s:'al', x:1084, y:992, t:'預定依賴', anchor:'center' } },
  { from: 'http-client', to: 'contracts', pts: [[635,1052],[635,1094]], label: { s:'al', x:649, y:1074, t:'使用契約', rot:-90, anchor:'center' } },
  { from: 'http-client', to: 'token-contract', pts: [[700,1052],[700,1074],[950,1074],[950,1094]], label: { s:'al', x:825, y:1066, t:'預定 token 依賴', anchor:'center' } },
  { from: 'transport', to: 'urlsession', pts: [[1235,1052],[1235,1300],[335,1300],[335,1394]], label: { s:'al', x:349, y:1248, t:'Foundation surface', rot:-90, anchor:'center' } },
  { from: 'token-contract', to: 'identity-boundary', pts: [[950,1094],[950,844],[555,844],[555,784]], label: { s:'al', x:964, y:964, t:'由邊界實作', rot:-90, anchor:'center' } },
  { from: 'identity-boundary', to: 'identity-store', pts: [[555,784],[555,1320],[770,1320],[770,1394]], label: { s:'al', x:784, y:1248, t:'外部憑證細節', rot:-90, anchor:'center' } },
  { from: 'urlsession', to: 'github-api', pts: [[474,1434],[1064,1434]], label: { s:'al', x:769, y:1422, t:'網路通訊', anchor:'center' } }
];

const TEXTS = [
  { s:'title', x:160, y:86, t:'Rivet — GitHub Integration 與 HTTP Client 邊界' },
  { s:'sub', x:160, y:118, t:'核心 Port → Integration Adapter → 預定 transport foundation → Outside；本圖不宣稱已有 HTTP 實作' },
  { s:'tag', x:160, y:146, runs:[{t:'核心 BC',fill:C.sky},{t:' → ',fill:'#4A5462'},{t:'GitHub Integration',fill:C.orange},{t:' → ',fill:'#4A5462'},{t:'RivetHTTPClient（預定）',fill:C.violet},{t:' → Outside',fill:'#4A5462'}] },
  { s:'legend', x:1082, y:86, t:'虛線 — Rivet 擁有、尚未實作的抽象' },
  { s:'legend', x:1082, y:110, t:'實線 — Foundation、外部系統或實作邊界' },
  { s:'legend', x:1143, y:134, t:'顏色 — 所屬的責任 plane' },
  { s:'bn', x:160, y:1600, t:'不變量：HTTP status、token 與 infrastructure failure 不得跨越 PR Inbox 或 PR Reader 的 Port' },
  { s:'bn', x:160, y:1620, t:'baseline：RivetHTTPClient 只有 manifest 與空目錄；沒有 product、target、module 或 Swift source' },
  { s:'bn', x:160, y:1640, t:'延後：API 型別、OAuth、Keychain、retry、DTO schema 與各 BC failure mapping 的實作決策' }
];

const SWATCHES = [
  { x:1046, y:75, w:26, h:13, stroke:'#8B93A1', alpha:0.8, dash:true },
  { x:1046, y:99, w:26, h:13, stroke:C.boxStroke, alpha:1, fill:C.boxFill }
];
const CHIPS = ['core','integration','package','outside'].map((id,i) => ({ x:1046+i*13, y:123, w:9, h:13, fill:planeColor(id) }));
