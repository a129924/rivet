// v2：完整可行性驗證工具的責任邊界；不是正式產品能力。
const W = 1480, H = 1680;
const PLANES = {
  "interaction": {
    "c": "#94A3B8",
    "label": "使用者與驗證畫面"
  },
  "verification": {
    "c": "#7DD3FC",
    "label": "獨立驗證 App"
  },
  "baseline": {
    "c": "#A78BFA",
    "label": "既有正式契約（未修改）"
  },
  "storage": {
    "c": "#4ADE80",
    "label": "macOS DPK"
  },
  "remote": {
    "c": "#F6821F",
    "label": "GitHub.com"
  }
};
const BANDS = [
  {
    "id": "band-interaction",
    "plane": "interaction",
    "x": 160,
    "y": 200,
    "w": 1260,
    "h": 160,
    "alpha": 0.5,
    "dash": false,
    "hdr": {
      "x": 184,
      "y": 230,
      "t": "使用者與驗證畫面"
    }
  },
  {
    "id": "band-verification",
    "plane": "verification",
    "x": 160,
    "y": 420,
    "w": 1260,
    "h": 420,
    "alpha": 0.5,
    "dash": true,
    "hdr": {
      "x": 184,
      "y": 450,
      "t": "GitHubConnectionVerification — 全部驗證產物歸此 App"
    }
  },
  {
    "id": "band-baseline",
    "plane": "baseline",
    "x": 160,
    "y": 900,
    "w": 1260,
    "h": 180,
    "alpha": 0.5,
    "dash": true,
    "hdr": {
      "x": 184,
      "y": 930,
      "t": "既有正式契約 — 原樣保留，只有驗證 App 單向使用"
    }
  },
  {
    "id": "band-storage",
    "plane": "storage",
    "x": 160,
    "y": 1160,
    "w": 1260,
    "h": 160,
    "alpha": 0.5,
    "dash": false,
    "hdr": {
      "x": 184,
      "y": 1190,
      "t": "macOS Data Protection Keychain — 新驗證 namespace"
    }
  },
  {
    "id": "band-remote",
    "plane": "remote",
    "x": 160,
    "y": 1400,
    "w": 1260,
    "h": 160,
    "alpha": 0.5,
    "dash": false,
    "hdr": {
      "x": 184,
      "y": 1430,
      "t": "GitHub.com — 真實外部服務"
    }
  }
];
const BOXES = [
  {
    "id": "human",
    "plane": "interaction",
    "band": "band-interaction",
    "x": 200,
    "y": 250,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "使用者",
    "about": "secret只輸入驗證App SecureField；新舊真人證據分開。",
    "texts": [
      [
        "bl",
        224,
        278,
        "使用者"
      ],
      [
        "bs",
        224,
        300,
        "自己的 OAuth App 設定"
      ],
      [
        "bs",
        224,
        316,
        "逐段回報系統提示"
      ]
    ]
  },
  {
    "id": "browser",
    "plane": "interaction",
    "band": "band-interaction",
    "x": 610,
    "y": 250,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "系統瀏覽器",
    "about": "127.0.0.1 callback；靜態完成頁不單獨證明連線成功。",
    "texts": [
      [
        "bl",
        634,
        278,
        "系統瀏覽器"
      ],
      [
        "bs",
        634,
        300,
        "真 GitHub 授權"
      ],
      [
        "bs",
        634,
        316,
        "callback 返回驗證 App"
      ]
    ]
  },
  {
    "id": "ui",
    "plane": "interaction",
    "band": "band-interaction",
    "x": 1020,
    "y": 250,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "驗證 UI",
    "about": "GitHubConnectionView與display-ready input皆App-local。",
    "texts": [
      [
        "bl",
        1044,
        278,
        "驗證 UI"
      ],
      [
        "bs",
        1044,
        300,
        "常駐「非 Rivet 正式產品」"
      ],
      [
        "bs",
        1044,
        316,
        "沒有共用 RivetPresentation"
      ]
    ]
  },
  {
    "id": "coord",
    "plane": "verification",
    "band": "band-verification",
    "x": 200,
    "y": 480,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "驗證協調",
    "about": "GitHubConnectionCoordinator；重新授權先退休，不復活舊連線。",
    "texts": [
      [
        "bl",
        224,
        508,
        "驗證協調"
      ],
      [
        "bs",
        224,
        530,
        "唯一 provider／scope"
      ],
      [
        "bs",
        224,
        546,
        "settlement 後才接受下一工作"
      ]
    ]
  },
  {
    "id": "session",
    "plane": "verification",
    "band": "band-verification",
    "x": 505,
    "y": 480,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "驗證授權 session",
    "about": "GitHubOAuthAuthorizationSession屬驗證App，不是production API。",
    "texts": [
      [
        "bl",
        529,
        508,
        "驗證授權 session"
      ],
      [
        "bs",
        529,
        530,
        "state／S256 PKCE"
      ],
      [
        "bs",
        529,
        546,
        "回傳 bundle，不保存"
      ]
    ]
  },
  {
    "id": "relay",
    "plane": "verification",
    "band": "band-verification",
    "x": 810,
    "y": 480,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "驗證 callback relay",
    "about": "GitHubLoopbackCallbackRelay只接有限本機callback。",
    "texts": [
      [
        "bl",
        834,
        508,
        "驗證 callback relay"
      ],
      [
        "bs",
        834,
        530,
        "127.0.0.1 動態 port"
      ],
      [
        "bs",
        834,
        546,
        "8 KiB／5 秒／exact path"
      ]
    ]
  },
  {
    "id": "probe",
    "plane": "verification",
    "band": "band-verification",
    "x": 1115,
    "y": 480,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "驗證帳號 probe",
    "about": "GitHubAccountProbe是驗證App內唯讀探針。",
    "texts": [
      [
        "bl",
        1139,
        508,
        "驗證帳號 probe"
      ],
      [
        "bs",
        1139,
        530,
        "scope.rest → GET /user"
      ],
      [
        "bs",
        1139,
        546,
        "200＋positive ID／非空 login"
      ]
    ]
  },
  {
    "id": "stores",
    "plane": "verification",
    "band": "band-verification",
    "x": 200,
    "y": 650,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "驗證 DPK adapter",
    "about": "GitHubOAuthDataProtectionStores全部App-local，不遷移舊Rivet資料。",
    "texts": [
      [
        "bl",
        224,
        678,
        "驗證 DPK adapter"
      ],
      [
        "bs",
        224,
        700,
        "兩 items／strict v1 codec"
      ],
      [
        "bs",
        224,
        716,
        "綁 clientID 與完整六欄"
      ]
    ]
  },
  {
    "id": "fetcher",
    "plane": "verification",
    "band": "band-verification",
    "x": 505,
    "y": 650,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "驗證 HTTP refresh",
    "about": "VerificationOAuthHTTPTokenFetcher沿既有public OAuthTokenFetcher port。",
    "texts": [
      [
        "bl",
        529,
        678,
        "驗證 HTTP refresh"
      ],
      [
        "bs",
        529,
        700,
        "本地 endpoint／DTO／30 秒"
      ],
      [
        "bs",
        529,
        716,
        "不擴 production internal visibility"
      ]
    ]
  },
  {
    "id": "tracker",
    "plane": "verification",
    "band": "band-verification",
    "x": 810,
    "y": 650,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "本地 lifecycle tracker",
    "about": "VerificationLifecycleObservation不呼額外snapshot或I/O、不新增正式停止API。",
    "texts": [
      [
        "bl",
        834,
        678,
        "本地 lifecycle tracker"
      ],
      [
        "bs",
        834,
        700,
        "一個 provider generation 一份"
      ],
      [
        "bs",
        834,
        716,
        "只記真 refresh／save 結果"
      ]
    ]
  },
  {
    "id": "clock",
    "plane": "verification",
    "band": "band-verification",
    "x": 1115,
    "y": 650,
    "w": 280,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "受控時鐘與脫敏收據",
    "about": "GitHubExpiryValidation只於明確環境opt-in；exclusive私有receipt。",
    "texts": [
      [
        "bl",
        1139,
        678,
        "受控時鐘與脫敏收據"
      ],
      [
        "bs",
        1139,
        700,
        "只改 provider 注入 now"
      ],
      [
        "bs",
        1139,
        716,
        "accepted 真保存後回 real"
      ]
    ]
  },
  {
    "id": "provider",
    "plane": "baseline",
    "band": "band-baseline",
    "x": 200,
    "y": 960,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "OAuthTokenProvider",
    "about": "production bytes對topic前base不變；沒有disposition新增API。",
    "texts": [
      [
        "bl",
        224,
        988,
        "OAuthTokenProvider"
      ],
      [
        "bs",
        224,
        1010,
        "既有 public lifecycle"
      ],
      [
        "bs",
        224,
        1026,
        "restore／single-flight／rotation save"
      ]
    ]
  },
  {
    "id": "scope",
    "plane": "baseline",
    "band": "band-baseline",
    "x": 610,
    "y": 960,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubClientScope／雙 client",
    "about": "共用同provider；不是新增正式產品登入composition。",
    "texts": [
      [
        "bl",
        634,
        988,
        "GitHubClientScope／雙 client"
      ],
      [
        "bs",
        634,
        1010,
        "既有 REST／GraphQL contracts"
      ],
      [
        "bs",
        634,
        1026,
        "HTTP 401 最多一次 recovery"
      ]
    ]
  },
  {
    "id": "http",
    "plane": "baseline",
    "band": "band-baseline",
    "x": 1020,
    "y": 960,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "RivetHTTPClient",
    "about": "驗證App單向依賴；移除整個App後production仍可build/test。",
    "texts": [
      [
        "bl",
        1044,
        988,
        "RivetHTTPClient"
      ],
      [
        "bs",
        1044,
        1010,
        "既有 generic raw HTTP"
      ],
      [
        "bs",
        1044,
        1026,
        "不承擔 GitHub 業務或分類"
      ]
    ]
  },
  {
    "id": "config",
    "plane": "storage",
    "band": "band-storage",
    "x": 405,
    "y": 1210,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "configuration item",
    "about": "驗證App私有group，DPK=true、同步false，無跨item transaction。",
    "texts": [
      [
        "bl",
        429,
        1238,
        "configuration item"
      ],
      [
        "bs",
        429,
        1260,
        "新 service／configuration account"
      ],
      [
        "bs",
        429,
        1276,
        "clientID＋clientSecret"
      ]
    ]
  },
  {
    "id": "credential",
    "plane": "storage",
    "band": "band-storage",
    "x": 815,
    "y": 1210,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "credential item",
    "about": "AfterFirstUnlockThisDeviceOnly；真輪替保存及新程序讀回。",
    "texts": [
      [
        "bl",
        839,
        1238,
        "credential item"
      ],
      [
        "bs",
        839,
        1260,
        "新 service／credential account"
      ],
      [
        "bs",
        839,
        1276,
        "完整六欄＋clientID"
      ]
    ]
  },
  {
    "id": "authorize",
    "plane": "remote",
    "band": "band-remote",
    "x": 200,
    "y": 1450,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHub authorize",
    "about": "真授權成功僅屬受限驗證結果。",
    "texts": [
      [
        "bl",
        224,
        1478,
        "GitHub authorize"
      ],
      [
        "bs",
        224,
        1500,
        "使用者同意／offline_access"
      ],
      [
        "bs",
        224,
        1516,
        "S256 PKCE"
      ]
    ]
  },
  {
    "id": "token",
    "plane": "remote",
    "band": "band-remote",
    "x": 610,
    "y": 1450,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHub token endpoint",
    "about": "本地驗證fetcher無redirect／cookie／cache／一般retry。",
    "texts": [
      [
        "bl",
        634,
        1478,
        "GitHub token endpoint"
      ],
      [
        "bs",
        634,
        1500,
        "初次 exchange／真 refresh"
      ],
      [
        "bs",
        634,
        1516,
        "輪替接受後必須完整保存"
      ]
    ]
  },
  {
    "id": "api",
    "plane": "remote",
    "band": "band-remote",
    "x": 1020,
    "y": 1450,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHub API",
    "about": "同帳號API成功，不宣稱正式Rivet產品登入交付。",
    "texts": [
      [
        "bl",
        1044,
        1478,
        "GitHub API"
      ],
      [
        "bs",
        1044,
        1500,
        "GET /user 有效帳號"
      ],
      [
        "bs",
        1044,
        1516,
        "PR 業務尚未整合"
      ]
    ]
  }
];
const EDGES = [
  {
    "from": "human",
    "to": "ui",
    "pts": [
      [
        390,
        354
      ],
      [
        390,
        374
      ],
      [
        1210,
        374
      ],
      [
        1210,
        358
      ]
    ]
  },
  {
    "from": "ui",
    "to": "coord",
    "pts": [
      [
        1210,
        354
      ],
      [
        1210,
        390
      ],
      [
        340,
        390
      ],
      [
        340,
        476
      ]
    ]
  },
  {
    "from": "coord",
    "to": "session",
    "pts": [
      [
        480,
        526
      ],
      [
        501,
        526
      ]
    ]
  },
  {
    "from": "relay",
    "to": "session",
    "pts": [
      [
        810,
        526
      ],
      [
        789,
        526
      ]
    ]
  },
  {
    "from": "coord",
    "to": "stores",
    "pts": [
      [
        340,
        584
      ],
      [
        340,
        646
      ]
    ]
  },
  {
    "from": "coord",
    "to": "tracker",
    "pts": [
      [
        480,
        560
      ],
      [
        494,
        560
      ],
      [
        494,
        620
      ],
      [
        950,
        620
      ],
      [
        950,
        646
      ]
    ]
  },
  {
    "from": "coord",
    "to": "provider",
    "pts": [
      [
        200,
        550
      ],
      [
        136,
        550
      ],
      [
        136,
        1010
      ],
      [
        196,
        1010
      ]
    ],
    "label": {
      "s": "al",
      "x": 120,
      "y": 820,
      "t": "只使用既有 public 契約",
      "rot": -90,
      "anchor": "center"
    }
  },
  {
    "from": "probe",
    "to": "scope",
    "pts": [
      [
        1395,
        550
      ],
      [
        1440,
        550
      ],
      [
        1440,
        870
      ],
      [
        800,
        870
      ],
      [
        800,
        956
      ]
    ]
  },
  {
    "from": "provider",
    "to": "scope",
    "pts": [
      [
        580,
        1010
      ],
      [
        606,
        1010
      ]
    ]
  },
  {
    "from": "provider",
    "to": "stores",
    "pts": [
      [
        390,
        960
      ],
      [
        390,
        900
      ],
      [
        340,
        900
      ],
      [
        340,
        758
      ]
    ]
  },
  {
    "from": "provider",
    "to": "fetcher",
    "pts": [
      [
        500,
        960
      ],
      [
        500,
        880
      ],
      [
        645,
        880
      ],
      [
        645,
        758
      ]
    ]
  },
  {
    "from": "fetcher",
    "to": "http",
    "pts": [
      [
        645,
        754
      ],
      [
        645,
        820
      ],
      [
        1428,
        820
      ],
      [
        1428,
        940
      ],
      [
        1210,
        940
      ],
      [
        1210,
        956
      ]
    ]
  },
  {
    "from": "stores",
    "to": "config",
    "pts": [
      [
        200,
        700
      ],
      [
        164,
        700
      ],
      [
        164,
        1120
      ],
      [
        595,
        1120
      ],
      [
        595,
        1206
      ]
    ]
  },
  {
    "from": "stores",
    "to": "credential",
    "pts": [
      [
        200,
        720
      ],
      [
        152,
        720
      ],
      [
        152,
        1140
      ],
      [
        1005,
        1140
      ],
      [
        1005,
        1206
      ]
    ]
  },
  {
    "from": "browser",
    "to": "authorize",
    "pts": [
      [
        800,
        250
      ],
      [
        800,
        180
      ],
      [
        100,
        180
      ],
      [
        100,
        1500
      ],
      [
        196,
        1500
      ]
    ],
    "label": {
      "s": "al",
      "x": 84,
      "y": 1020,
      "t": "瀏覽器授權",
      "rot": -90,
      "anchor": "center"
    }
  },
  {
    "from": "http",
    "to": "token",
    "pts": [
      [
        1400,
        1010
      ],
      [
        1448,
        1010
      ],
      [
        1448,
        1370
      ],
      [
        800,
        1370
      ],
      [
        800,
        1446
      ]
    ]
  },
  {
    "from": "scope",
    "to": "api",
    "pts": [
      [
        800,
        1064
      ],
      [
        800,
        1100
      ],
      [
        1456,
        1100
      ],
      [
        1456,
        1388
      ],
      [
        1210,
        1388
      ],
      [
        1210,
        1446
      ]
    ]
  }
];
const TEXTS = [
  {
    "s": "title",
    "x": 160,
    "y": 86,
    "t": "GitHub 持續連線 — 獨立驗證 App"
  },
  {
    "s": "sub",
    "x": 160,
    "y": 118,
    "t": "授權 → 保存 → 重啟 → 輪替 → API；不交付正式產品登入"
  },
  {
    "s": "legend",
    "x": 1082,
    "y": 86,
    "t": "虛線：自有抽象"
  },
  {
    "s": "legend",
    "x": 1082,
    "y": 110,
    "t": "實線：畫面或外部設施"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1610,
    "t": "歸屬：移除驗證 App 後，production 不改仍可建置／測試；沒有驗證專用 public API 或反向依賴。"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1632,
    "t": "限制：有效 profile／同機同使用者／同 AppID、group 與原 certificate；profile 更新後讀回仍未驗證。"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1654,
    "t": "箭頭為呼叫／注入；provider 經注入 public ports 呼叫 adapter，production 不 import 驗證 App。"
  }
];
const SWATCHES = [
  {
    "x": 1046,
    "y": 75,
    "w": 26,
    "h": 13,
    "stroke": "#8B93A1",
    "alpha": 0.8,
    "dash": true
  },
  {
    "x": 1046,
    "y": 99,
    "w": 26,
    "h": 13,
    "stroke": "#3A4250",
    "alpha": 1
  }
];
const CHIPS = [];
