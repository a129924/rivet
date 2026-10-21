const W = 1480, H = 1760;
const PLANES = {
  "interaction": {
    "c": "#94A3B8",
    "label": "使用者與顯示"
  },
  "composition": {
    "c": "#7DD3FC",
    "label": "應用程式組合"
  },
  "integration": {
    "c": "#A78BFA",
    "label": "GitHubIntegration（non-BC）"
  },
  "storage": {
    "c": "#4ADE80",
    "label": "macOS 憑證保存"
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
    "h": 170,
    "alpha": 0.5,
    "dash": false,
    "hdr": {
      "x": 184,
      "y": 230,
      "t": "使用者與顯示入口"
    }
  },
  {
    "id": "band-composition",
    "plane": "composition",
    "x": 160,
    "y": 450,
    "w": 1260,
    "h": 190,
    "alpha": 0.5,
    "dash": true,
    "hdr": {
      "x": 184,
      "y": 480,
      "t": "App composition — 唯一 provider／scope 所有者"
    }
  },
  {
    "id": "band-integration",
    "plane": "integration",
    "x": 160,
    "y": 720,
    "w": 1260,
    "h": 400,
    "alpha": 0.5,
    "dash": true,
    "hdr": {
      "x": 184,
      "y": 750,
      "t": "GitHubIntegration — 既有 non-BC"
    }
  },
  {
    "id": "band-storage",
    "plane": "storage",
    "x": 160,
    "y": 1200,
    "w": 1260,
    "h": 170,
    "alpha": 0.5,
    "dash": false,
    "hdr": {
      "x": 184,
      "y": 1230,
      "t": "macOS Data Protection Keychain"
    }
  },
  {
    "id": "band-remote",
    "plane": "remote",
    "x": 160,
    "y": 1450,
    "w": 1260,
    "h": 170,
    "alpha": 0.5,
    "dash": false,
    "hdr": {
      "x": 184,
      "y": 1480,
      "t": "GitHub.com — 外部授權與 API"
    }
  }
];
const BOXES = [
  {
    "id": "user",
    "plane": "interaction",
    "band": "band-interaction",
    "x": 200,
    "y": 255,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "使用者",
    "about": "僅單一 GitHub.com 帳號。",
    "texts": [
      [
        "bl",
        224,
        283,
        "使用者"
      ],
      [
        "bs",
        224,
        305,
        "授權、取消、明確重試"
      ],
      [
        "bs",
        224,
        321,
        "提示觀察由真人回報"
      ]
    ]
  },
  {
    "id": "browser",
    "plane": "interaction",
    "band": "band-interaction",
    "x": 610,
    "y": 255,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "系統瀏覽器",
    "about": "由產品開啟正式授權 URL；loopback callback 回到本機。",
    "texts": [
      [
        "bl",
        634,
        283,
        "系統瀏覽器"
      ],
      [
        "bs",
        634,
        305,
        "GitHub 授權頁面"
      ],
      [
        "bs",
        634,
        321,
        "不保存應用程式 credential"
      ]
    ]
  },
  {
    "id": "leaf",
    "plane": "interaction",
    "band": "band-interaction",
    "x": 1020,
    "y": 255,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHubConnectionView",
    "about": "Presentation leaf 只接受 display-ready 輸入；不擁有憑證生命週期。",
    "texts": [
      [
        "bl",
        1044,
        283,
        "GitHubConnectionView"
      ],
      [
        "bs",
        1044,
        305,
        "顯示帳號與有限狀態"
      ],
      [
        "bs",
        1044,
        321,
        "輸入 intent，不依賴 integration"
      ]
    ]
  },
  {
    "id": "coordinator",
    "plane": "composition",
    "band": "band-composition",
    "x": 200,
    "y": 510,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubConnectionCoordinator",
    "about": "App composition 持有唯一 provider／scope；所有重授權與修復先退休舊 generation。",
    "texts": [
      [
        "bl",
        224,
        538,
        "GitHubConnectionCoordinator"
      ],
      [
        "bs",
        224,
        560,
        "唯一 tracked operation admission gate"
      ],
      [
        "bs",
        224,
        576,
        "Task settled 後才允許改寫"
      ]
    ]
  },
  {
    "id": "relay",
    "plane": "composition",
    "band": "band-composition",
    "x": 610,
    "y": 510,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubLoopbackCallbackRelay",
    "about": "NWListener ready 後才建立 session 與開瀏覽器；完成、取消或逾時皆關閉。",
    "texts": [
      [
        "bl",
        634,
        538,
        "GitHubLoopbackCallbackRelay"
      ],
      [
        "bs",
        634,
        560,
        "只綁 127.0.0.1 動態 port"
      ],
      [
        "bs",
        634,
        576,
        "8 KiB／5 秒；只收 callback path"
      ]
    ]
  },
  {
    "id": "probe",
    "plane": "composition",
    "band": "band-composition",
    "x": 1020,
    "y": 510,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubAccountProbe",
    "about": "403 等 probe 失敗不觸發額外刷新；開始重授權即清除舊帳號。",
    "texts": [
      [
        "bl",
        1044,
        538,
        "GitHubAccountProbe"
      ],
      [
        "bs",
        1044,
        560,
        "scope.rest → GET /user"
      ],
      [
        "bs",
        1044,
        576,
        "只接受有效 200 帳號"
      ]
    ]
  },
  {
    "id": "session",
    "plane": "integration",
    "band": "band-integration",
    "x": 200,
    "y": 780,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "OAuth 授權 session",
    "about": "GitHubOAuthAuthorizationSession actor；驗證 callback，session 不持久化。",
    "texts": [
      [
        "bl",
        224,
        808,
        "OAuth 授權 session"
      ],
      [
        "bs",
        224,
        830,
        "state + S256 PKCE"
      ],
      [
        "bs",
        224,
        846,
        "一次 code consumption／30 秒 exchange"
      ]
    ]
  },
  {
    "id": "provider",
    "plane": "integration",
    "band": "band-integration",
    "x": 610,
    "y": 780,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "OAuthTokenProvider",
    "about": "provider 唯一管理 token lifecycle；disposition 只讀觀測；暫時重試沿用相同 provider。",
    "texts": [
      [
        "bl",
        634,
        808,
        "OAuthTokenProvider"
      ],
      [
        "bs",
        634,
        830,
        "single-flight refresh + save"
      ],
      [
        "bs",
        634,
        846,
        "失效與 accepted-save-failure 停止"
      ]
    ]
  },
  {
    "id": "scope",
    "plane": "integration",
    "band": "band-integration",
    "x": 1020,
    "y": 780,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubClientScope",
    "about": "REST 與 GraphQL 共用 credential state；不新增平行 lifecycle。",
    "texts": [
      [
        "bl",
        1044,
        808,
        "GitHubClientScope"
      ],
      [
        "bs",
        1044,
        830,
        "同一 provider 支援雙 client"
      ],
      [
        "bs",
        1044,
        846,
        "prepare／有限 401 recovery"
      ]
    ]
  },
  {
    "id": "stores",
    "plane": "integration",
    "band": "band-integration",
    "x": 200,
    "y": 980,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "Data Protection stores",
    "about": "GitHubOAuthDataProtectionStores：明確區分 missing、denied、unavailable、corrupt、identityMismatch。",
    "texts": [
      [
        "bl",
        224,
        1008,
        "Data Protection stores"
      ],
      [
        "bs",
        224,
        1030,
        "兩個 item／strict version 1 codec"
      ],
      [
        "bs",
        224,
        1046,
        "clientID 綁定完整六欄 bundle"
      ]
    ]
  },
  {
    "id": "rest",
    "plane": "integration",
    "band": "band-integration",
    "x": 610,
    "y": 980,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubRestClient",
    "about": "本 topic 沿用雙 client，不改 generic HTTP auth。",
    "texts": [
      [
        "bl",
        634,
        1008,
        "GitHubRestClient"
      ],
      [
        "bs",
        634,
        1030,
        "既有 REST port／HTTP 行為"
      ],
      [
        "bs",
        634,
        1046,
        "401 recovery 最多一次"
      ]
    ]
  },
  {
    "id": "graphql",
    "plane": "integration",
    "band": "band-integration",
    "x": 1020,
    "y": 980,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": true,
    "name": "GitHubGraphQLClient",
    "about": "產品最小驗收使用 REST；GraphQL 的相同 provider 契約由自動化驗證。",
    "texts": [
      [
        "bl",
        1044,
        1008,
        "GitHubGraphQLClient"
      ],
      [
        "bs",
        1044,
        1030,
        "既有 GraphQL port／HTTP 行為"
      ],
      [
        "bs",
        1044,
        1046,
        "401 recovery 最多一次"
      ]
    ]
  },
  {
    "id": "config",
    "plane": "storage",
    "band": "band-storage",
    "x": 405,
    "y": 1255,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "configuration item",
    "about": "唯一 service 內獨立 configuration account；不和 credential item 做跨 item transaction。",
    "texts": [
      [
        "bl",
        429,
        1283,
        "configuration item"
      ],
      [
        "bs",
        429,
        1305,
        "clientID + clientSecret"
      ],
      [
        "bs",
        429,
        1321,
        "可信設定；保存成功才開始授權"
      ]
    ]
  },
  {
    "id": "credential",
    "plane": "storage",
    "band": "band-storage",
    "x": 815,
    "y": 1255,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "credential item",
    "about": "DPK=true、synchronizable=false、精確 group/service/account；同 actor 序列化 update-first。",
    "texts": [
      [
        "bl",
        839,
        1283,
        "credential item"
      ],
      [
        "bs",
        839,
        1305,
        "clientID + 六欄 credential bundle"
      ],
      [
        "bs",
        839,
        1321,
        "AfterFirstUnlockThisDeviceOnly"
      ]
    ]
  },
  {
    "id": "authorize",
    "plane": "remote",
    "band": "band-remote",
    "x": 200,
    "y": 1505,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHub authorize",
    "about": "正式 OAuth App 授權入口；取消與拒絕不可誤建連線。",
    "texts": [
      [
        "bl",
        224,
        1533,
        "GitHub authorize"
      ],
      [
        "bs",
        224,
        1555,
        "瀏覽器授權／使用者同意"
      ],
      [
        "bs",
        224,
        1571,
        "offline_access + S256 PKCE"
      ]
    ]
  },
  {
    "id": "token",
    "plane": "remote",
    "band": "band-remote",
    "x": 610,
    "y": 1505,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHub token endpoint",
    "about": "使用 production ephemeral fetcher；無 redirect、cookie、cache 或一般 retry。",
    "texts": [
      [
        "bl",
        634,
        1533,
        "GitHub token endpoint"
      ],
      [
        "bs",
        634,
        1555,
        "初次 exchange／真 refresh"
      ],
      [
        "bs",
        634,
        1571,
        "輪替接受後必須完整保存"
      ]
    ]
  },
  {
    "id": "api",
    "plane": "remote",
    "band": "band-remote",
    "x": 1020,
    "y": 1505,
    "w": 380,
    "h": 104,
    "r": 10,
    "dash": false,
    "name": "GitHub REST／GraphQL API",
    "about": "產品 probe 以 GET /user 回傳有效 id 與非空 login 證明連線可用。",
    "texts": [
      [
        "bl",
        1044,
        1533,
        "GitHub REST／GraphQL API"
      ],
      [
        "bs",
        1044,
        1555,
        "唯讀帳號結果與雙 client"
      ],
      [
        "bs",
        1044,
        1571,
        "不涉及 PR Inbox／Reader 業務"
      ]
    ]
  }
];
const EDGES = [
  {
    "to": "coordinator",
    "pts": [
      [
        390,
        359
      ],
      [
        390,
        506
      ]
    ],
    "from": "user"
  },
  {
    "to": "leaf",
    "pts": [
      [
        580,
        560
      ],
      [
        596,
        560
      ],
      [
        596,
        400
      ],
      [
        1210,
        400
      ],
      [
        1210,
        363
      ]
    ],
    "from": "coordinator"
  },
  {
    "to": "relay",
    "pts": [
      [
        580,
        540
      ],
      [
        606,
        540
      ]
    ],
    "from": "coordinator"
  },
  {
    "to": "session",
    "pts": [
      [
        800,
        614
      ],
      [
        800,
        680
      ],
      [
        390,
        680
      ],
      [
        390,
        776
      ]
    ],
    "from": "relay"
  },
  {
    "to": "provider",
    "pts": [
      [
        540,
        614
      ],
      [
        540,
        700
      ],
      [
        800,
        700
      ],
      [
        800,
        776
      ]
    ],
    "from": "coordinator"
  },
  {
    "to": "scope",
    "pts": [
      [
        1210,
        614
      ],
      [
        1210,
        776
      ]
    ],
    "from": "probe"
  },
  {
    "to": "scope",
    "pts": [
      [
        990,
        830
      ],
      [
        1016,
        830
      ]
    ],
    "from": "provider"
  },
  {
    "to": "stores",
    "pts": [[200, 590], [136, 590], [136, 1030], [196, 1030]],
    "label": {
      "s": "al",
      "x": 120,
      "y": 810,
      "t": "初次授權 bundle 完整保存",
      "rot": -90,
      "anchor": "center"
    },
    "from": "coordinator"
  },
  {
    "to": "stores",
    "pts": [
      [
        700,
        884
      ],
      [
        700,
        940
      ],
      [
        480,
        940
      ],
      [
        480,
        976
      ]
    ],
    "from": "provider"
  },
  {
    "to": "rest",
    "pts": [
      [
        1120,
        884
      ],
      [
        1120,
        940
      ],
      [
        800,
        940
      ],
      [
        800,
        976
      ]
    ],
    "from": "scope"
  },
  {
    "to": "graphql",
    "pts": [
      [
        1210,
        884
      ],
      [
        1210,
        976
      ]
    ],
    "from": "scope"
  },
  {
    "to": "config",
    "pts": [
      [
        350,
        1084
      ],
      [
        350,
        1160
      ],
      [
        595,
        1160
      ],
      [
        595,
        1251
      ]
    ],
    "from": "stores"
  },
  {
    "to": "credential",
    "pts": [
      [
        480,
        1084
      ],
      [
        480,
        1180
      ],
      [
        1005,
        1180
      ],
      [
        1005,
        1251
      ]
    ],
    "from": "stores"
  },
  {
    "to": "authorize",
    "pts": [
      [
        800,
        255
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
        1540
      ],
      [
        196,
        1540
      ]
    ],
    "from": "browser",
    "label": {
      "s": "al",
      "x": 84,
      "y": 900,
      "t": "瀏覽器正式授權",
      "rot": -90,
      "anchor": "center"
    }
  },
  {
    "to": "token",
    "pts": [
      [
        990,
        860
      ],
      [
        1450,
        860
      ],
      [
        1450,
        1420
      ],
      [
        800,
        1420
      ],
      [
        800,
        1501
      ]
    ],
    "from": "provider"
  },
  {
    "to": "api",
    "pts": [
      [
        990,
        1035
      ],
      [
        1436,
        1035
      ],
      [
        1436,
        1440
      ],
      [
        1210,
        1440
      ],
      [
        1210,
        1501
      ]
    ],
    "from": "rest"
  }
];
const TEXTS = [
  {
    "s": "title",
    "x": 160,
    "y": 86,
    "t": "Rivet — 持續可用的 GitHub 連線"
  },
  {
    "s": "sub",
    "x": 160,
    "y": 118,
    "t": "產品入口 → 完整保存 → 程序重啟 → 自動刷新 → API"
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
    "t": "實線：產品表面與外部設施"
  },
  {
    "s": "legend",
    "x": 1143,
    "y": 134,
    "t": "色彩：責任層"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1686,
    "t": "不變量：取消不等於 settled；重授權先退休舊 provider／scope；保存失敗不可宣告就緒。"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1706,
    "t": "限制：同機、同 GUI 使用者、同 App 身分／group／certificate／固定位置與有效 profile；profile 更新後讀回仍未驗證。"
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
const CHIPS = [
  {
    "x": 1046,
    "y": 123,
    "w": 9,
    "h": 13,
    "fill": "#94A3B8"
  },
  {
    "x": 1059,
    "y": 123,
    "w": 9,
    "h": 13,
    "fill": "#7DD3FC"
  },
  {
    "x": 1072,
    "y": 123,
    "w": 9,
    "h": 13,
    "fill": "#A78BFA"
  },
  {
    "x": 1085,
    "y": 123,
    "w": 9,
    "h": 13,
    "fill": "#4ADE80"
  },
  {
    "x": 1098,
    "y": 123,
    "w": 9,
    "h": 13,
    "fill": "#F6821F"
  }
];
