// 本 topic 的責任圖；不是 runtime sequence，也不加入新的 BC。
const W = 1480, H = 1600;
const PLANES = {
  "surface": {
    "c": "#7DD3FC",
    "label": "驗證 App 介面"
  },
  "app": {
    "c": "#A78BFA",
    "label": "程序內組合"
  },
  "auth": {
    "c": "#FB7185",
    "label": "GitHub 初次授權"
  },
  "runtime": {
    "c": "#4ADE80",
    "label": "既有憑證執行期"
  },
  "outside": {
    "c": "#94A3B8",
    "label": "外部系統"
  }
};
const BANDS = [
  {
    "id": "band-surface",
    "plane": "surface",
    "x": 160,
    "y": 200,
    "w": 1260,
    "h": 170,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 230,
      "t": "獨立驗證 APP · 非 RIVET 產品 UI"
    }
  },
  {
    "id": "band-app",
    "plane": "app",
    "x": 160,
    "y": 430,
    "w": 1260,
    "h": 190,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 460,
      "t": "驗證 APP 組合與平台 ADAPTER"
    }
  },
  {
    "id": "band-auth",
    "plane": "auth",
    "x": 160,
    "y": 680,
    "w": 1260,
    "h": 190,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 710,
      "t": "GITHUBINTEGRATION · NON-BC"
    }
  },
  {
    "id": "band-runtime",
    "plane": "runtime",
    "x": 160,
    "y": 930,
    "w": 1260,
    "h": 300,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 960,
      "t": "沿用既有 CREDENTIAL LIFECYCLE 與 CLIENTS"
    }
  },
  {
    "id": "band-outside",
    "plane": "outside",
    "x": 160,
    "y": 1290,
    "w": 1260,
    "h": 190,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 1320,
      "t": "外部系統 · 無遠端成功預設"
    }
  }
];
const BOXES = [
  {
    "id": "entry",
    "plane": "surface",
    "band": "band-surface",
    "x": 200,
    "y": 260,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "GitHubSignInVerificationApp",
    "about": "組合依賴與測試模式；啟動不恢復憑證、不開瀏覽器。",
    "texts": [
      [
        "bl",
        224,
        286,
        "GitHubSignInVerificationApp"
      ],
      [
        "bs",
        224,
        308,
        "組合依賴與測試模式"
      ],
      [
        "bn",
        224,
        327,
        "啟動不恢復憑證、不開瀏覽器"
      ]
    ]
  },
  {
    "id": "input",
    "plane": "surface",
    "band": "band-surface",
    "x": 620,
    "y": 260,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "App-local Presentation input",
    "about": "驗證 App 內部狀態與操作旗標；不由共用 RivetPresentation 公開。",
    "texts": [
      [
        "bl",
        644,
        286,
        "Presentation input"
      ],
      [
        "bs",
        644,
        308,
        "display-ready 狀態與操作旗標"
      ],
      [
        "bn",
        644,
        327,
        "不持有 OAuth 憑證"
      ]
    ]
  },
  {
    "id": "view",
    "plane": "surface",
    "band": "band-surface",
    "x": 1040,
    "y": 260,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "GitHubConnectionView",
    "about": "配置輸入、登入、再次查詢；使用 SecureField 輸入 secret。",
    "texts": [
      [
        "bl",
        1064,
        286,
        "GitHubConnectionView"
      ],
      [
        "bs",
        1064,
        308,
        "配置輸入、登入、再次查詢"
      ],
      [
        "bn",
        1064,
        327,
        "使用 SecureField 輸入 secret"
      ]
    ]
  },
  {
    "id": "relay",
    "plane": "app",
    "band": "band-app",
    "x": 200,
    "y": 490,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "Loopback relay",
    "about": "僅 127.0.0.1 動態連接埠；有界 HTTP headers 與讀取時間。",
    "texts": [
      [
        "bl",
        224,
        516,
        "Loopback relay"
      ],
      [
        "bs",
        224,
        538,
        "僅 127.0.0.1 動態連接埠"
      ],
      [
        "bn",
        224,
        557,
        "有界 HTTP headers 與讀取時間"
      ]
    ]
  },
  {
    "id": "coordinator",
    "plane": "app",
    "band": "band-app",
    "x": 620,
    "y": 490,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "Connection coordinator",
    "about": "驗證 App 擁有 coordinator／dependencies 與 GitHubAccountProbe／Identity／Error；透過 scope 驗證真實 API。",
    "texts": [
      [
        "bl",
        644,
        516,
        "Connection coordinator"
      ],
      [
        "bs",
        644,
        538,
        "App-local dependencies／Probe"
      ],
      [
        "bn",
        644,
        557,
        "工作 settled 後才接受新登入"
      ]
    ]
  },
  {
    "id": "store",
    "plane": "app",
    "band": "band-app",
    "x": 1040,
    "y": 490,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "程序內 bundle store",
    "about": "完整六欄 load／save；不寫 Keychain、SQLite 或檔案。",
    "texts": [
      [
        "bl",
        1064,
        516,
        "程序內 bundle store"
      ],
      [
        "bs",
        1064,
        538,
        "完整六欄 load／save"
      ],
      [
        "bn",
        1064,
        557,
        "不寫 Keychain、SQLite 或檔案"
      ]
    ]
  },
  {
    "id": "config",
    "plane": "auth",
    "band": "band-auth",
    "x": 200,
    "y": 740,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "OAuth App configuration",
    "about": "client ID 與 secret；diagnostics／reflection 遮蔽。",
    "texts": [
      [
        "bl",
        224,
        766,
        "OAuth App configuration"
      ],
      [
        "bs",
        224,
        788,
        "client ID 與 secret"
      ],
      [
        "bn",
        224,
        807,
        "diagnostics／reflection 遮蔽"
      ]
    ]
  },
  {
    "id": "session",
    "plane": "auth",
    "band": "band-auth",
    "x": 620,
    "y": 740,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "Authorization Session",
    "about": "state／S256／單次 callback；取消或到期不發布遲到結果。",
    "texts": [
      [
        "bl",
        644,
        766,
        "Authorization Session"
      ],
      [
        "bs",
        644,
        788,
        "state／S256／單次 callback"
      ],
      [
        "bn",
        644,
        807,
        "取消或到期不發布遲到結果"
      ]
    ]
  },
  {
    "id": "exchanger",
    "plane": "auth",
    "band": "band-auth",
    "x": 1040,
    "y": 740,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "Code exchanger",
    "about": "固定 token endpoint；無磁碟快取、不跟隨 redirect。",
    "texts": [
      [
        "bl",
        1064,
        766,
        "Code exchanger"
      ],
      [
        "bs",
        1064,
        788,
        "固定 token endpoint"
      ],
      [
        "bn",
        1064,
        807,
        "無磁碟快取、不跟隨 redirect"
      ]
    ]
  },
  {
    "id": "factory",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 200,
    "y": 990,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "Refresh factory",
    "about": "additive public 組裝入口；原 concrete 維持 internal。",
    "texts": [
      [
        "bl",
        224,
        1016,
        "Refresh factory"
      ],
      [
        "bs",
        224,
        1038,
        "additive public 組裝入口"
      ],
      [
        "bn",
        224,
        1057,
        "原 concrete 維持 internal"
      ]
    ]
  },
  {
    "id": "provider",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 620,
    "y": 990,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "OAuthTokenProvider",
    "about": "restore／refresh／rotation；沿用 single-flight 與 snapshot。",
    "texts": [
      [
        "bl",
        644,
        1016,
        "OAuthTokenProvider"
      ],
      [
        "bs",
        644,
        1038,
        "restore／refresh／rotation"
      ],
      [
        "bn",
        644,
        1057,
        "沿用 single-flight 與 snapshot"
      ]
    ]
  },
  {
    "id": "scope",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 1040,
    "y": 990,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "GitHubClientScope",
    "about": "caller-owned provider lifetime；prepare 不探測遠端權限。",
    "texts": [
      [
        "bl",
        1064,
        1016,
        "GitHubClientScope"
      ],
      [
        "bs",
        1064,
        1038,
        "caller-owned provider lifetime"
      ],
      [
        "bn",
        1064,
        1057,
        "prepare 不探測遠端權限"
      ]
    ]
  },
  {
    "id": "refresh",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 200,
    "y": 1130,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "HTTP refresh adapter",
    "about": "原有請求與錯誤政策；本 topic 不重寫 rotation。",
    "texts": [
      [
        "bl",
        224,
        1156,
        "HTTP refresh adapter"
      ],
      [
        "bs",
        224,
        1178,
        "原有請求與錯誤政策"
      ],
      [
        "bn",
        224,
        1197,
        "本 topic 不重寫 rotation"
      ]
    ]
  },
  {
    "id": "rest",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 620,
    "y": 1130,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "REST client",
    "about": "本次呼叫 GET /user；401 recovery 沿用既有政策。",
    "texts": [
      [
        "bl",
        644,
        1156,
        "REST client"
      ],
      [
        "bs",
        644,
        1178,
        "本次呼叫 GET /user"
      ],
      [
        "bn",
        644,
        1197,
        "401 recovery 沿用既有政策"
      ]
    ]
  },
  {
    "id": "graphql",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 1040,
    "y": 1130,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": true,
    "name": "GraphQL client",
    "about": "同一 scope 的既有鄰接能力；本次身分查詢不使用它。",
    "texts": [
      [
        "bl",
        1064,
        1156,
        "GraphQL client"
      ],
      [
        "bs",
        1064,
        1178,
        "同一 scope 的既有鄰接能力"
      ],
      [
        "bn",
        1064,
        1197,
        "本次身分查詢不使用它"
      ]
    ]
  },
  {
    "id": "browser",
    "plane": "outside",
    "band": "band-outside",
    "x": 200,
    "y": 1350,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "預設瀏覽器",
    "about": "使用者主動完成 GitHub 授權；不接收 Client Secret。",
    "texts": [
      [
        "bl",
        224,
        1376,
        "預設瀏覽器"
      ],
      [
        "bs",
        224,
        1398,
        "使用者主動完成 GitHub 授權"
      ],
      [
        "bn",
        224,
        1417,
        "不接收 Client Secret"
      ]
    ]
  },
  {
    "id": "github",
    "plane": "outside",
    "band": "band-outside",
    "x": 620,
    "y": 1350,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "GitHub OAuth",
    "about": "授權與初次 token exchange；真實驗收待 Human review。",
    "texts": [
      [
        "bl",
        644,
        1376,
        "GitHub OAuth"
      ],
      [
        "bs",
        644,
        1398,
        "授權與初次 token exchange"
      ],
      [
        "bn",
        644,
        1417,
        "真實驗收待 Human review"
      ]
    ]
  },
  {
    "id": "api",
    "plane": "outside",
    "band": "band-outside",
    "x": 1040,
    "y": 1350,
    "w": 380,
    "h": 80,
    "r": 10,
    "dash": false,
    "name": "GitHub API",
    "about": "HTTP 200＋有效 login／id；錯誤回應不顯示成功。",
    "texts": [
      [
        "bl",
        1064,
        1376,
        "GitHub API"
      ],
      [
        "bs",
        1064,
        1398,
        "HTTP 200＋有效 login／id"
      ],
      [
        "bn",
        1064,
        1417,
        "錯誤回應不顯示成功"
      ]
    ]
  }
];
const EDGES = [
  {
    "from": "entry",
    "to": "coordinator",
    "pts": [
      [
        390,
        340
      ],
      [
        390,
        400
      ],
      [
        810,
        400
      ],
      [
        810,
        484
      ]
    ]
  },
  {
    "from": "view",
    "to": "input",
    "pts": [
      [
        1038,
        300
      ],
      [
        1006,
        300
      ]
    ]
  },
  {
    "from": "coordinator",
    "to": "input",
    "pts": [
      [
        810,
        488
      ],
      [
        810,
        346
      ]
    ]
  },
  {
    "from": "coordinator",
    "to": "relay",
    "pts": [
      [
        618,
        530
      ],
      [
        586,
        530
      ]
    ]
  },
  {
    "from": "coordinator",
    "to": "store",
    "pts": [
      [
        1002,
        530
      ],
      [
        1034,
        530
      ]
    ]
  },
  {
    "from": "relay",
    "to": "session",
    "pts": [
      [
        390,
        570
      ],
      [
        390,
        625
      ],
      [
        810,
        625
      ],
      [
        810,
        734
      ]
    ]
  },
  {
    "from": "config",
    "to": "session",
    "pts": [
      [
        582,
        780
      ],
      [
        614,
        780
      ]
    ]
  },
  {
    "from": "session",
    "to": "exchanger",
    "pts": [
      [
        1002,
        780
      ],
      [
        1034,
        780
      ]
    ]
  },
  {
    "from": "coordinator",
    "to": "provider",
    "pts": [
      [
        660,
        570
      ],
      [
        660,
        620
      ],
      [
        116,
        620
      ],
      [
        116,
        1030
      ],
      [
        614,
        1030
      ]
    ]
  },
  {
    "from": "factory",
    "to": "refresh",
    "pts": [
      [
        390,
        1070
      ],
      [
        390,
        1124
      ]
    ]
  },
  {
    "from": "provider",
    "to": "refresh",
    "pts": [
      [
        810,
        1070
      ],
      [
        810,
        1100
      ],
      [
        390,
        1100
      ],
      [
        390,
        1124
      ]
    ]
  },
  {
    "from": "provider",
    "to": "scope",
    "pts": [
      [
        1002,
        1030
      ],
      [
        1034,
        1030
      ]
    ]
  },
  {
    "from": "scope",
    "to": "graphql",
    "pts": [
      [
        1230,
        1070
      ],
      [
        1230,
        1124
      ]
    ]
  },
  {
    "from": "scope",
    "to": "rest",
    "pts": [
      [
        1100,
        1070
      ],
      [
        1100,
        1108
      ],
      [
        900,
        1108
      ],
      [
        900,
        1124
      ]
    ]
  },
  {
    "from": "rest",
    "to": "api",
    "pts": [
      [
        810,
        1210
      ],
      [
        810,
        1260
      ],
      [
        1230,
        1260
      ],
      [
        1230,
        1344
      ]
    ]
  },
  {
    "from": "exchanger",
    "to": "github",
    "pts": [
      [
        1382,
        780
      ],
      [
        1440,
        780
      ],
      [
        1440,
        1250
      ],
      [
        810,
        1250
      ],
      [
        810,
        1344
      ]
    ]
  },
  {
    "from": "entry",
    "to": "browser",
    "pts": [
      [
        260,
        340
      ],
      [
        260,
        390
      ],
      [
        84,
        390
      ],
      [
        84,
        1390
      ],
      [
        194,
        1390
      ]
    ]
  }
];
const TEXTS = [
  {
    "s": "title",
    "x": 160,
    "y": 86,
    "t": "正式 OAuth 與獨立驗證 App"
  },
  {
    "s": "sub",
    "x": 160,
    "y": 118,
    "t": "驗證入口 → 正式 OAuth → 程序內組合 → 真實 API 結果"
  },
  {
    "s": "legend",
    "x": 1082,
    "y": 86,
    "t": "虛線：擁有的抽象"
  },
  {
    "s": "legend",
    "x": 1082,
    "y": 110,
    "t": "實線：平台介面與可替換實作"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1540,
    "t": "正式 Rivet 登入 UI 尚未交付；驗證 App 可移除，GitHubIntegration 能力保留。"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1560,
    "t": "持久化、跨重啟還原及 DPK 採用留在另一 topic；本圖不代表遠端 OAuth 已驗收。"
  }
];
const SWATCHES = [];
const CHIPS = [];
