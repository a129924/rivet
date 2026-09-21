const W = 1480, H = 1110;

// 此圖只表達套件所有權與編譯期依賴，不描述 Transport 的執行期請求／回應流程。
const PLANES = {
  caller:     { c: '#F6821F', label: '呼叫端 API 領域' },
  client:     { c: '#A78BFA', label: 'HTTP 用戶端抽象' },
  contracts:  { c: '#22D3EE', label: 'HTTP 合約' },
  transport:  { c: '#4ADE80', label: 'Transport 邊界' },
  outside:    { c: '#94A3B8', label: '外部' }
};

const BANDS = [
  { id:'band-caller', plane:'caller', x:110, y:185, w:1260, h:120, alpha:0.48,
    hdr:{x:140,y:215,t:'呼叫端／領域層'}, tagr:{x:1340,y:215,t:'不屬於 RivetHTTPClient',alpha:0.6} },
  { id:'band-contracts', plane:'contracts', x:110, y:325, w:1260, h:220, alpha:0.5, dash:true,
    hdr:{x:140,y:355,t:'RivetHTTPClient — HTTP 合約'}, tagr:{x:1340,y:355,t:'已實作最小介面',alpha:0.6} },
  { id:'band-client', plane:'client', x:110, y:565, w:1260, h:140, alpha:0.5, dash:true,
    hdr:{x:140,y:595,t:'用戶端抽象'}, tagr:{x:1340,y:595,t:'已實作 · 型別化失敗',alpha:0.6} },
  { id:'band-transport', plane:'transport', x:110, y:725, w:1260, h:135, alpha:0.5, dash:true,
    hdr:{x:140,y:755,t:'TRANSPORT 邊界'}, tagr:{x:1340,y:755,t:'注入式合約',alpha:0.6} },
  { id:'band-outside', plane:'outside', x:110, y:880, w:1260, h:135, alpha:0.48,
    hdr:{x:140,y:910,t:'外部 — FOUNDATION 表層'}, tagr:{x:1340,y:910,t:'非 Rivet 所有',alpha:0.6} }
];

const BOXES = [
  { id:'application-caller', plane:'caller', band:'band-caller', x:160,y:232,w:1160,h:68,r:10,
    name:'應用程式／轉接器呼叫端',about:'呼叫端以通用 HTTPClient.Configuration 設定 base URL、headers 與 timeout；不引入端點策略。',
    texts:[['bl',184,260,'應用程式／轉接器呼叫端'],['bs',184,282,'設定 Configuration；發送絕對 URL 或相對路徑']] },
  { id:'http-url', plane:'contracts', band:'band-contracts', x:140,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPURL',about:'套件擁有的值物件；只接受有 host 的 http 或 https URL，並承接用戶端已驗證的 URL。',
    texts:[['bl',164,413,'HTTPURL'],['bs',164,435,'http／https + 主機'],['bn',164,457,'用戶端 URL 驗證以 typed throws 回報']] },
  { id:'url-error', plane:'contracts', band:'band-contracts', x:423,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPURLValidationError',about:'區分 URL、設定與相對路徑驗證的套件擁有錯誤。',
    texts:[['bl',447,413,'HTTPURLValidationError'],['bs',447,435,'URL／設定／路徑驗證'],['bn',447,457,'不混入 Transport 失敗']] },
  { id:'request', plane:'contracts', band:'band-contracts', x:706,y:385,w:262,h:88,r:10,dash:true,
    name:'HTTPRequest',about:'只持有已驗證 HTTPURL、method、headers 與可選 body。',
    texts:[['bl',730,413,'HTTPRequest'],['bs',730,435,'HTTPURL · method · headers'],['bn',730,457,'body: Data?；不以 throws 回報']] },
  { id:'response', plane:'contracts', band:'band-contracts', x:989,y:385,w:330,h:88,r:10,dash:true,
    name:'HTTPResponse',about:'Transport 未經 status 或解碼政策處理的原始回應合約。',
    texts:[['bl',1013,413,'HTTPResponse'],['bs',1013,435,'status · headers · body'],['bn',1013,457,'原始回傳值']] },
  { id:'auth', plane:'contracts', band:'band-contracts', x:140,y:495,w:262,h:42,r:10,dash:true,
    name:'Auth',about:'現行 makeFlow(for:) 是既有模型 A；採用的模型 C 則提供策略與獨立流程，確切工廠 API 尚未鎖定。',
    texts:[['bs',164,522,'Auth — 既有模型 A／模型 C 目標架構']] },
  { id:'auth-flow', plane:'contracts', band:'band-contracts', x:423,y:495,w:262,h:42,r:10,dash:true,
    name:'AuthFlow',about:'現行 .send(HTTPRequest) 能力是既有模型 A；採用的模型 C 只擁有認證策略／狀態與重試決策。',
    texts:[['bs',447,522,'AuthFlow — 目標策略／狀態']] },
  { id:'method-headers', plane:'contracts', band:'band-contracts', x:706,y:495,w:613,h:42,r:10,dash:true,
    name:'HTTPMethod 與 HTTPHeaders',about:'HTTPRequest 使用的套件擁有 method 與 header 值型別。',
    texts:[['bs',730,522,'HTTPMethod 與 HTTPHeaders — 套件擁有的請求中繼資料']] },
  { id:'http-client', plane:'client', band:'band-client', x:140,y:620,w:360,h:68,r:10,dash:true,
    name:'HTTPClient／Configuration',about:'公開通用 HTTP 介面；Configuration 合成相對路徑、合併 headers 並設定 timeout，所有介面經 execute 委派。',
    texts:[['bl',164,648,'HTTPClient／Configuration'],['bs',164,670,'絕對 URL／相對路徑 → execute(_:)']] },
  { id:'auth-requester', plane:'client', band:'band-client', x:540,y:620,w:360,h:68,r:10,dash:true,
    name:'AuthRequester',about:'現行驅動迴圈是既有模型 A；採用的模型 C 中它只保有呼叫端原始請求並解讀語意決策。選定／修飾後請求的準備者與表徵均延後確定；它不負責準備該請求。',
    texts:[['bl',564,648,'AuthRequester'],['bs',564,670,'目標：保有原始請求；解讀語意決策']] },
  { id:'requester', plane:'client', band:'band-client', x:940,y:620,w:379,h:68,r:10,dash:true,
    name:'Requester',about:'把已驗證 HTTPRequest 映射為 Foundation URLRequest；不重驗 URL。',
    texts:[['bl',964,648,'Requester'],['bs',964,670,'HTTPRequest → URLRequest']] },
  { id:'transport', plane:'transport', band:'band-transport', x:140,y:780,w:1179,h:68,r:10,dash:true,
    name:'Transport／URLSessionTransport',about:'注入式 typed-throws 合約與套件擁有的正式 URLSession Transport。',
    texts:[['bl',164,808,'Transport／URLSessionTransport'],['bs',164,830,'HTTPClientError；raw HTTP status']] },
  { id:'url-request', plane:'outside', band:'band-outside', x:140,y:935,w:350,h:68,r:10,
    name:'Foundation URLRequest',about:'Requester 實際映射到的 Foundation 請求表層。',
    texts:[['bl',164,963,'Foundation URLRequest'],['bs',164,985,'Requester 的輸出表層']] },
  { id:'foundation-url-data', plane:'outside', band:'band-outside', x:530,y:935,w:350,h:68,r:10,
    name:'Foundation URL／Data',about:'HTTPURL 值與請求／回應 body 直接使用的 Foundation 型別。',
    texts:[['bl',554,963,'Foundation URL／Data'],['bs',554,985,'值與 body 的直接依賴']] },
  { id:'urlsession', plane:'outside', band:'band-outside', x:920,y:935,w:399,h:68,r:10,
    name:'Foundation URLSession',about:'URLSessionTransport 採用的外部網路表層。',
    texts:[['bl',944,963,'Foundation URLSession'],['bs',944,985,'由套件擁有的 Transport 採用']] }
];

const EDGES = [
  { from:'application-caller',to:'http-client',pts:[[740,306],[740,580],[320,580],[320,614]],label:{s:'al',x:338,y:560,t:'設定並呼叫',rot:-90,anchor:'center'} },
  { from:'http-url',to:'url-error',pts:[[407,429],[417,429]],label:{s:'al',x:412,y:417,t:'型別化錯誤',anchor:'center'} },
  { from:'request',to:'http-url',pts:[[837,479],[837,482],[271,482],[271,479]],label:{s:'al',x:554,y:480,t:'依賴',anchor:'center'} },
  { from:'request',to:'method-headers',pts:[[973,429],[978,429],[978,516],[963,516]],label:{s:'al',x:971,y:466,t:'依賴',rot:-90,anchor:'center'} },
  { from:'auth',to:'auth-flow',pts:[[407,516],[417,516]],label:{s:'al',x:412,y:504,t:'建立',anchor:'center'} },
  { from:'http-client',to:'requester',pts:[[505,640],[925,640],[925,642],[934,642]],label:{s:'al',x:722,y:628,t:'設定後執行',anchor:'center'} },
  { from:'auth-requester',to:'auth',pts:[[650,614],[650,575],[271,575],[271,543]],label:{s:'al',x:668,y:580,t:'依賴',rot:-90,anchor:'center'} },
  // 此相依只表達泛用 I/O 委派，不表示 AuthRequester 準備選定／修飾後請求。
  { from:'auth-requester',to:'requester',pts:[[720,694],[720,714],[1129,714],[1129,694]],label:{s:'al',x:924,y:706,t:'泛用 I/O 委派；非請求準備',anchor:'center'} },
  { from:'auth-requester',to:'auth-flow',pts:[[720,614],[720,555],[554,555],[554,543]],label:{s:'al',x:737,y:580,t:'回應／語意決策',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'response',pts:[[860,614],[860,600],[1154,600],[1154,479]],label:{s:'al',x:1007,y:588,t:'策略輸入',anchor:'center'} },
  { from:'http-client',to:'request',pts:[[320,614],[320,555],[837,555],[837,479]],label:{s:'al',x:854,y:568,t:'建立',rot:-90,anchor:'center'} },
  { from:'http-client',to:'response',pts:[[360,614],[360,557],[1154,557],[1154,479]],label:{s:'al',x:1171,y:568,t:'回傳型別',rot:-90,anchor:'center'} },
  { from:'requester',to:'request',pts:[[1075,614],[1075,550],[837,550],[837,479]],label:{s:'al',x:1092,y:575,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'response',pts:[[1244,614],[1244,550],[1154,550],[1154,479]],label:{s:'al',x:1261,y:575,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'transport',pts:[[1129,694],[1129,770],[730,770],[730,774]],label:{s:'al',x:747,y:735,t:'注入依賴',rot:-90,anchor:'center'} },
  { from:'transport',to:'response',pts:[[730,774],[730,715],[1154,715],[1154,479]],label:{s:'al',x:1171,y:652,t:'依賴',rot:-90,anchor:'center'} },
  { from:'requester',to:'url-request',pts:[[1129,694],[1129,870],[315,870],[315,929]],label:{s:'al',x:332,y:841,t:'Foundation 對映',rot:-90,anchor:'center'} },
  { from:'transport',to:'url-request',pts:[[315,854],[315,929]],label:{s:'al',x:332,y:891,t:'依賴',rot:-90,anchor:'center'} },
  { from:'http-url',to:'foundation-url-data',pts:[[271,479],[271,557],[705,557],[705,929]],label:{s:'al',x:722,y:727,t:'URL 值',rot:-90,anchor:'center'} },
  { from:'request',to:'foundation-url-data',pts:[[837,479],[837,562],[705,562],[705,929]],label:{s:'al',x:854,y:538,t:'body Data',rot:-90,anchor:'center'} },
  { from:'response',to:'foundation-url-data',pts:[[1154,479],[1154,567],[705,567],[705,929]],label:{s:'al',x:1171,y:538,t:'body Data',rot:-90,anchor:'center'} },
  { from:'transport',to:'urlsession',pts:[[1120,854],[1120,870],[1120,929]],label:{s:'al',x:1137,y:892,t:'正式執行',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:110,y:86,t:'RivetHTTPClient — 設定式介面結構'},
  {s:'sub',x:110,y:118,t:'Configuration → URL 驗證／合成 → 原始執行；Auth 區塊標示既有模型 A 與已採用、尚未實作的模型 C'},
  {s:'tag',x:110,y:146,runs:[{t:'Configuration',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'HTTPURL',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'HTTPRequest',fill:planeColor('contracts')},{t:' → ',fill:'#4A5462'},{t:'Requester',fill:planeColor('client')},{t:' → ',fill:'#4A5462'},{t:'Transport',fill:planeColor('transport')}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的抽象'},
  {s:'legend',x:1082,y:110,t:'實線 — 呼叫端、Foundation 或外部表層'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬的責任層'},
  {s:'bn',x:110,y:1040,t:'不變量：Configuration 提供通用 base URL／相對路徑便利功能，不是端點或查詢建構器'},
  {s:'bn',x:110,y:1060,t:'不變量：HTTPURL 驗證與 HTTPClientError 分別表達設定／URL／路徑驗證、Transport 失敗；HTTP status 維持原始回應'},
  {s:'bn',x:110,y:1080,t:'Auth 歷史／目標架構：現行 `.send(HTTPRequest)` 是既有模型 A；模型 C 分離策略／狀態、呼叫端原始請求與 I/O，經選擇／修飾請求的準備責任維持延後確定'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['caller','client','contracts','transport','outside'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
