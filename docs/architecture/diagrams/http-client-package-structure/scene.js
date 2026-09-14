const W = 1480, H = 1110;

// 此圖只表達 package ownership 與編譯期依賴，不描述 transport 的執行期 request／response flow。
const PLANES = {
  caller:     { c: '#F6821F', label: '呼叫端 API domain' },
  client:     { c: '#A78BFA', label: 'HTTP client abstraction' },
  contracts:  { c: '#22D3EE', label: 'HTTP contracts' },
  transport:  { c: '#4ADE80', label: 'Transport boundary' },
  outside:    { c: '#94A3B8', label: 'Outside' }
};

const BANDS = [
  { id:'band-caller', plane:'caller', x:110, y:185, w:1260, h:120, alpha:0.48,
    hdr:{x:140,y:215,t:'CALLER／DOMAIN LAYER'}, tagr:{x:1340,y:215,t:'不屬於 RIVETHTTPCLIENT',alpha:0.6} },
  { id:'band-contracts', plane:'contracts', x:110, y:325, w:1260, h:220, alpha:0.5, dash:true,
    hdr:{x:140,y:355,t:'RIVETHTTPCLIENT — HTTP CONTRACTS'}, tagr:{x:1340,y:355,t:'已實作最小介面',alpha:0.6} },
  { id:'band-client', plane:'client', x:110, y:565, w:1260, h:140, alpha:0.5, dash:true,
    hdr:{x:140,y:595,t:'CLIENT ABSTRACTIONS'}, tagr:{x:1340,y:595,t:'已實作 · typed failures',alpha:0.6} },
  { id:'band-transport', plane:'transport', x:110, y:725, w:1260, h:135, alpha:0.5, dash:true,
    hdr:{x:140,y:755,t:'TRANSPORT BOUNDARY'}, tagr:{x:1340,y:755,t:'注入式 contract',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:110, y:880, w:1260, h:135, alpha:0.48,
    hdr:{x:140,y:910,t:'OUTSIDE — FOUNDATION SURFACE'}, tagr:{x:1340,y:910,t:'非 RIVET 所有',alpha:0.6} }
];

const BOXES = [
  { id:'endpoint-domain', plane:'caller', band:'band-caller', x:160,y:232,w:1160,h:68,r:10,
    name:'Endpoint／Base URL／Path／Query',about:'呼叫端或 domain layer 組裝 API URL；package 不提供此 API。',
    texts:[['bl',184,260,'Endpoint／Base URL／Path／Query'],['bs',184,282,'呼叫端組裝；再建立 HTTPURL']] },
  { id:'http-url', plane:'contracts', band:'band-contracts', x:140,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPURL',about:'package-owned value object；只接受有 host 的 http 或 https URL。',
    texts:[['bl',164,413,'HTTPURL'],['bs',164,435,'http／https + host'],['bn',164,457,'URL construction typed throws']] },
  { id:'url-error', plane:'contracts', band:'band-contracts', x:423,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPURLValidationError',about:'HTTPURL construction 的封閉 validation error。',
    texts:[['bl',447,413,'HTTPURLValidationError'],['bs',447,435,'scheme 或 host validation'],['bn',447,457,'package-owned error']] },
  { id:'request', plane:'contracts', band:'band-contracts', x:706,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPRequest',about:'只持有已驗證 HTTPURL、method、headers 與 optional body。',
    texts:[['bl',730,413,'HTTPRequest'],['bs',730,435,'HTTPURL · method · headers'],['bn',730,457,'body: Data?；不 throws']] },
  { id:'response', plane:'contracts', band:'band-contracts', x:989,y:385,w:330,h:88,r:10,dash:true,
    name:'HTTPResponse',about:'Transport 未經 status 或 decode policy 處理的 raw response contract。',
    texts:[['bl',1013,413,'HTTPResponse'],['bs',1013,435,'status · headers · body'],['bn',1013,457,'raw return value']] },
  { id:'auth', plane:'contracts', band:'band-contracts', x:140,y:495,w:262,h:42,r:10,dash:true,
    name:'Auth',about:'caller opt-in 的 flow factory；不擁有 credential 或認證 policy。',
    texts:[['bs',164,522,'Auth — makeFlow(for:)']] },
  { id:'auth-flow', plane:'contracts', band:'band-contracts', x:423,y:495,w:262,h:42,r:10,dash:true,
    name:'AuthFlow',about:'擁有認證決策，從 start 與 receive 產出 send 或 finish action。',
    texts:[['bs',447,522,'AuthFlow — start／receive']] },
  { id:'method-headers', plane:'contracts', band:'band-contracts', x:706,y:495,w:613,h:42,r:10,dash:true,
    name:'HTTPMethod 與 HTTPHeaders',about:'HTTPRequest 使用的 package-owned method 與 header value types。',
    texts:[['bs',730,522,'HTTPMethod 與 HTTPHeaders — package-owned request metadata']] },
  { id:'http-client', plane:'client', band:'band-client', x:140,y:620,w:360,h:68,r:10,dash:true,
    name:'HTTPClient',about:'公開 bare HTTP facade；所有 method facade 經 execute 委派給 Requester。',
    texts:[['bl',164,648,'HTTPClient'],['bs',164,670,'bare facade → execute(_:)']] },
  { id:'auth-requester', plane:'client', band:'band-client', x:540,y:620,w:360,h:68,r:10,dash:true,
    name:'AuthRequester',about:'internal decorator；注入 Requester 與 Auth，generic 地驅動 AuthFlow。',
    texts:[['bl',564,648,'AuthRequester'],['bs',564,670,'internal：Requester + Auth']] },
  { id:'requester', plane:'client', band:'band-client', x:940,y:620,w:379,h:68,r:10,dash:true,
    name:'Requester',about:'把已驗證 HTTPRequest 映射為 Foundation URLRequest；不重驗 URL。',
    texts:[['bl',964,648,'Requester'],['bs',964,670,'HTTPRequest → URLRequest']] },
  { id:'transport', plane:'transport', band:'band-transport', x:140,y:780,w:1179,h:68,r:10,dash:true,
    name:'Transport／URLSessionTransport',about:'注入式 typed-throws contract 與 package-owned production URLSession transport。',
    texts:[['bl',164,808,'Transport／URLSessionTransport'],['bs',164,830,'HTTPClientError；raw HTTP status']] },
  { id:'url-request', plane:'outside', band:'band-outside', x:140,y:935,w:350,h:68,r:10,
    name:'Foundation URLRequest',about:'Requester 實際映射到的 Foundation request surface。',
    texts:[['bl',164,963,'Foundation URLRequest'],['bs',164,985,'Requester 的輸出 surface']] },
  { id:'foundation-url-data', plane:'outside', band:'band-outside', x:530,y:935,w:350,h:68,r:10,
    name:'Foundation URL／Data',about:'HTTPURL value 與 request／response body 直接使用的 Foundation types。',
    texts:[['bl',554,963,'Foundation URL／Data'],['bs',554,985,'value 與 body 的直接依賴']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:920,y:935,w:399,h:68,r:10,
    name:'Foundation URLSession',about:'URLSessionTransport 採用的 Outside networking surface。',
    texts:[['bl',944,963,'Foundation URLSession'],['bs',944,985,'由 package-owned transport 採用']] }
];

const EDGES = [
  { from:'endpoint-domain',to:'http-url',pts:[[740,306],[740,315],[271,315],[271,379]],label:{s:'al',x:289,y:337,t:'建立',rot:-90,anchor:'center'} },
  { from:'http-url',to:'url-error',pts:[[407,429],[417,429]],label:{s:'al',x:412,y:417,t:'typed error',anchor:'center'} },
  { from:'request',to:'http-url',pts:[[837,479],[837,482],[271,482],[271,479]],label:{s:'al',x:554,y:480,t:'依賴',anchor:'center'} },
  { from:'request',to:'method-headers',pts:[[973,429],[978,429],[978,516],[963,516]],label:{s:'al',x:971,y:466,t:'依賴',rot:-90,anchor:'center'} },
  { from:'auth',to:'auth-flow',pts:[[407,516],[417,516]],label:{s:'al',x:412,y:504,t:'建立',anchor:'center'} },
  { from:'http-client',to:'requester',pts:[[505,640],[925,640],[925,642],[934,642]],label:{s:'al',x:722,y:628,t:'bare execute',anchor:'center'} },
  { from:'auth-requester',to:'requester',pts:[[905,670],[925,670],[925,666],[934,666]],label:{s:'al',x:915,y:690,t:'injected',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'auth-flow',pts:[[720,614],[720,555],[554,555],[554,543]],label:{s:'al',x:737,y:580,t:'驅動',rot:-90,anchor:'center'} },
  { from:'http-client',to:'request',pts:[[320,614],[320,555],[837,555],[837,479]],label:{s:'al',x:854,y:568,t:'使用',rot:-90,anchor:'center'} },
  { from:'http-client',to:'response',pts:[[360,614],[360,557],[1154,557],[1154,479]],label:{s:'al',x:1171,y:568,t:'回傳型別',rot:-90,anchor:'center'} },
  { from:'requester',to:'request',pts:[[1075,614],[1075,550],[837,550],[837,479]],label:{s:'al',x:1092,y:575,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'response',pts:[[1244,614],[1244,550],[1154,550],[1154,479]],label:{s:'al',x:1261,y:575,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'transport',pts:[[1129,694],[1129,770],[730,770],[730,774]],label:{s:'al',x:747,y:735,t:'注入依賴',rot:-90,anchor:'center'} },
  { from:'transport',to:'response',pts:[[730,774],[730,715],[1154,715],[1154,479]],label:{s:'al',x:1171,y:652,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'url-request',pts:[[1129,694],[1129,870],[315,870],[315,929]],label:{s:'al',x:332,y:841,t:'Foundation mapping',rot:-90,anchor:'center'} },
  { from:'transport',to:'url-request',pts:[[315,854],[315,929]],label:{s:'al',x:332,y:891,t:'依賴',rot:-90,anchor:'center'} },
  { from:'http-url',to:'foundation-url-data',pts:[[271,479],[271,557],[705,557],[705,929]],label:{s:'al',x:722,y:727,t:'URL value',rot:-90,anchor:'center'} },
  { from:'request',to:'foundation-url-data',pts:[[837,479],[837,562],[705,562],[705,929]],label:{s:'al',x:854,y:538,t:'body Data',rot:-90,anchor:'center'} },
  { from:'response',to:'foundation-url-data',pts:[[1154,479],[1154,567],[705,567],[705,929]],label:{s:'al',x:1171,y:538,t:'body Data',rot:-90,anchor:'center'} },
  { from:'transport',to:'urlsession',pts:[[1120,854],[1120,870],[1120,929]],label:{s:'al',x:1137,y:892,t:'production execution',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:110,y:86,t:'RivetHTTPClient — 最小介面結構'},
  {s:'sub',x:110,y:118,t:'bare HTTPClient → Requester；internal AuthRequester 驅動 AuthFlow → injected Requester → Transport → raw HTTPResponse'},
  {s:'tag',x:110,y:146,runs:[{t:'HTTPURL',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'HTTPRequest',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'Auth／AuthFlow',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'AuthRequester',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'Requester',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'Transport',fill:planeColor('transport')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的 abstraction'},
  {s:'legend',x:1082,y:110,t:'實線 — 呼叫端、Foundation 或外部 surface'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:110,y:1040,t:'不變量：Endpoint、Base URL、Path 與 Query 由呼叫端／domain layer 組裝，不是 package API'},
  {s:'bn',x:110,y:1060,t:'不變量：internal AuthRequester generic 地送出 flow action 並回灌 raw response；flow 保有認證決策，HTTP status 維持 raw response'},
  {s:'bn',x:110,y:1080,t:'延後：Endpoint、status／Content-Type validation、retry、token refresh 與 package-owned decoder'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['caller','client','contracts','transport','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
