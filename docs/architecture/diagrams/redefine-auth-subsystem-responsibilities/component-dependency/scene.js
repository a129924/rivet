const W = 1480, H = 1480;

// 此架構圖只表達已採用模型 C 的責任／依賴目標；它不是現行執行期序列。
// 虛線表示 Rivet 擁有的抽象；實線表示呼叫端、外部或待定邊界。
const PLANES = {
  caller: { c: '#94A3B8', label: '呼叫端' },
  coordination: { c: '#22D3EE', label: '協調與請求所有權' },
  policy: { c: '#A78BFA', label: '認證策略／狀態' },
  io: { c: '#4ADE80', label: '通用 HTTP 輸入／輸出' },
  deferred: { c: '#F6821F', label: '未來待定邊界' }
};

const BANDS = [
  { id:'band-caller', plane:'caller', x:110, y:185, w:1260, h:146, alpha:0.48,
    hdr:{x:140,y:215,t:'呼叫端'}, tagr:{x:1340,y:215,t:'交接前的原始請求所有者',alpha:0.6} },
  { id:'band-coordination', plane:'coordination', x:110, y:405, w:1260, h:182, alpha:0.5, dash:true,
    hdr:{x:140,y:435,t:'AuthRequester — 協調'}, tagr:{x:1340,y:435,t:'Rivet 所有 — 原始請求唯一所有者',alpha:0.6} },
  { id:'band-policy', plane:'policy', x:110, y:665, w:1260, h:220, alpha:0.5, dash:true,
    hdr:{x:140,y:695,t:'認證策略／狀態'}, tagr:{x:1340,y:695,t:'Rivet 所有 — 不建構請求、不執行輸入／輸出',alpha:0.6} },
  { id:'band-io', plane:'io', x:110, y:965, w:1260, h:182, alpha:0.5, dash:true,
    hdr:{x:140,y:995,t:'通用 HTTP 輸入／輸出'}, tagr:{x:1340,y:995,t:'Requester 是輸入／輸出所有者',alpha:0.6} },
  { id:'band-deferred', plane:'deferred', x:110, y:1225, w:1260, h:132, alpha:0.48,
    hdr:{x:140,y:1255,t:'待定的未來邊界'}, tagr:{x:1340,y:1255,t:'未定義型別／端點／程式介面',alpha:0.6} }
];

const BOXES = [
  { id:'caller', plane:'caller', band:'band-caller', x:180,y:240,w:1120,h:68,r:10,
    name:'呼叫端原始 HTTPRequest',about:'呼叫端交付原始請求；在目標架構中僅 AuthRequester 於執行生命週期內持有它。',
    texts:[['bl',204,268,'呼叫端原始 HTTPRequest'],['bs',204,290,'呼叫端意圖：URL · 方法 · 查詢 · 本體；不交給 AuthFlow']] },
  { id:'auth-requester', plane:'coordination', band:'band-coordination', x:180,y:466,w:774,h:86,r:10,dash:true,
    name:'AuthRequester',about:'只保有呼叫端原始請求並解讀流程的語意決策；選定／修飾請求的準備者與表徵均延後確定。',
    texts:[['bl',204,494,'AuthRequester'],['bs',204,516,'原始請求唯一所有者；語意解讀者'],['bn',204,538,'選定／修飾請求的準備者與表徵均延後確定']] },
  { id:'legacy-request-type', plane:'coordination', band:'band-coordination', x:978,y:466,w:322,h:86,r:10,dash:true,
    name:'legacy Model A HTTPRequest 型別',about:'只記錄 legacy Model A 的 AuthRequester 編譯期 request-type 相依；不表示 Model C 的請求準備、建構、所有權、資料流或輸入／輸出。',
    texts:[['bl',1002,494,'legacy Model A HTTPRequest 型別'],['bs',1002,516,'僅編譯期 request-type 相依'],['bn',1002,538,'非模型 C 準備／建構／所有權／輸入輸出']] },
  { id:'auth', plane:'policy', band:'band-policy', x:180,y:726,w:346,h:108,r:10,dash:true,
    name:'Auth',about:'提供認證策略與獨立流程，不擁有個別執行的狀態或輸入／輸出。',
    texts:[['bl',204,754,'Auth'],['bs',204,776,'認證策略／流程提供者'],['bs',204,792,'不持有原始請求或輸入／輸出'],['bn',204,814,'確切工廠簽章待定']] },
  { id:'auth-flow', plane:'policy', band:'band-policy', x:592,y:726,w:346,h:108,r:10,dash:true,
    name:'AuthFlow',about:'唯一擁有認證狀態、回應策略、更新資格、重試上限與終結決策。',
    texts:[['bl',616,754,'AuthFlow'],['bs',616,776,'認證策略／狀態機'],['bs',616,792,'讀取 HTTPResponse 語意；控制重試'],['bn',616,814,'不建構請求；不執行輸入／輸出']] },
  { id:'semantic-decision', plane:'policy', band:'band-policy', x:1004,y:726,w:296,h:108,r:10,dash:true,
    name:'語意決策',about:'流程的目標輸出只描述下一步語意，未鎖定列舉或請求裝飾表示法。',
    texts:[['bl',1028,754,'語意決策'],['bs',1028,776,'傳送／更新／結束等語意'],['bs',1028,792,'確切操作形狀待定'],['bn',1028,814,'不授予請求能力']] },
  { id:'requester', plane:'io', band:'band-io', x:180,y:1026,w:346,h:86,r:10,dash:true,
    name:'Requester',about:'唯一通用 HTTP 輸入／輸出所有者；接收選定 HTTPRequest 並回傳原始 HTTPResponse。',
    texts:[['bl',204,1054,'Requester'],['bs',204,1076,'HTTPRequest → 原始 HTTPResponse'],['bn',204,1098,'不認識認證策略或重試']] },
  { id:'transport', plane:'io', band:'band-io', x:592,y:1026,w:346,h:86,r:10,dash:true,
    name:'Transport',about:'套件所有的 HTTP 執行邊界；Requester 將選定請求委派給 Transport。',
    texts:[['bl',616,1054,'Transport'],['bs',616,1076,'執行 HTTP 輸入／輸出'],['bn',616,1098,'不擁有認證語意']] },
  { id:'raw-response', plane:'io', band:'band-io', x:1004,y:1026,w:296,h:86,r:10,dash:true,
    name:'原始 HTTPResponse',about:'所有 HTTP 狀態原樣回傳；AuthFlow 只將它當作策略輸入。',
    texts:[['bl',1028,1054,'原始 HTTPResponse'],['bs',1028,1076,'401 等回應語意'],['bn',1028,1098,'不在輸入／輸出邊界重訂策略']] },
  { id:'refresh-boundary', plane:'deferred', band:'band-deferred', x:280,y:1280,w:920,h:56,r:10,
    name:'待定的憑證更新輸入／輸出邊界',about:'僅後續具體消費端主題才可鎖定的憑證更新機制；本主題不命名型別、端點、憑證程式介面或結果契約。',
    texts:[['bl',304,1308,'待定的憑證更新輸入／輸出邊界'],['bs',304,1328,'僅限後續具體消費端主題；AuthRequester 派送語意上的憑證更新，不由 AuthFlow 直接呼叫']] }
];

const EDGES = [
  { from:'caller',to:'auth-requester',pts:[[740,314],[740,390],[445,390],[445,460]],label:{s:'al',x:462,y:370,t:'交付原始請求',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'auth',pts:[[330,558],[330,710],[353,710],[353,720]],label:{s:'al',x:370,y:634,t:'取得策略／流程',rot:-90,anchor:'center'} },
  { from:'auth',to:'auth-flow',pts:[[532,780],[586,780]],label:{s:'al',x:559,y:768,t:'獨立流程',anchor:'center'} },
  { from:'auth-requester',to:'auth-flow',pts:[[500,558],[500,672],[765,672],[765,720]],label:{s:'al',x:782,y:644,t:'回應輸入',rot:-90,anchor:'center'} },
  { from:'auth-flow',to:'semantic-decision',pts:[[944,780],[998,780]],label:{s:'al',x:971,y:768,t:'輸出語意',anchor:'center'} },
  { from:'semantic-decision',to:'auth-requester',pts:[[1152,840],[1152,910],[92,910],[92,509],[174,509]],label:{s:'al',x:76,y:708,t:'AuthRequester 解讀決策',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'legacy-request-type',pts:[[960,509],[972,509]] },
  { from:'auth-requester',to:'requester',pts:[[174,540],[64,540],[64,940],[353,940],[353,1020]],label:{s:'al',x:48,y:740,t:'泛用 I/O 委派；非請求準備',rot:-90,anchor:'center'} },
  { from:'requester',to:'transport',pts:[[532,1069],[586,1069]],label:{s:'al',x:559,y:1057,t:'委派輸入／輸出',anchor:'center'} },
  { from:'transport',to:'raw-response',pts:[[944,1069],[998,1069]],label:{s:'al',x:971,y:1057,t:'原始回應',anchor:'center'} },
  { from:'raw-response',to:'auth-requester',pts:[[1152,1020],[1152,930],[1360,930],[1360,509],[1306,509]],label:{s:'al',x:1376,y:720,t:'回傳策略輸入',rot:-90,anchor:'center'} },
  { from:'auth-requester',to:'refresh-boundary',pts:[[445,558],[445,1218],[740,1218],[740,1274]],label:{s:'al',x:757,y:980,t:'派送語意更新',rot:-90,anchor:'center'} }
];

const TEXTS = [
  {s:'title',x:110,y:86,t:'RivetHTTPClient — 認證責任目標'},
  {s:'sub',x:110,y:118,t:'原始請求所有權 → 語意策略／狀態 → 通用 HTTP 輸入／輸出；已採用模型 C，尚未實作'},
  {s:'tag',x:110,y:146,runs:[{t:'AuthRequester',fill:planeColor('coordination')},{t:' 持有原始請求；',fill:'#4A5462'},{t:'AuthFlow',fill:planeColor('policy')},{t:' 只擁有策略／狀態；',fill:'#4A5462'},{t:'Requester',fill:planeColor('io')},{t:' 執行通用輸入／輸出',fill:'#4A5462'}]},
  {s:'legend',x:1082,y:86,t:'虛線 — Rivet 擁有的抽象'},
  {s:'legend',x:1082,y:110,t:'實線 — 呼叫端或待定邊界'},
  {s:'legend',x:1143,y:134,t:'顏色 — 所屬責任層'},
  {s:'bn',x:110,y:1406,t:'歷史：模型 A 的 AuthRequester → HTTPRequest 僅是編譯期型別相依，非模型 C 請求準備／建構／所有權／輸入輸出。'},
  {s:'bn',x:110,y:1426,t:'限制：本圖不建立 HeaderOverlay、CredentialRefresher、AuthEvent、TokenFetcher 或 TokenProvider 執行期。'},
  {s:'bn',x:110,y:1446,t:'未來：憑證更新輸入／輸出、憑證更新、操作／失敗／非同步程式介面必須由獨立具體消費端主題鎖定。'}
];
const SWATCHES = [
  {x:1046,y:75,w:26,h:13,stroke:'#8B93A1',alpha:0.8,dash:true},
  {x:1046,y:99,w:26,h:13,stroke:C.boxStroke,alpha:1,fill:C.boxFill}
];
const CHIPS = ['caller','coordination','policy','io','deferred'].map((id,i)=>({x:1046+i*13,y:123,w:9,h:13,fill:planeColor(id)}));
