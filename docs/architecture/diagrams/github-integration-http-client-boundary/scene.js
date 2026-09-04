const W = 1480, H = 1640;

// 此圖只記錄 ownership 與 compile-time boundary；不把 HTTP 呼叫畫成 core BC 的 runtime flow。
const PLANES = {
  core:        { c: '#7DD3FC', label: '核心 Bounded Context' },
  integration: { c: '#F6821F', label: 'GitHub Integration' },
  package:     { c: '#A78BFA', label: '內部 HTTP package' },
  outside:     { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id:'band-core', plane:'core', x:160, y:200, w:1260, h:156, alpha:0.52, dash:true,
    hdr:{x:184,y:230,t:'CORE BOUNDED CONTEXTS'}, tagr:{x:1396,y:230,t:'擁有 PORT 與 FAILURE CONTRACT',alpha:0.6} },
  { id:'band-integration', plane:'integration', x:160, y:440, w:1260, h:238, alpha:0.48,
    hdr:{x:184,y:470,t:'GITHUB INTEGRATION — SUPPORTING BC'}, tagr:{x:1396,y:470,t:'ADAPTER BOUNDARY',alpha:0.6} },
  { id:'band-package', plane:'package', x:160, y:760, w:1260, h:238, alpha:0.5, dash:true,
    hdr:{x:184,y:790,t:'RIVETHTTPCLIENT — MINIMAL INTERFACE'}, tagr:{x:1396,y:790,t:'已實作 product、target 與 tests',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:160, y:1080, w:1260, h:156, alpha:0.48,
    hdr:{x:184,y:1110,t:'OUTSIDE — FOUNDATION 與 GITHUB.COM'}, tagr:{x:1396,y:1110,t:'未實作 concrete transport',alpha:0.6} }
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

  { id:'http-url', plane:'package', band:'band-package', x:200,y:830,w:270,h:88,r:10,dash:true,
    name:'HTTPURL',about:'已實作的 validated URL value object。',
    texts:[['bl',224,858,'HTTPURL'],['bs',224,880,'http／https + host'],['bn',224,902,'typed validation error']] },
  { id:'request', plane:'package', band:'band-package', x:500,y:830,w:270,h:88,r:10,dash:true,
    name:'HTTPRequest',about:'已實作的 request value，直接持有 HTTPURL。',
    texts:[['bl',524,858,'HTTPRequest'],['bs',524,880,'method · headers · body'],['bn',524,902,'不重新驗證 URL']] },
  { id:'client', plane:'package', band:'band-package', x:800,y:830,w:270,h:88,r:10,dash:true,
    name:'HTTPClient／Requester',about:'已實作的最小 HTTP 入口與 URLRequest mapping。',
    texts:[['bl',824,858,'HTTPClient／Requester'],['bs',824,880,'一般 async throws'],['bn',824,902,'無 URLSession transport']] },
  { id:'transport', plane:'package', band:'band-package', x:1100,y:830,w:270,h:88,r:10,dash:true,
    name:'Transport／HTTPResponse',about:'注入式 transport boundary 與未經 policy 轉換的 raw response。',
    texts:[['bl',1124,858,'Transport／HTTPResponse'],['bs',1124,880,'injected · raw response'],['bn',1124,902,'error 原樣傳遞']] },

  { id:'foundation-types', plane:'outside', band:'band-outside', x:200,y:1140,w:540,h:68,r:10,
    name:'Foundation URLRequest／URL／Data',about:'package 直接使用的 Foundation request、URL 與 body types。',
    texts:[['bl',224,1168,'Foundation URLRequest／URL／Data'],['bs',224,1190,'package 直接使用的 Foundation types']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:880,y:1140,w:540,h:68,r:10,
    name:'URLSession／GitHub.com API',about:'future concrete transport 與外部 API；不在此切片實作。',
    texts:[['bl',904,1168,'URLSession／GitHub.com API'],['bs',904,1190,'future implementation surface']] }
];

const EDGES = [
  { from:'adapter',to:'inbox-port',pts:[[470,504],[470,400],[325,400],[325,334]],label:{s:'al',x:339,y:366,t:'符合 Inbox Port',rot:-90,anchor:'center'} },
  { from:'adapter',to:'reader-port',pts:[[470,504],[470,420],[605,420],[605,334]],label:{s:'al',x:619,y:386,t:'符合 Reader Port',rot:-90,anchor:'center'} },
  { from:'adapter',to:'domain-url',pts:[[744,554],[874,554]],label:{s:'al',x:809,y:542,t:'呼叫端組裝',anchor:'center'} },
  { from:'domain-url',to:'http-url',pts:[[1150,604],[1150,720],[335,720],[335,824]],label:{s:'al',x:349,y:666,t:'提供 URL',rot:-90,anchor:'center'} },
  { from:'request',to:'http-url',pts:[[494,874],[474,874]],label:{s:'al',x:484,y:862,t:'依賴',anchor:'center'} },
  { from:'client',to:'request',pts:[[794,874],[776,874]],label:{s:'al',x:785,y:862,t:'使用',anchor:'center'} },
  { from:'client',to:'transport',pts:[[1074,874],[1094,874]],label:{s:'al',x:1084,y:862,t:'注入依賴',anchor:'center'} },
  { from:'client',to:'foundation-types',pts:[[935,924],[935,1040],[470,1040],[470,1134]],label:{s:'al',x:484,y:1084,t:'Foundation mapping',rot:-90,anchor:'center'} },
  { from:'adapter',to:'client',pts:[[470,604],[470,700],[935,700],[935,824]],label:{s:'al',x:949,y:752,t:'採用 package',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:160,y:86,t:'Rivet — GitHub Integration 與 HTTP Client 邊界'},
  {s:'sub',x:160,y:118,t:'Integration Adapter 可採用最小 HTTP interface；Endpoint 組裝與 concrete transport 均留在 package 外'},
  {s:'tag',x:160,y:146,runs:[{t:'Integration Adapter',fill:planeColor('integration')},{t:' → ',fill:'#4A5462'},{t:'HTTPURL',fill:planeColor('package')},{t:' → ',fill:'#4A5462'},{t:'HTTPClient',fill:planeColor('package')},{t:' → ',fill:'#4A5462'},{t:'Transport',fill:planeColor('package')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的 abstraction'},
  {s:'legend',x:1082,y:110,t:'實線 — Foundation 或外部 surface'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:160,y:1470,t:'不變量：HTTP、token 與 infrastructure failure 不得跨越 PR Inbox 或 PR Reader 的 Port'},
  {s:'bn',x:160,y:1490,t:'不變量：Transport error 不由 HTTP package 統一包裝；Adapter 仍負責跨 core Port 前的語意 mapping'},
  {s:'bn',x:160,y:1510,t:'延後：URLSessionTransport、OAuth、Keychain、retry、status validation、decode policy 與 GitHub DTO mapping'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['core','integration','package','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
