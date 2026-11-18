const W = 1480, H = 1560;
const PLANES = {
  "caller": {
    "c": "#94A3B8",
    "label": "呼叫端"
  },
  "owner": {
    "c": "#7DD3FC",
    "label": "還原 owner"
  },
  "runtime": {
    "c": "#A78BFA",
    "label": "既有連線能力"
  },
  "outside": {
    "c": "#F6821F",
    "label": "外部系統"
  }
};
const BANDS = [
  {
    "id": "band-caller",
    "plane": "caller",
    "x": 160,
    "y": 200,
    "w": 1260,
    "h": 160,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 230,
      "t": "呼叫端：唯一連線生命週期"
    }
  },
  {
    "id": "band-owner",
    "plane": "owner",
    "x": 160,
    "y": 450,
    "w": 1260,
    "h": 180,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 480,
      "t": "新增：啟動還原入口"
    }
  },
  {
    "id": "band-runtime",
    "plane": "runtime",
    "x": 160,
    "y": 720,
    "w": 1260,
    "h": 180,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 750,
      "t": "沿用：準備與 token 生命週期"
    }
  },
  {
    "id": "band-adapters",
    "plane": "runtime",
    "x": 160,
    "y": 990,
    "w": 1260,
    "h": 180,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 1020,
      "t": "沿用：設定、憑證與刷新依賴"
    }
  },
  {
    "id": "band-outside",
    "plane": "outside",
    "x": 160,
    "y": 1260,
    "w": 1260,
    "h": 180,
    "alpha": 0.5,
    "hdr": {
      "x": 184,
      "y": 1290,
      "t": "外部：本地儲存與 GitHub"
    }
  }
];
const BOXES = [
  {
    "id": "caller",
    "plane": "caller",
    "band": "band-caller",
    "x": 200,
    "y": 260,
    "w": 1180,
    "h": 88,
    "r": 10,
    "dash": false,
    "name": "產品組裝端",
    "about": "呼叫端持有唯一 owner，明示重試而不替換仍存活的連線。",
    "texts": [
      [
        "bl",
        224,
        288,
        "產品組裝端"
      ],
      [
        "bs",
        224,
        312,
        "保留一個 restorer；本次不接產品 UI"
      ]
    ]
  },
  {
    "id": "configuration",
    "plane": "owner",
    "band": "band-owner",
    "x": 200,
    "y": 510,
    "w": 340,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "設定組裝",
    "about": "讀取設定並建立 clientID-bound store 與正式 fetcher。",
    "texts": [
      [
        "bl",
        224,
        538,
        "設定組裝"
      ],
      [
        "bs",
        224,
        562,
        "只在尚無 provider 時讀取"
      ]
    ]
  },
  {
    "id": "restorer",
    "plane": "owner",
    "band": "band-owner",
    "x": 590,
    "y": 510,
    "w": 790,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "GitHubOAuthStartupRestorer",
    "about": "一次 prepare，等待原工作真正收尾才釋放 busy。",
    "texts": [
      [
        "bl",
        614,
        538,
        "GitHubOAuthStartupRestorer"
      ],
      [
        "bs",
        614,
        562,
        "busy／取消收尾；成功或失敗皆保留原 provider"
      ]
    ]
  },
  {
    "id": "scope",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 200,
    "y": 780,
    "w": 340,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "GitHubClientScope",
    "about": "沿既有 prepare 完成 snapshot 與本地 Bearer 驗證。",
    "texts": [
      [
        "bl",
        224,
        808,
        "GitHubClientScope"
      ],
      [
        "bs",
        224,
        832,
        "本地 ready 後交付雙 clients"
      ]
    ]
  },
  {
    "id": "provider",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 590,
    "y": 780,
    "w": 440,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "OAuthTokenProvider",
    "about": "scope 與 clients 共用同一 provider，不因重試重建。",
    "texts": [
      [
        "bl",
        614,
        808,
        "OAuthTokenProvider"
      ],
      [
        "bs",
        614,
        832,
        "刷新、保存、single-flight 與 terminal"
      ]
    ]
  },
  {
    "id": "clients",
    "plane": "runtime",
    "band": "band-runtime",
    "x": 1080,
    "y": 780,
    "w": 300,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "REST／GraphQL",
    "about": "本地 ready 不保證遠端權限或後續請求成功。",
    "texts": [
      [
        "bl",
        1104,
        808,
        "REST／GraphQL"
      ],
      [
        "bs",
        1104,
        832,
        "後續 request 沿既有 policy"
      ]
    ]
  },
  {
    "id": "config-store",
    "plane": "runtime",
    "band": "band-adapters",
    "x": 200,
    "y": 1050,
    "w": 340,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "Configuration Store",
    "about": "不存在與讀取故障各自分類。",
    "texts": [
      [
        "bl",
        224,
        1078,
        "Configuration Store"
      ],
      [
        "bs",
        224,
        1102,
        "讀既存 OAuth App 設定"
      ]
    ]
  },
  {
    "id": "credential-store",
    "plane": "runtime",
    "band": "band-adapters",
    "x": 590,
    "y": 1050,
    "w": 440,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "Credential Store",
    "about": "不清除或替換其他帳號的憑證。",
    "texts": [
      [
        "bl",
        614,
        1078,
        "Credential Store"
      ],
      [
        "bs",
        614,
        1102,
        "綁定 clientID，完整保存 rotation"
      ]
    ]
  },
  {
    "id": "fetcher",
    "plane": "runtime",
    "band": "band-adapters",
    "x": 1080,
    "y": 1050,
    "w": 300,
    "h": 88,
    "r": 10,
    "dash": true,
    "name": "Token Fetcher",
    "about": "只在原 provider 決定需要刷新時執行。",
    "texts": [
      [
        "bl",
        1104,
        1078,
        "Token Fetcher"
      ],
      [
        "bs",
        1104,
        1102,
        "沿用正式 refresh 契約"
      ]
    ]
  },
  {
    "id": "keychain",
    "plane": "outside",
    "band": "band-outside",
    "x": 200,
    "y": 1320,
    "w": 560,
    "h": 88,
    "r": 10,
    "dash": false,
    "name": "Data Protection Keychain",
    "about": "本次不執行真人或 live DPK 驗收。",
    "texts": [
      [
        "bl",
        224,
        1348,
        "Data Protection Keychain"
      ],
      [
        "bs",
        224,
        1372,
        "Caller 提供既有 access group"
      ]
    ]
  },
  {
    "id": "github",
    "plane": "outside",
    "band": "band-outside",
    "x": 820,
    "y": 1320,
    "w": 560,
    "h": 88,
    "r": 10,
    "dash": false,
    "name": "GitHub.com",
    "about": "本次受控測試不新增真 OAuth 或遠端權限保證。",
    "texts": [
      [
        "bl",
        844,
        1348,
        "GitHub.com"
      ],
      [
        "bs",
        844,
        1372,
        "既有 OAuth refresh 與 resource API"
      ]
    ]
  }
];
const EDGES = [
  {
    "from": "caller",
    "to": "restorer",
    "pts": [
      [
        985,
        348
      ],
      [
        985,
        506
      ]
    ],
    "label": {
      "s": "al",
      "x": 1000,
      "y": 420,
      "t": "啟動還原"
    }
  },
  {
    "from": "configuration",
    "to": "restorer",
    "pts": [
      [
        540,
        554
      ],
      [
        586,
        554
      ]
    ]
  },
  {
    "from": "restorer",
    "to": "scope",
    "pts": [
      [
        750,
        598
      ],
      [
        750,
        675
      ],
      [
        370,
        675
      ],
      [
        370,
        776
      ]
    ],
    "label": {
      "s": "al",
      "x": 480,
      "y": 663,
      "t": "prepare 一次"
    }
  },
  {
    "from": "scope",
    "to": "provider",
    "pts": [
      [
        540,
        824
      ],
      [
        586,
        824
      ]
    ]
  },
  {
    "from": "provider",
    "to": "credential-store",
    "pts": [
      [
        810,
        868
      ],
      [
        810,
        1046
      ]
    ],
    "label": {
      "s": "al",
      "x": 825,
      "y": 965,
      "t": "讀回／完整保存"
    }
  },
  {
    "from": "provider",
    "to": "fetcher",
    "pts": [
      [
        960,
        868
      ],
      [
        960,
        945
      ],
      [
        1230,
        945
      ],
      [
        1230,
        1046
      ]
    ],
    "label": {
      "s": "al",
      "x": 1080,
      "y": 933,
      "t": "必要刷新"
    }
  },
  {
    "from": "configuration",
    "to": "config-store",
    "pts": [
      [
        200,
        554
      ],
      [
        120,
        554
      ],
      [
        120,
        1094
      ],
      [
        196,
        1094
      ]
    ],
    "label": {
      "s": "al",
      "x": 104,
      "y": 960,
      "t": "讀設定"
    }
  },
  {
    "from": "config-store",
    "to": "keychain",
    "pts": [
      [
        370,
        1138
      ],
      [
        370,
        1316
      ]
    ],
    "label": {
      "s": "al",
      "x": 385,
      "y": 1230,
      "t": "讀取"
    }
  },
  {
    "from": "credential-store",
    "to": "keychain",
    "pts": [
      [
        700,
        1138
      ],
      [
        700,
        1316
      ]
    ],
    "label": {
      "s": "al",
      "x": 715,
      "y": 1230,
      "t": "保存"
    }
  },
  {
    "from": "fetcher",
    "to": "github",
    "pts": [
      [
        1230,
        1138
      ],
      [
        1230,
        1316
      ]
    ],
    "label": {
      "s": "al",
      "x": 1245,
      "y": 1230,
      "t": "refresh"
    }
  }
];
const TEXTS = [
  {
    "s": "title",
    "x": 160,
    "y": 86,
    "t": "OAuth 冷啟動連線還原"
  },
  {
    "s": "sub",
    "x": 160,
    "y": 118,
    "t": "讀取設定 → 保留 provider → 準備連線 → 交付結果"
  },
  {
    "s": "legend",
    "x": 1082,
    "y": 86,
    "t": "虛線：我們擁有的契約"
  },
  {
    "s": "legend",
    "x": 1082,
    "y": 110,
    "t": "實線：呼叫端或外部系統"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1500,
    "t": "取消不回滾成功保存；重疊立即 busy；重試不重建 terminal provider。"
  },
  {
    "s": "bn",
    "x": 160,
    "y": 1520,
    "t": "不新增 BC、UI、登入或清除能力；本地 ready 不保證遠端權限。"
  }
];
const SWATCHES = [];
const CHIPS = [];
