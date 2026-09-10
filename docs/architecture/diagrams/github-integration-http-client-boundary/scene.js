const W = 1480, H = 1910;

// 此圖只記錄 ownership 與 compile-time boundary；request preparation 的 runtime lifecycle
// 由同目錄的 github-authorization-lifecycle artifact 獨立表達。
const PLANES = {
  core:        { c: '#7DD3FC', label: '核心 Bounded Context' },
  localInfra:  { c: '#F472B6', label: 'Domain-local GitHub Infra' },
  integration: { c: '#F6821F', label: 'GitHub Integration shared capability' },
  package:     { c: '#A78BFA', label: '內部 HTTP package' },
  outside:     { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id:'band-core', plane:'core', x:160, y:200, w:1260, h:156, alpha:0.52, dash:true,
    hdr:{x:184,y:230,t:'CORE BOUNDED CONTEXTS'}, tagr:{x:1396,y:230,t:'擁有 PORT 與 FAILURE CONTRACT',alpha:0.6} },
  { id:'band-local-infra', plane:'localInfra', x:160, y:440, w:1260, h:410, alpha:0.48,
    hdr:{x:184,y:470,t:'CONSUMING DOMAIN — LOCAL GITHUB INFRA'}, tagr:{x:1396,y:470,t:'ADAPTER · DTO · FAILURE MAPPING',alpha:0.6} },
  { id:'band-integration', plane:'integration', x:160, y:930, w:1260, h:210, alpha:0.48,
    hdr:{x:184,y:960,t:'GITHUB INTEGRATION — LOWER SHARED CAPABILITY'}, tagr:{x:1396,y:960,t:'NO DOMAIN PORT CONFORMER',alpha:0.6} },
  { id:'band-package', plane:'package', x:160, y:1220, w:1260, h:238, alpha:0.5, dash:true,
    hdr:{x:184,y:1250,t:'RIVETHTTPCLIENT — MINIMAL INTERFACE'}, tagr:{x:1396,y:1250,t:'已實作 product、target 與 tests',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:160, y:1540, w:1260, h:156, alpha:0.48,
    hdr:{x:184,y:1570,t:'OUTSIDE — FOUNDATION、CREDENTIAL 與 GITHUB.COM'}, tagr:{x:1396,y:1570,t:'Foundation networking surface',alpha:0.6} }
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

  { id:'inbox-rest-adapter', plane:'localInfra', band:'band-local-infra', x:200,y:510,w:300,h:104,r:10,dash:true,
    name:'PR Inbox local REST Adapter',about:'PR Inbox 的 local Infra 實作自己的 Port，並隔離 REST 外部細節。',
    texts:[['bl',224,538,'PR Inbox local REST Adapter'],['bs',224,560,'只實作 Inbox Port'],['bs',224,582,'endpoint／DTO／failure mapping'],['bn',224,602,'非 Integration conformer']] },
  { id:'reader-rest-adapter', plane:'localInfra', band:'band-local-infra', x:540,y:510,w:300,h:104,r:10,dash:true,
    name:'PR Reader local REST Adapter',about:'PR Reader 的 local Infra 實作自己的 Port，並隔離 REST 外部細節。',
    texts:[['bl',564,538,'PR Reader local REST Adapter'],['bs',564,560,'只實作 Reader Port'],['bs',564,582,'endpoint／DTO／failure mapping'],['bn',564,602,'非 Integration conformer']] },
  { id:'domain-url', plane:'localInfra', band:'band-local-infra', x:880,y:510,w:540,h:104,r:10,dash:true,
    name:'Domain-local API composition',about:'Endpoint、Base URL、Path 與 Query 由 consuming Domain local Infra 組裝。',
    texts:[['bl',904,538,'Domain-local API composition'],['bs',904,560,'Endpoint／Base URL／Path／Query'],['bs',904,582,'DTO 與 failure mapping'],['bn',904,602,'不屬於 RivetHTTPClient']] },
  { id:'graphql-adapter', plane:'localInfra', band:'band-local-infra', x:200,y:680,w:540,h:104,r:10,dash:true,
    name:'Domain-local GitHub GraphQL Adapter',about:'每個 Domain local Infra 的 GraphQL adapter；維持 Apollo-only route。',
    texts:[['bl',224,708,'Domain-local GitHub GraphQL Adapter'],['bs',224,730,'ApolloClient route'],['bs',224,752,'不經 RivetHTTPClient.Transport'],['bn',224,772,'token interceptor 留待獨立 topic']] },
  { id:'local-failure', plane:'localInfra', band:'band-local-infra', x:880,y:680,w:540,h:104,r:10,dash:true,
    name:'Domain-local failure boundary',about:'每個 Domain local Infra 將外部失敗映射為自己的 Domain failure contract。',
    texts:[['bl',904,708,'Domain-local failure boundary'],['bs',904,730,'正規化 infrastructure failure'],['bs',904,752,'映射為 Domain failure contract'],['bn',904,772,'不跨越 core Port']] },
  { id:'token-provider', plane:'integration', band:'band-integration', x:200,y:1000,w:540,h:104,r:10,dash:true,
    name:'GitHubTokenProvider（future declaration）',about:'GitHub Integration 的 lower shared capability；交付既有 PAT 對應的 shared value type。',
    texts:[['bl',224,1028,'GitHubTokenProvider（future declaration）'],['bs',224,1050,'交付 shared GitHubAccessToken'],['bs',224,1072,'初版：一個既有 fine-grained PAT'],['bn',224,1092,'具體 failure contract 延後決定']] },
  { id:'request-authorizer', plane:'integration', band:'band-integration', x:880,y:1000,w:540,h:104,r:10,dash:true,
    name:'Shared REST request authorizer（future declaration）',about:'供 Domain-local REST adapter 採用的 shared capability；不符合 Domain Port。',
    texts:[['bl',904,1028,'Shared REST request authorizer（future declaration）'],['bs',904,1050,'設定／覆寫 Authorization: Bearer …'],['bs',904,1072,'僅供 local GitHub REST adapter 採用'],['bn',904,1092,'無 refresh、401 retry 或 HTTP policy']] },

  { id:'http-url', plane:'package', band:'band-package', x:200,y:1290,w:270,h:88,r:10,dash:true,
    name:'HTTPURL',about:'已實作的 validated URL value object。',
    texts:[['bl',224,1318,'HTTPURL'],['bs',224,1340,'http／https + host'],['bn',224,1362,'typed validation error']] },
  { id:'request', plane:'package', band:'band-package', x:500,y:1290,w:270,h:88,r:10,dash:true,
    name:'HTTPRequest',about:'已實作的 request value，直接持有 HTTPURL。',
    texts:[['bl',524,1318,'HTTPRequest'],['bs',524,1340,'method · headers · body'],['bn',524,1362,'不重新驗證 URL']] },
  { id:'client', plane:'package', band:'band-package', x:800,y:1290,w:270,h:88,r:10,dash:true,
    name:'HTTPClient／Requester',about:'已實作的最小 HTTP 入口、typed transport failure 與 URLRequest mapping。',
    texts:[['bl',824,1318,'HTTPClient／Requester'],['bs',824,1340,'throws(HTTPClientError)'],['bn',824,1362,'建立 Foundation request']] },
  { id:'transport', plane:'package', band:'band-package', x:1100,y:1290,w:270,h:88,r:10,dash:true,
    name:'Transport／URLSessionTransport／HTTPResponse',about:'注入式 transport boundary、production URLSession transport 與未經 policy 轉換的 raw response；JSON convenience 使用 caller-owned decoder。',
    texts:[['bl',1124,1318,'Transport／URLSessionTransport'],['bs',1124,1340,'HTTPClientError · raw response'],['bn',1124,1362,'JSON decoder 由 caller 擁有']] },

  { id:'foundation-types', plane:'outside', band:'band-outside', x:200,y:1600,w:360,h:68,r:10,
    name:'Foundation URLRequest／URL／Data',about:'package 直接使用的 Foundation request、URL 與 body types。',
    texts:[['bl',224,1628,'Foundation URLRequest／URL／Data'],['bs',224,1650,'package 直接使用的 Foundation types']] },
  { id:'credential', plane:'outside', band:'band-outside', x:620,y:1600,w:360,h:68,r:10,
    name:'使用者設定 PAT／Keychain',about:'既有的單一 fine-grained PAT 與其儲存位置都在 Outside；本 topic 不決定 concrete adapter。',
    texts:[['bl',644,1628,'使用者設定 PAT／Keychain'],['bs',644,1650,'Outside；不屬於 HTTP package']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:1040,y:1600,w:360,h:68,r:10,
    name:'Foundation URLSession／GitHub.com API',about:'URLSessionTransport 採用的 Foundation networking surface；GitHub adapter 仍未實作。',
    texts:[['bl',1064,1628,'Foundation URLSession／GitHub.com API'],['bs',1064,1650,'adapter direction 留待後續 topic']] }
];

const EDGES = [
  { from:'inbox-rest-adapter',to:'inbox-port',pts:[[350,504],[350,400],[325,400],[325,334]],label:{s:'al',x:339,y:366,t:'local Infra 實作 Inbox Port',rot:-90,anchor:'center'} },
  { from:'reader-rest-adapter',to:'reader-port',pts:[[690,504],[690,400],[605,400],[605,334]],label:{s:'al',x:619,y:386,t:'local Infra 實作 Reader Port',rot:-90,anchor:'center'} },
  { from:'inbox-rest-adapter',to:'domain-url',pts:[[506,554],[874,554]],label:{s:'al',x:690,y:542,t:'每個 adapter 自行組裝',anchor:'center'} },
  { from:'reader-rest-adapter',to:'domain-url',pts:[[846,574],[862,574],[862,594],[874,594]],label:{s:'al',x:854,y:562,t:'local composition',rot:-90,anchor:'center'} },
  { from:'domain-url',to:'http-url',pts:[[1426,554],[1440,554],[1440,1170],[335,1170],[335,1284]],label:{s:'al',x:349,y:1070,t:'提供 URL',rot:-90,anchor:'center'} },
  { from:'request',to:'http-url',pts:[[494,1334],[474,1334]],label:{s:'al',x:484,y:1322,t:'依賴',anchor:'center'} },
  { from:'client',to:'request',pts:[[794,1334],[776,1334]],label:{s:'al',x:785,y:1322,t:'使用',anchor:'center'} },
  { from:'client',to:'transport',pts:[[1074,1334],[1094,1334]],label:{s:'al',x:1084,y:1322,t:'注入依賴',anchor:'center'} },
  { from:'client',to:'foundation-types',pts:[[935,1384],[935,1490],[380,1490],[380,1594]],label:{s:'al',x:394,y:1542,t:'Foundation mapping',rot:-90,anchor:'center'} },
  { from:'transport',to:'urlsession',pts:[[1235,1384],[1235,1594]],label:{s:'al',x:1249,y:1488,t:'compile-time 採用',rot:-90,anchor:'center'} },
  { from:'inbox-rest-adapter',to:'request-authorizer',pts:[[194,554],[140,554],[140,890],[1150,890],[1150,994]],label:{s:'al',x:680,y:878,t:'local REST adapter 採用 shared capability',anchor:'center'} },
  { from:'reader-rest-adapter',to:'request-authorizer',pts:[[846,554],[860,554],[860,890],[1170,890],[1170,994]],label:{s:'al',x:874,y:878,t:'local REST adapter 採用',anchor:'center'} },
  { from:'inbox-rest-adapter',to:'client',pts:[[194,574],[120,574],[120,1170],[935,1170],[935,1284]],label:{s:'al',x:537,y:1158,t:'local REST adapter 採用 package',anchor:'center'} },
  { from:'reader-rest-adapter',to:'client',pts:[[846,574],[860,574],[860,1170],[955,1170],[955,1284]],label:{s:'al',x:874,y:1158,t:'local REST adapter 採用',anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:160,y:86,t:'Rivet — GitHub Integration 與 HTTP Client 邊界'},
  {s:'sub',x:160,y:118,t:'Domain-local GitHub Infra 實作自己的 Port；Integration 只提供 lower shared authorization capability'},
  {s:'tag',x:160,y:146,runs:[{t:'Domain-local adapter',fill:planeColor('localInfra')},{t:' · ',fill:'#4A5462'},{t:'GitHub shared capability',fill:planeColor('integration')},{t:' · ',fill:'#4A5462'},{t:'HTTP package raw request interface',fill:planeColor('package')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的 abstraction'},
  {s:'legend',x:1082,y:110,t:'實線 — Foundation 或外部 surface'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:160,y:1750,t:'不變量：每個 Domain local Infra 擁有 adapter、endpoint、DTO 與 failure mapping；Integration 不符合 Domain Port'},
  {s:'bn',x:160,y:1770,t:'不變量：HTTP、token 與 infrastructure failure 不得跨越 PR Inbox 或 PR Reader 的 Port；PR Inbox 與 PR Reader 不直接相依'},
  {s:'bn',x:160,y:1790,t:'不變量：RivetHTTPClient 不持有 token、沒有 TokenProvider API，也不處理 refresh 或 401 retry；JSON decoder 由 caller 擁有'},
  {s:'bn',x:160,y:1810,t:'宣告而非實作：future shared provider／REST authorizer 屬 GitHub Integration；Keychain 與 PAT 都是 Outside；runtime lifecycle 見獨立圖'},
  {s:'bn',x:160,y:1830,t:'延後：OAuth、Keychain adapter、retry、status／Content-Type validation、Apollo token interceptor、schema 與 operation'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['core','localInfra','integration','package','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
