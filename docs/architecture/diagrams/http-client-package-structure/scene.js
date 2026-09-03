const W = 1480, H = 1680;

// 此圖只表達未來 package 的 ownership 與預定編譯期依賴，並非執行期 request flow。
const PLANES = {
  integration: { c: '#F6821F', label: 'GitHub Integration Adapter' },
  client:      { c: '#A78BFA', label: 'HTTP client abstraction' },
  contracts:   { c: '#22D3EE', label: 'HTTP contracts' },
  transport:   { c: '#4ADE80', label: 'Transport boundary' },
  outside:     { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id:'band-integration', plane:'integration', x:450, y:200, w:580, h:174, alpha:0.5,
    hdr:{x:474,y:230,t:'GITHUB INTEGRATION ADAPTER'}, tagr:{x:1006,y:230,t:'未來的 PACKAGE CONSUMER',alpha:0.6} },
  { id:'band-client', plane:'client', x:160, y:460, w:1260, h:238, alpha:0.5, dash:true,
    hdr:{x:184,y:490,t:'RIVETHTTPCLIENT — CLIENT ABSTRACTIONS'}, tagr:{x:1396,y:490,t:'預定 · 尚無 SWIFT DECLARATION',alpha:0.6} },
  { id:'band-contracts', plane:'contracts', x:160, y:780, w:1260, h:218, alpha:0.5, dash:true,
    hdr:{x:184,y:810,t:'HTTP CONTRACTS'}, tagr:{x:1396,y:810,t:'預定資料形狀 · 未鎖定 WIRE SHAPE',alpha:0.6} },
  { id:'band-transport', plane:'transport', x:160, y:1080, w:1260, h:150, alpha:0.5, dash:true,
    hdr:{x:184,y:1110,t:'TRANSPORT BOUNDARY'}, tagr:{x:1396,y:1110,t:'預定可替換邊界',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:160, y:1340, w:1260, h:150, alpha:0.48,
    hdr:{x:184,y:1370,t:'OUTSIDE — FOUNDATION SURFACES'}, tagr:{x:1396,y:1370,t:'非 RIVET 所有',alpha:0.6} }
];

const BOXES = [
  { id:'github-adapter', plane:'integration', band:'band-integration', x:510,y:260,w:460,h:88,r:10,dash:true,
    name:'GitHub Data Adapter',about:'未來唯一可使用此 package 的 GitHub Integration Adapter 邊界。',
    texts:[['bl',534,288,'GitHub Data Adapter'],['bs',534,310,'未來 package consumer'],['bn',534,332,'核心 BC 不直接依賴 HTTP client']] },
  { id:'http-client', plane:'client', band:'band-client', x:200,y:530,w:350,h:88,r:10,dash:true,
    name:'HTTPClient',about:'預定的 typed HTTP 入口，尚未有 API、product 或 target。',
    texts:[['bl',224,558,'HTTPClient'],['bs',224,580,'預定 typed HTTP 入口'],['bn',224,602,'尚未有 Swift declaration']] },
  { id:'requester', plane:'client', band:'band-client', x:590,y:530,w:350,h:88,r:10,dash:true,
    name:'Requester',about:'預定將 HTTP contract 組裝為 Foundation request 的 abstraction。',
    texts:[['bl',614,558,'Requester'],['bs',614,580,'預定 request construction'],['bn',614,602,'不定義 header 或 body 規則']] },
  { id:'token-provider', plane:'client', band:'band-client', x:980,y:530,w:350,h:88,r:10,dash:true,
    name:'TokenProvider',about:'預定 token contract；不包含 OAuth、Keychain 或 refresh 行為。',
    texts:[['bl',1004,558,'TokenProvider'],['bs',1004,580,'預定 token contract'],['bn',1004,602,'不含授權實作']] },
  { id:'endpoint', plane:'contracts', band:'band-contracts', x:200,y:850,w:370,h:88,r:10,dash:true,
    name:'Endpoint',about:'預定 URL、method 與 query 的 contract，尚未定義型別。',
    texts:[['bl',224,878,'Endpoint'],['bs',224,900,'預定 URL · method · query'],['bn',224,922,'尚未定義型別']] },
  { id:'request', plane:'contracts', band:'band-contracts', x:600,y:850,w:370,h:88,r:10,dash:true,
    name:'Request',about:'預定 headers 與 body 的 contract，尚未選擇 encode policy。',
    texts:[['bl',624,878,'Request'],['bs',624,900,'預定 headers · body'],['bn',624,922,'未選擇 encode policy']] },
  { id:'response', plane:'contracts', band:'band-contracts', x:1000,y:850,w:370,h:88,r:10,dash:true,
    name:'Response',about:'預定 status、headers 與 payload contract，尚未定義 decode policy。',
    texts:[['bl',1024,878,'Response'],['bs',1024,900,'預定 status · headers · payload'],['bn',1024,922,'未選擇 decode policy']] },
  { id:'transport', plane:'transport', band:'band-transport', x:200,y:1150,w:1180,h:68,r:10,dash:true,
    name:'Transport',about:'預定可替換的 URLSession abstraction，尚未宣告 protocol。',
    texts:[['bl',374,1178,'Transport'],['bs',374,1200,'預定 URLSession boundary']] },
  { id:'url-request', plane:'outside', band:'band-outside', x:180,y:1410,w:285,h:68,r:10,
    name:'URLRequest',about:'Foundation request surface，非 package 自有 contract。',
    texts:[['bl',204,1438,'Foundation URLRequest'],['bs',204,1460,'Foundation surface']] },
  { id:'url-response', plane:'outside', band:'band-outside', x:495,y:1410,w:285,h:68,r:10,
    name:'HTTPURLResponse',about:'Foundation HTTP response surface，非 package 自有 contract。',
    texts:[['bl',519,1438,'HTTPURLResponse'],['bs',519,1460,'Foundation surface']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:810,y:1410,w:285,h:68,r:10,
    name:'Foundation URLSession',about:'Foundation 提供的資料任務與網路執行 surface。',
    texts:[['bl',834,1438,'Foundation URLSession'],['bs',834,1460,'網路執行 surface']] },
  { id:'network', plane:'outside', band:'band-outside', x:1125,y:1410,w:285,h:68,r:10,
    name:'Network',about:'網路與 server availability 皆為 package 外的 infrastructure。',
    texts:[['bl',1149,1438,'Network'],['bs',1149,1460,'外部 infrastructure']] }
];

const EDGES = [
  { from:'github-adapter',to:'http-client',pts:[[740,352],[740,420],[375,420],[375,524]],label:{s:'al',x:389,y:470,t:'預定使用',rot:-90,anchor:'center'} },
  { from:'http-client',to:'requester',pts:[[554,574],[584,574]],label:{s:'al',x:569,y:562,t:'預定依賴',anchor:'center'} },
  { from:'http-client',to:'token-provider',pts:[[375,622],[375,662],[1155,662],[1155,624]],label:{s:'al',x:765,y:654,t:'預定依賴',anchor:'center'} },
  { from:'http-client',to:'endpoint',pts:[[375,622],[375,844]],label:{s:'al',x:389,y:734,t:'使用 contract',rot:-90,anchor:'center'} },
  { from:'http-client',to:'request',pts:[[445,622],[445,742],[635,742],[635,844]],label:{s:'al',x:649,y:792,t:'使用 contract',rot:-90,anchor:'center'} },
  { from:'http-client',to:'response',pts:[[500,622],[500,722],[1185,722],[1185,844]],label:{s:'al',x:1199,y:782,t:'使用 contract',rot:-90,anchor:'center'} },
  { from:'requester',to:'transport',pts:[[765,622],[765,1074],[525,1074],[525,1144]],label:{s:'al',x:539,y:848,t:'預定依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'url-request',pts:[[800,622],[800,1280],[322,1280],[322,1404]],label:{s:'al',x:336,y:1100,t:'Foundation request surface',rot:-90,anchor:'center'} },
  { from:'transport',to:'urlsession',pts:[[790,1222],[790,1300],[952,1300],[952,1404]],label:{s:'al',x:966,y:1352,t:'依賴 Foundation surface',rot:-90,anchor:'center'} },
  { from:'github-adapter',to:'token-provider',pts:[[970,352],[970,420],[1155,420],[1155,524]],label:{s:'al',x:984,y:456,t:'符合 contract',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:160,y:86,t:'RivetHTTPClient — 預定 package 結構'},
  {s:'sub',x:160,y:118,t:'Adapter → HTTPClient → Requester／TokenProvider → Transport → Foundation；僅表達 ownership 與預定依賴'},
  {s:'tag',x:160,y:146,runs:[{t:'HTTPClient',fill:C.violet},{t:' → ',fill:'#4A5462'},{t:'Requester',fill:C.violet},{t:' → ',fill:'#4A5462'},{t:'Transport',fill:C.green},{t:' → ',fill:'#4A5462'},{t:'URLSession',fill:C.slate}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有、尚未實作的抽象'},
  {s:'legend',x:1082,y:110,t:'實線 — Foundation 或外部 infrastructure'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:160,y:1560,t:'不變量：package failure 不等於 PR Inbox 或 PR Reader 的 failure contract；Adapter 必須先完成語意映射'},
  {s:'bn',x:160,y:1580,t:'baseline：只有 Package.swift、Sources/.gitkeep、Tests/.gitkeep；本圖中的每個 owned abstraction 都尚未成為 Swift API'},
  {s:'bn',x:160,y:1600,t:'延後：Codable schema、header precedence、status validation、retry、token refresh 與 URLSession configuration'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['integration','client','contracts','transport','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
