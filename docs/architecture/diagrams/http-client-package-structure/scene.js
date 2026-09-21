const W = 1480, H = 1240;

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
  { id:'band-contracts', plane:'contracts', x:110, y:325, w:1260, h:320, alpha:0.5, dash:true,
    hdr:{x:140,y:355,t:'RIVETHTTPCLIENT — HTTP CONTRACTS'}, tagr:{x:1340,y:355,t:'已實作最小介面',alpha:0.6} },
  { id:'band-client', plane:'client', x:110, y:665, w:1260, h:140, alpha:0.5, dash:true,
    hdr:{x:140,y:695,t:'CLIENT ABSTRACTIONS'}, tagr:{x:1340,y:695,t:'已實作 · typed failures',alpha:0.6} },
  { id:'band-transport', plane:'transport', x:110, y:825, w:1260, h:135, alpha:0.5, dash:true,
    hdr:{x:140,y:855,t:'TRANSPORT BOUNDARY'}, tagr:{x:1340,y:855,t:'注入式 contract',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:110, y:980, w:1260, h:135, alpha:0.48,
    hdr:{x:140,y:1010,t:'OUTSIDE — FOUNDATION SURFACE'}, tagr:{x:1340,y:1010,t:'非 RIVET 所有',alpha:0.6} }
];

const BOXES = [
  { id:'application-caller', plane:'caller', band:'band-caller', x:160,y:232,w:1160,h:68,r:10,
    name:'Application／Adapter caller',about:'呼叫端以 generic HTTPClient.Configuration 設定 base URL、headers 與 timeout；不引入 endpoint policy。',
    texts:[['bl',184,260,'Application／Adapter caller'],['bs',184,282,'設定 Configuration；發送 absolute URL 或 relative path']] },
  { id:'http-url', plane:'contracts', band:'band-contracts', x:140,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPURL',about:'package-owned value object；只接受有 host 的 http 或 https URL，並承接 client 已驗證的 URL。',
    texts:[['bl',164,413,'HTTPURL'],['bs',164,435,'http／https + host'],['bn',164,457,'client URL validation typed throws']] },
  { id:'url-error', plane:'contracts', band:'band-contracts', x:423,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPURLValidationError',about:'區分 URL、configuration 與 relative path validation 的 package-owned error。',
    texts:[['bl',447,413,'HTTPURLValidationError'],['bs',447,435,'URL／configuration／path validation'],['bn',447,457,'不混入 transport failure']] },
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
  { id:'request-authorization', plane:'contracts', band:'band-contracts', x:140,y:558,w:545,h:58,r:10,dash:true,
    name:'RequestAuthorization',about:'caller 在 bare execution 前同步套用的 HTTPRequest transformation；不傳送 request。',
    texts:[['bl',164,584,'RequestAuthorization'],['bs',164,604,'同步呼叫端套用的轉換']] },
  { id:'async-request-authorization', plane:'contracts', band:'band-contracts', x:706,y:558,w:613,h:58,r:10,dash:true,
    name:'AsyncRequestAuthorization',about:'caller 在 bare execution 前非同步套用的 HTTPRequest transformation；一般 error 原樣交回 caller。',
    texts:[['bl',730,584,'AsyncRequestAuthorization'],['bs',730,604,'非同步 throws 呼叫端套用的轉換']] },
  { id:'http-client', plane:'client', band:'band-client', x:140,y:720,w:360,h:68,r:10,dash:true,
    name:'HTTPClient／Configuration',about:'公開 generic HTTP facade；configuration 合成 relative path、合併 headers 並設定 timeout，所有 facade 經 execute 委派。',
    texts:[['bl',164,748,'HTTPClient／Configuration'],['bs',164,770,'absolute URL／relative path → execute(_:)']] },
  { id:'auth-requester', plane:'client', band:'band-client', x:540,y:720,w:360,h:68,r:10,dash:true,
    name:'AuthRequester',about:'internal decorator；注入 Requester 與 Auth，generic 地驅動 AuthFlow。',
    texts:[['bl',564,748,'AuthRequester'],['bs',564,770,'internal：Requester + Auth']] },
  { id:'requester', plane:'client', band:'band-client', x:940,y:720,w:379,h:68,r:10,dash:true,
    name:'Requester',about:'把已驗證 HTTPRequest 映射為 Foundation URLRequest；不重驗 URL。',
    texts:[['bl',964,748,'Requester'],['bs',964,770,'HTTPRequest → URLRequest']] },
  { id:'transport', plane:'transport', band:'band-transport', x:140,y:880,w:1179,h:68,r:10,dash:true,
    name:'Transport／URLSessionTransport',about:'注入式 typed-throws contract 與 package-owned production URLSession transport。',
    texts:[['bl',164,908,'Transport／URLSessionTransport'],['bs',164,930,'HTTPClientError；raw HTTP status']] },
  { id:'url-request', plane:'outside', band:'band-outside', x:140,y:1035,w:350,h:68,r:10,
    name:'Foundation URLRequest',about:'Requester 實際映射到的 Foundation request surface。',
    texts:[['bl',164,1063,'Foundation URLRequest'],['bs',164,1085,'Requester 的輸出 surface']] },
  { id:'foundation-url-data', plane:'outside', band:'band-outside', x:530,y:1035,w:350,h:68,r:10,
    name:'Foundation URL／Data',about:'HTTPURL value 與 request／response body 直接使用的 Foundation types。',
    texts:[['bl',554,1063,'Foundation URL／Data'],['bs',554,1085,'value 與 body 的直接依賴']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:920,y:1035,w:399,h:68,r:10,
    name:'Foundation URLSession',about:'URLSessionTransport 採用的 Outside networking surface。',
    texts:[['bl',944,1063,'Foundation URLSession'],['bs',944,1085,'由 package-owned transport 採用']] }
];

const EDGES = [
  { from:'application-caller',to:'http-client',pts:[[740,306],[740,680],[320,680],[320,714]],label:{s:'al',x:338,y:660,t:'設定並呼叫',rot:-90,anchor:'center'} },
  { from:'http-url',to:'url-error',pts:[[407,429],[417,429]],label:{s:'al',x:412,y:417,t:'typed error',anchor:'center'} },
  { from:'request',to:'http-url',pts:[[837,479],[837,482],[271,482],[271,479]],label:{s:'al',x:554,y:480,t:'依賴',anchor:'center'} },
  { from:'request',to:'method-headers',pts:[[973,429],[978,429],[978,516],[963,516]],label:{s:'al',x:971,y:466,t:'依賴',rot:-90,anchor:'center'} },
  { from:'auth',to:'auth-flow',pts:[[407,516],[417,516]],label:{s:'al',x:412,y:504,t:'建立',anchor:'center'} },
  { from:'request-authorization',to:'request',pts:[[685,587],[695,587],[695,480],[700,480],[700,429]] },
  { from:'async-request-authorization',to:'request',pts:[[1324,587],[1340,587],[1340,480],[974,480],[974,429]] },
  { from:'http-client',to:'requester',pts:[[505,740],[925,740],[925,742],[934,742]],label:{s:'al',x:722,y:728,t:'configured execute',anchor:'center'} },
  { from:'auth-requester',to:'auth',pts:[[650,714],[650,655],[271,655],[271,543]],label:{s:'al',x:668,y:660,t:'依賴',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'requester',pts:[[905,770],[925,770],[925,766],[934,766]],label:{s:'al',x:915,y:790,t:'injected',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'auth-flow',pts:[[720,714],[720,655],[554,655],[554,543]],label:{s:'al',x:737,y:660,t:'驅動',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'request',pts:[[780,714],[780,680],[837,680],[837,479]],label:{s:'al',x:800,y:668,t:'依賴',anchor:'center'} },
  { from:'auth-requester',to:'response',pts:[[860,714],[860,700],[1154,700],[1154,479]],label:{s:'al',x:1007,y:688,t:'依賴',anchor:'center'} },
  { from:'http-client',to:'request',pts:[[320,714],[320,655],[837,655],[837,479]],label:{s:'al',x:854,y:668,t:'建立',rot:-90,anchor:'center'} },
  { from:'http-client',to:'response',pts:[[360,714],[360,657],[1154,657],[1154,479]],label:{s:'al',x:1171,y:668,t:'回傳型別',rot:-90,anchor:'center'} },
  { from:'requester',to:'request',pts:[[1075,714],[1075,650],[837,650],[837,479]],label:{s:'al',x:1092,y:675,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'response',pts:[[1244,714],[1244,650],[1154,650],[1154,479]],label:{s:'al',x:1261,y:675,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'transport',pts:[[1129,794],[1129,870],[730,870],[730,874]],label:{s:'al',x:747,y:835,t:'注入依賴',rot:-90,anchor:'center'} },
  { from:'transport',to:'response',pts:[[730,874],[730,815],[1154,815],[1154,479]],label:{s:'al',x:1171,y:752,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'url-request',pts:[[1129,794],[1129,970],[315,970],[315,1029]],label:{s:'al',x:332,y:941,t:'Foundation mapping',rot:-90,anchor:'center'} },
  { from:'transport',to:'url-request',pts:[[315,954],[315,1029]],label:{s:'al',x:332,y:991,t:'依賴',rot:-90,anchor:'center'} },
  { from:'http-url',to:'foundation-url-data',pts:[[271,479],[271,657],[705,657],[705,1029]],label:{s:'al',x:722,y:827,t:'URL value',rot:-90,anchor:'center'} },
  { from:'request',to:'foundation-url-data',pts:[[837,479],[837,662],[705,662],[705,1029]],label:{s:'al',x:854,y:638,t:'body Data',rot:-90,anchor:'center'} },
  { from:'response',to:'foundation-url-data',pts:[[1154,479],[1154,667],[705,667],[705,1029]],label:{s:'al',x:1171,y:638,t:'body Data',rot:-90,anchor:'center'} },
  { from:'transport',to:'urlsession',pts:[[1120,954],[1120,970],[1120,1029]],label:{s:'al',x:1137,y:992,t:'production execution',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:110,y:86,t:'RivetHTTPClient — 設定式介面結構'},
  {s:'sub',x:110,y:118,t:'呼叫端套用的同步／非同步請求授權轉換 → bare execution；internal AuthRequester 注入 Requester 與 Auth'},
  {s:'tag',x:110,y:146,runs:[{t:'RequestAuthorization／AsyncRequestAuthorization',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'HTTPRequest',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'Requester',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'Transport',fill:planeColor('transport')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的 abstraction'},
  {s:'legend',x:1082,y:110,t:'實線 — 呼叫端、Foundation 或外部 surface'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任 plane'},
  {s:'bn',x:110,y:1140,t:'不變量：Configuration 提供 generic base URL／relative path convenience，不是 Endpoint 或 Query builder'},
  {s:'bn',x:110,y:1160,t:'不變量：HTTPURL validation 與 HTTPClientError 分別表達 configuration／URL／path validation、transport failure；HTTP status 維持 raw response'},
  {s:'bn',x:110,y:1180,t:'不變量：sync／async authorization 都由 caller 套用 HTTPRequest；async 一般 error 原樣交回 caller，不參與 execution'},
  {s:'bn',x:110,y:1200,t:'延後：Endpoint、status／Content-Type validation、retry、token refresh 與 package-owned decoder'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['caller','client','contracts','transport','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
