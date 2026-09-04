const W = 1480, H = 1680;

// 此圖只表達 package ownership 與編譯期依賴，不描述 transport 的執行期 request／response flow。
const PLANES = {
  caller:     { c: '#F6821F', label: '呼叫端 API domain' },
  client:     { c: '#A78BFA', label: 'HTTP client abstraction' },
  contracts:  { c: '#22D3EE', label: 'HTTP contracts' },
  transport:  { c: '#4ADE80', label: 'Transport boundary' },
  outside:    { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id:'band-caller', plane:'caller', x:160, y:200, w:1260, h:156, alpha:0.48,
    hdr:{x:184,y:230,t:'CALLER／DOMAIN LAYER'}, tagr:{x:1396,y:230,t:'不屬於 RIVETHTTPCLIENT',alpha:0.6} },
  { id:'band-contracts', plane:'contracts', x:160, y:440, w:1260, h:238, alpha:0.5, dash:true,
    hdr:{x:184,y:470,t:'RIVETHTTPCLIENT — HTTP CONTRACTS'}, tagr:{x:1396,y:470,t:'已實作最小介面',alpha:0.6} },
  { id:'band-client', plane:'client', x:160, y:760, w:1260, h:156, alpha:0.5, dash:true,
    hdr:{x:184,y:790,t:'CLIENT ABSTRACTIONS'}, tagr:{x:1396,y:790,t:'已實作 · 無底層 transport',alpha:0.6} },
  { id:'band-transport', plane:'transport', x:160, y:1000, w:1260, h:156, alpha:0.5, dash:true,
    hdr:{x:184,y:1030,t:'TRANSPORT BOUNDARY'}, tagr:{x:1396,y:1030,t:'注入式 contract',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:160, y:1240, w:1260, h:156, alpha:0.48,
    hdr:{x:184,y:1270,t:'OUTSIDE — FOUNDATION SURFACE'}, tagr:{x:1396,y:1270,t:'非 RIVET 所有',alpha:0.6} }
];

const BOXES = [
  { id:'endpoint-domain', plane:'caller', band:'band-caller', x:250,y:260,w:1080,h:68,r:10,
    name:'Endpoint／Base URL／Path／Query',about:'呼叫端或 domain layer 組裝 API URL；package 不提供此 API。',
    texts:[['bl',274,288,'Endpoint／Base URL／Path／Query'],['bs',274,310,'呼叫端組裝；再建立 HTTPURL']] },

  { id:'http-url', plane:'contracts', band:'band-contracts', x:200,y:510,w:270,h:88,r:10,dash:true,
    name:'HTTPURL',about:'package-owned value object；只接受有 host 的 http 或 https URL。',
    texts:[['bl',224,538,'HTTPURL'],['bs',224,560,'http／https + host'],['bn',224,582,'唯一 typed throws 邊界']] },
  { id:'url-error', plane:'contracts', band:'band-contracts', x:500,y:510,w:270,h:88,r:10,dash:true,
    name:'HTTPURLValidationError',about:'HTTPURL construction 的封閉 validation error。',
    texts:[['bl',524,538,'HTTPURLValidationError'],['bs',524,560,'scheme 或 host validation'],['bn',524,582,'package-owned error']] },
  { id:'request', plane:'contracts', band:'band-contracts', x:800,y:510,w:270,h:88,r:10,dash:true,
    name:'HTTPRequest',about:'只持有已驗證 HTTPURL、method、headers 與 optional body。',
    texts:[['bl',824,538,'HTTPRequest'],['bs',824,560,'HTTPURL · method · headers'],['bn',824,582,'body: Data?；不 throws']] },
  { id:'response', plane:'contracts', band:'band-contracts', x:1100,y:510,w:270,h:88,r:10,dash:true,
    name:'HTTPResponse',about:'Transport 未經 status 或 decode policy 處理的 raw response contract。',
    texts:[['bl',1124,538,'HTTPResponse'],['bs',1124,560,'status · headers · body'],['bn',1124,582,'raw return value']] },
  { id:'method-headers', plane:'contracts', band:'band-contracts', x:420,y:616,w:640,h:42,r:10,dash:true,
    name:'HTTPMethod 與 HTTPHeaders',about:'HTTPRequest 使用的 package-owned method 與 header value types。',
    texts:[['bs',444,643,'HTTPMethod 與 HTTPHeaders — package-owned request metadata']] },

  { id:'http-client', plane:'client', band:'band-client', x:200,y:820,w:560,h:68,r:10,dash:true,
    name:'HTTPClient',about:'公開入口；以一般 async throws 委派給 Requester。',
    texts:[['bl',224,848,'HTTPClient'],['bs',224,870,'execute(HTTPRequest) async throws']] },
  { id:'requester', plane:'client', band:'band-client', x:860,y:820,w:560,h:68,r:10,dash:true,
    name:'Requester',about:'把已驗證 HTTPRequest 映射為 Foundation URLRequest；不重驗 URL。',
    texts:[['bl',884,848,'Requester'],['bs',884,870,'HTTPRequest → URLRequest']] },

  { id:'transport', plane:'transport', band:'band-transport', x:200,y:1060,w:1220,h:68,r:10,dash:true,
    name:'Transport',about:'注入式 async throws contract；錯誤會原樣向上傳遞。',
    texts:[['bl',224,1088,'Transport'],['bs',224,1110,'injected；沒有統一 error model']] },

  { id:'url-request', plane:'outside', band:'band-outside', x:200,y:1300,w:350,h:68,r:10,
    name:'Foundation URLRequest',about:'Requester 實際映射到的 Foundation request surface。',
    texts:[['bl',224,1328,'Foundation URLRequest'],['bs',224,1350,'Requester 的輸出 surface']] },
  { id:'foundation-url-data', plane:'outside', band:'band-outside', x:590,y:1300,w:350,h:68,r:10,
    name:'Foundation URL／Data',about:'HTTPURL value 與 request／response body 直接使用的 Foundation types。',
    texts:[['bl',614,1328,'Foundation URL／Data'],['bs',614,1350,'value 與 body 的直接依賴']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:980,y:1300,w:440,h:68,r:10,
    name:'Foundation URLSession',about:'可能的 future transport implementation；此切片不實作或依賴它。',
    texts:[['bl',1004,1328,'Foundation URLSession'],['bs',1004,1350,'本切片未實作']] }
];

const EDGES = [
  { from:'endpoint-domain',to:'http-url',pts:[[740,334],[740,400],[335,400],[335,504]],label:{s:'al',x:349,y:444,t:'建立',rot:-90,anchor:'center'} },
  { from:'http-url',to:'url-error',pts:[[474,554],[494,554]],label:{s:'al',x:484,y:542,t:'typed error',anchor:'center'} },
  { from:'request',to:'http-url',pts:[[935,604],[935,628],[335,628],[335,604]],label:{s:'al',x:635,y:620,t:'依賴',anchor:'center'} },
  { from:'request',to:'method-headers',pts:[[1076,554],[1080,554],[1080,637],[1064,637]],label:{s:'al',x:1074,y:592,t:'依賴',rot:-90,anchor:'center'} },
  { from:'http-client',to:'requester',pts:[[764,854],[854,854]],label:{s:'al',x:809,y:842,t:'依賴',anchor:'center'} },
  { from:'http-client',to:'request',pts:[[480,814],[480,718],[935,718],[935,604]],label:{s:'al',x:949,y:706,t:'使用',rot:-90,anchor:'center'} },
  { from:'http-client',to:'response',pts:[[520,814],[520,738],[1235,738],[1235,604]],label:{s:'al',x:1249,y:698,t:'回傳型別',rot:-90,anchor:'center'} },
  { from:'requester',to:'transport',pts:[[1140,894],[1140,994],[810,994],[810,1054]],label:{s:'al',x:824,y:956,t:'注入依賴',rot:-90,anchor:'center'} },
  { from:'transport',to:'response',pts:[[810,1054],[810,976],[1235,976],[1235,604]],label:{s:'al',x:1249,y:790,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'url-request',pts:[[1140,894],[1140,1180],[375,1180],[375,1294]],label:{s:'al',x:389,y:1126,t:'Foundation mapping',rot:-90,anchor:'center'} },
  { from:'http-url',to:'foundation-url-data',pts:[[335,604],[335,700],[765,700],[765,1294]],label:{s:'al',x:779,y:942,t:'URL value',rot:-90,anchor:'center'} },
  { from:'request',to:'foundation-url-data',pts:[[935,604],[935,720],[765,720],[765,1294]],label:{s:'al',x:949,y:662,t:'body Data',rot:-90,anchor:'center'} },
  { from:'response',to:'foundation-url-data',pts:[[1235,604],[1235,740],[765,740],[765,1294]],label:{s:'al',x:1249,y:672,t:'body Data',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:160,y:86,t:'RivetHTTPClient — 最小介面結構'},
  {s:'sub',x:160,y:118,t:'已實作 HTTPURL → HTTPRequest → HTTPClient → Requester → injected Transport → HTTPResponse；不含 Endpoint 或 URLSession 實作'},
  {s:'tag',x:160,y:146,runs:[{t:'HTTPURL',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'HTTPRequest',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'HTTPClient',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'Requester',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'Transport',fill:planeColor('transport')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的 abstraction'},
  {s:'legend',x:1082,y:110,t:'實線 — 呼叫端、Foundation 或外部 surface'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:160,y:1530,t:'不變量：Endpoint、Base URL、Path 與 Query 由呼叫端／domain layer 組裝，不是 package API'},
  {s:'bn',x:160,y:1550,t:'不變量：typed throws 只限 HTTPURL validation；Transport error 維持一般 async throws 並原樣傳遞'},
  {s:'bn',x:160,y:1570,t:'延後：URLSessionTransport、網路呼叫、status validation、retry、token refresh 與 decode policy'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['caller','client','contracts','transport','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
