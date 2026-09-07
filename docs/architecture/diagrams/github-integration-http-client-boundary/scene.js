const W = 1480, H = 1800;

// 此圖只記錄 ownership 與 compile-time boundary；request preparation 的 runtime lifecycle
// 由同目錄的 github-authorization-lifecycle artifact 獨立表達。
const PLANES = {
  core:        { c: '#7DD3FC', label: '核心 Bounded Context' },
  integration: { c: '#F6821F', label: 'GitHub Integration' },
  package:     { c: '#A78BFA', label: '內部 HTTP package' },
  outside:     { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id:'band-core', plane:'core', x:160, y:200, w:1260, h:156, alpha:0.52, dash:true,
    hdr:{x:184,y:230,t:'CORE BOUNDED CONTEXTS'}, tagr:{x:1396,y:230,t:'擁有 PORT 與 FAILURE CONTRACT',alpha:0.6} },
  { id:'band-integration', plane:'integration', x:160, y:440, w:1260, h:390, alpha:0.48,
    hdr:{x:184,y:470,t:'GITHUB INTEGRATION — SUPPORTING BC'}, tagr:{x:1396,y:470,t:'ADAPTER BOUNDARY',alpha:0.6} },
  { id:'band-package', plane:'package', x:160, y:910, w:1260, h:238, alpha:0.5, dash:true,
    hdr:{x:184,y:940,t:'RIVETHTTPCLIENT — MINIMAL INTERFACE'}, tagr:{x:1396,y:940,t:'已實作 product、target 與 tests',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:160, y:1230, w:1260, h:156, alpha:0.48,
    hdr:{x:184,y:1260,t:'OUTSIDE — FOUNDATION、CREDENTIAL 與 GITHUB.COM'}, tagr:{x:1396,y:1260,t:'未實作 concrete transport',alpha:0.6} }
];

const BOXES = [
  { id:'inbox-port', plane:'core', band:'band-core', x:200,y:260,w:250,h:68,r:10,dash:true,
    name:'PR Inbox Port',about:'PR Inbox 自有的資料需求，不認識 GitHub 或 HTTP。',
    texts:[['bl',224,288,'PR Inbox Port'],['bs',224,310,'不依賴 GitHub 或 HTTP']] },
  { id:'reader-port', plane:'core', band:'band-core', x:480,y:260,w:250,h:68,r:10,dash:true,
    name:'PR Reader Port',about:'PR Reader 自有的資料需求，不認識 GitHub 或 HTTP。',
    texts:[['bl',504,288,'PR Reader Port'],['bs',504,310,'不依賴 GitHub 或 HTTP']] },
  { id:'inbox-failure-contract', plane:'core', band:'band-core', x:880,y:260,w:250,h:68,r:10,dash:true,
    name:'PR Inbox Failure Contract',about:'PR Inbox 自有的語意 failure contract，不含 infrastructure detail。',
    texts:[['bl',904,288,'Inbox Failure Contract'],['bs',904,310,'僅屬於 PR Inbox']] },
  { id:'reader-failure-contract', plane:'core', band:'band-core', x:1160,y:260,w:250,h:68,r:10,dash:true,
    name:'PR Reader Failure Contract',about:'PR Reader 自有的語意 failure contract，不含 infrastructure detail。',
    texts:[['bl',1184,288,'Reader Failure Contract'],['bs',1184,310,'僅屬於 PR Reader']] },

  { id:'adapter', plane:'integration', band:'band-integration', x:200,y:510,w:540,h:88,r:10,dash:true,
    name:'GitHub Data Adapter',about:'將外部資料轉換成核心 Port 所需的資料。',
    texts:[['bl',224,538,'GitHub Data Adapter'],['bs',224,560,'符合核心 Port'],['bn',224,582,'DTO 不進入 core BC']] },
  { id:'domain-url', plane:'integration', band:'band-integration', x:880,y:510,w:540,h:88,r:10,dash:true,
    name:'API domain URL composition',about:'Endpoint、Base URL、Path 與 Query 由呼叫端或 domain layer 組裝。',
    texts:[['bl',904,538,'API domain URL composition'],['bs',904,560,'Endpoint／Base URL／Path／Query'],['bn',904,582,'不屬於 RivetHTTPClient']] },
  { id:'token-provider', plane:'integration', band:'band-integration', x:200,y:650,w:540,h:104,r:10,dash:true,
    name:'GitHubTokenProvider（future declaration）',about:'GitHub Integration 擁有的 future seam；交付既有 PAT 對應的 Integration value type。',
    texts:[['bl',224,678,'GitHubTokenProvider（future declaration）'],['bs',224,700,'token() throws → GitHubAccessToken'],['bs',224,722,'初版：一個既有 fine-grained PAT'],['bn',224,742,'不是 HTTP package API']] },
  { id:'request-authorizer', plane:'integration', band:'band-integration', x:880,y:650,w:540,h:104,r:10,dash:true,
    name:'GitHub request authorizer（future declaration）',about:'每個 GitHub request 進入 HTTP package 前，設定或覆寫 Bearer Authorization。',
    texts:[['bl',904,678,'GitHub request authorizer（future declaration）'],['bs',904,700,'每個 GitHub request 取得 token'],['bs',904,722,'設定／覆寫 Authorization: Bearer …'],['bn',904,742,'無 refresh、401 retry 或 HTTP policy']] },

  { id:'http-url', plane:'package', band:'band-package', x:200,y:980,w:270,h:88,r:10,dash:true,
    name:'HTTPURL',about:'已實作的 validated URL value object。',
    texts:[['bl',224,1008,'HTTPURL'],['bs',224,1030,'http／https + host'],['bn',224,1052,'typed validation error']] },
  { id:'request', plane:'package', band:'band-package', x:500,y:980,w:270,h:88,r:10,dash:true,
    name:'HTTPRequest',about:'已實作的 request value，直接持有 HTTPURL。',
    texts:[['bl',524,1008,'HTTPRequest'],['bs',524,1030,'method · headers · body'],['bn',524,1052,'不重新驗證 URL']] },
  { id:'client', plane:'package', band:'band-package', x:800,y:980,w:270,h:88,r:10,dash:true,
    name:'HTTPClient／Requester',about:'已實作的最小 HTTP 入口與 URLRequest mapping。',
    texts:[['bl',824,1008,'HTTPClient／Requester'],['bs',824,1030,'一般 async throws'],['bn',824,1052,'無 URLSession transport']] },
  { id:'transport', plane:'package', band:'band-package', x:1100,y:980,w:270,h:88,r:10,dash:true,
    name:'Transport／HTTPResponse',about:'注入式 transport boundary 與未經 policy 轉換的 raw response。',
    texts:[['bl',1124,1008,'Transport／HTTPResponse'],['bs',1124,1030,'injected · raw response'],['bn',1124,1052,'error 原樣傳遞']] },

  { id:'foundation-types', plane:'outside', band:'band-outside', x:200,y:1290,w:360,h:68,r:10,
    name:'Foundation URLRequest／URL／Data',about:'package 直接使用的 Foundation request、URL 與 body types。',
    texts:[['bl',224,1318,'Foundation URLRequest／URL／Data'],['bs',224,1340,'package 直接使用的 Foundation types']] },
  { id:'credential', plane:'outside', band:'band-outside', x:620,y:1290,w:360,h:68,r:10,
    name:'使用者設定 PAT／Keychain',about:'既有的單一 fine-grained PAT 與其儲存位置都在 Outside；本 topic 不決定 concrete adapter。',
    texts:[['bl',644,1318,'使用者設定 PAT／Keychain'],['bs',644,1340,'Outside；不屬於 HTTP package']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:1040,y:1290,w:360,h:68,r:10,
    name:'URLSession／GitHub.com API',about:'future concrete transport 與外部 API；不在此切片實作。',
    texts:[['bl',1064,1318,'URLSession／GitHub.com API'],['bs',1064,1340,'future implementation surface']] }
];

const EDGES = [
  { from:'adapter',to:'inbox-port',pts:[[470,504],[470,400],[325,400],[325,334]],label:{s:'al',x:339,y:366,t:'符合 Inbox Port',rot:-90,anchor:'center'} },
  { from:'adapter',to:'reader-port',pts:[[470,504],[470,420],[605,420],[605,334]],label:{s:'al',x:619,y:386,t:'符合 Reader Port',rot:-90,anchor:'center'} },
  { from:'adapter',to:'domain-url',pts:[[744,554],[874,554]],label:{s:'al',x:809,y:542,t:'呼叫端組裝',anchor:'center'} },
  { from:'domain-url',to:'http-url',pts:[[1150,604],[1150,860],[335,860],[335,974]],label:{s:'al',x:349,y:726,t:'提供 URL',rot:-90,anchor:'center'} },
  { from:'request',to:'http-url',pts:[[494,1024],[474,1024]],label:{s:'al',x:484,y:1012,t:'依賴',anchor:'center'} },
  { from:'client',to:'request',pts:[[794,1024],[776,1024]],label:{s:'al',x:785,y:1012,t:'使用',anchor:'center'} },
  { from:'client',to:'transport',pts:[[1074,1024],[1094,1024]],label:{s:'al',x:1084,y:1012,t:'注入依賴',anchor:'center'} },
  { from:'client',to:'foundation-types',pts:[[935,1074],[935,1190],[380,1190],[380,1284]],label:{s:'al',x:394,y:1234,t:'Foundation mapping',rot:-90,anchor:'center'} },
  { from:'adapter',to:'client',pts:[[470,604],[470,860],[935,860],[935,974]],label:{s:'al',x:949,y:752,t:'採用 package',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:160,y:86,t:'Rivet — GitHub Integration 與 HTTP Client 邊界'},
  {s:'sub',x:160,y:118,t:'Integration 擁有 future authorization seam；HTTP package 維持最小 raw request interface'},
  {s:'tag',x:160,y:146,runs:[{t:'Integration-owned authorization seam',fill:planeColor('integration')},{t:' · ',fill:'#4A5462'},{t:'HTTP package raw request interface',fill:planeColor('package')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的 abstraction'},
  {s:'legend',x:1082,y:110,t:'實線 — Foundation 或外部 surface'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:160,y:1530,t:'不變量：HTTP、token 與 infrastructure failure 不得跨越 PR Inbox 或 PR Reader 的 Port'},
  {s:'bn',x:160,y:1550,t:'不變量：RivetHTTPClient 不持有 token、沒有 TokenProvider API，也不處理 refresh 或 401 retry'},
  {s:'bn',x:160,y:1570,t:'宣告而非實作：future provider／authorizer 屬 GitHub Integration；Keychain 與 PAT 都是 Outside；runtime lifecycle 見獨立圖'},
  {s:'bn',x:160,y:1590,t:'延後：URLSessionTransport、OAuth、Keychain adapter、retry、status validation、decode policy 與 GitHub DTO mapping'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['core','integration','package','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
