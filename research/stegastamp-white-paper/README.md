# StegaStampは白い紙に使えるか：再調査

調査日：2026-10-09（America/Denver）。26出典記録、学術・一次Web／公式実装・開発者フォーラム・書誌API。複数の同一著者／同一組織資料を独立した再現実験とは数えていない。文献調査であり、新規の印刷・Questベンチマークは実施していない。

## 要約

- **白い紙に入力できることと、目立たず実カメラで読めることは別。** StegaStampの著者自身が、単色では変更が目立つと説明し、白黒文書の失敗報告に類似画像での再学習を勧めている。🟡 一次資料による確度：[issue10](https://github.com/tancik/StegaStamp/issues/10)。
- **既製モデルを白い余白にそのまま使うのは第一候補ではない。** 写真用モデルであり、細い上辺線にIDを隠す手法ではない。🟡 [原論文§4・§5.5](https://arxiv.org/pdf/1904.05343)、[公式実装](https://github.com/tancik/StegaStamp)。
- **「約900」は採用件数とは確認できない。** 今回GitHubは885 stars、OpenAlex正式出版記録は491引用。前者を見た可能性はあるが、元の画面がないため断定しない。🟡 [GitHub API](https://api.github.com/repos/tancik/StegaStamp)、[OpenAlex](https://api.openalex.org/works/https://doi.org/10.1109/CVPR42600.2020.00219)。
- **次の候補はTrustMark。** ブラウザ復号実装と印刷デモはあるが、白い余白・Quest10枚同時の成功証明はない。🟡 [FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md)、[JS](https://github.com/adobe/trustmark/blob/main/js/README.md)、[Know How](https://www.adobe.com/max/2024/sessions/project-know-how-gs3-8.html)。

## 1. 何をしている技術か

StegaStamp（CVPR2020）は画像とメッセージをニューラルencoderに入れ、画像全体に小さなRGB変更を加える。カメラ画像を切り出し／補正してニューラルdecoderでビットを復元する。登録画像との最近傍マッチングではないが、紙を完全に無加工のまま識別する技術でもない。400×400入力・100bit符号語を用い、標準実装は56bitメッセージ＋40bit BCH＋4bit padding。56bitは約7.2×10^16通りの理論的ID空間で、同時に追える枚数ではない。🟡 [原論文§4・補遺](https://arxiv.org/pdf/1904.05343)、[encode_image.py](https://github.com/tancik/StegaStamp/blob/master/encode_image.py)、[モデル](https://github.com/tancik/StegaStamp/blob/master/models.py)。

原著は100枚のImageNet自然画像と18種類のプリンタ／画面・カメラ組合せを評価し、1,890枚の撮影画像で平均bit accuracy98.7%を報告する。これは「白紙のID認識率98.7%」でも「10枚同時成功率」でもない。実験写真・著者動画と書誌情報は確認できるが、その条件を今のQuestに移す保証にはならない。🟡 [論文§5.2](https://arxiv.org/pdf/1904.05343)、[著者ページ](https://www.matthewtancik.com/stegastamp)、[CVPR](https://openaccess.thecvf.com/content_CVPR_2020/html/Tancik_StegaStamp_Invisible_Hyperlinks_in_Physical_Photographs_CVPR_2020_paper.html)。

## 2. 白紙・白い余白・白黒論文

| 対象 | 証拠 | 今回の判断 |
|---|---|---|
| 写真／テクスチャがある絵 | 原著印刷撮影実験 | 実在する有力方式。ただし距離・機材依存 |
| 白黒文書 | 利用者が見た目悪化と携帯撮影復号失敗を報告 | 既製モデルで成功保証なし |
| 大きな白い余白／単色 | 著者が変更の可視性を明示 | 隠しやすい条件ではない |
| 細い上辺だけ | 既製実装は400×400画像を加工 | そのまま対応しない。再設計／学習が必要 |
| 黒L字＋白い面への透かし | L字で領域補正する設計は考えられる | 未実験の設計仮説 |

表の根拠は[原論文§5.5](https://arxiv.org/pdf/1904.05343)、[白黒文書issue10](https://github.com/tancik/StegaStamp/issues/10)、[encode実装](https://github.com/tancik/StegaStamp/blob/master/encode_image.py)。単に白い紙をPNGにして入力することはできるが、出力は微妙な色／明暗模様を含む画像になる。何も印刷されない真っ白な領域からIDを読み出すわけではない。🟡 実装に基づく説明。

特に直接的なのはissue10。質問者は白黒文書のwatermarkの見た目が悪く、携帯で撮った画像から抽出できないと記載。著者Tancikは対象に似た画像で再学習・hyperparameter調整を勧め、**“a flat color … Any modification would be very visible.”** と返信している。原著§5.5も大きな低周波領域ではresidualが知覚可能と明記。🟡 [著者返信](https://github.com/tancik/StegaStamp/issues/10)、[原著](https://arxiv.org/pdf/1904.05343)。利用者一例は失敗率の統計ではないが、今回の白紙への一般化を疑う具体的根拠になる。[非自然画像issue44](https://github.com/tancik/StegaStamp/issues/44)も補助的な失敗報告で、独立評価ではない。🔴 利用者報告の確度。

別問題として検出器の制約がある。公式READMEは検出がサイズに敏感でnoisyと記載し、推奨動画入力1920×1080、検出器訓練コード未同梱と説明する。白い外枠がないと検出できないという報告は「白い面の中にIDを隠せる」証拠ではなく、領域検出の話。黒L字による補正はこの領域検出の一部を代替できても、復号signalの不足は解消しない。🟡／🔴 [README](https://github.com/tancik/StegaStamp)、[issue5](https://github.com/tancik/StegaStamp/issues/5)、[訓練コード](https://github.com/tancik/StegaStamp/blob/master/train.py)。

## 3. 「900」の読み方：引用と実利用を分ける

2026-10-09取得の[GitHub API](https://api.github.com/repos/tancik/StegaStamp)では **885 stars／224 forks**。これは関心・複製の指標であり、885製品の導入を意味しない。同日[OpenAlex正式出版DOI](https://api.openalex.org/works/https://doi.org/10.1109/CVPR42600.2020.00219)は **491 citations**、記録更新2026-10-08。[同名検索](https://api.openalex.org/works?search=StegaStamp&per-page=5)に別preprint記録28引用もあるが、重複論文を確認せず491＋28を全体引用数にしない。🟡 取得時点のデータベース値。

Google Scholar／Semantic Scholarは対象集合・統合方法が異なるので、別の数値になり得る。今回はSemantic Scholar APIが429、Google検索ページが有効な結果本文を返さず、**Scholarで約900引用あるという主張は未確認**。ユーザーがどのサイトの数字を見たかも未確定。公式READMEは研究用code releaseを説明しているが、世界の実導入件数は示していない。🟡 [公式README](https://github.com/tancik/StegaStamp)、[OpenAlex検索](https://api.openalex.org/works?search=StegaStamp&per-page=5)。

## 4. 後続技術と、どこまで実用と言えるか

| 方式 | 実在する証拠 | 白紙／Questへの留保 |
|---|---|---|
| StegaStamp | 原論文・印刷カメラデモ・公開モデル | 白領域で目立つ、検出器ボトルネック |
| TrustMark | 100bit透かし、BCH、Python・JS、印刷デモ | 同条件の白紙10枚同時未測定 |
| RoSteALS | autoencoder latentで隠す研究 | 白紙上辺専用ではない |
| Stable Signature | 生成画像のdecoderに署名を組み込む | 汎用の白紙タグとは別 |
| VideoSeal | 画像／動画透かし公式実装 | 無地紙のprint-camera証明とは別 |

比較対象の一次資料：[StegaStamp](https://arxiv.org/pdf/1904.05343)、[TrustMark](https://arxiv.org/abs/2311.18297)、[RoSteALS](https://arxiv.org/abs/2304.03400)、[Stable Signature](https://github.com/facebookresearch/stable_signature)、[VideoSeal](https://github.com/facebookresearch/videoseal)。名称にinvisible／robustがあっても「小さい無地紙で頑健」を意味しない。

**TrustMarkを次の比較候補にする理由**：Adobe公式FAQはRGB画像への適用、印刷前CMYK変換、強度1.0→1.5にすると紙・カード・一部素材への印刷を生き残ったと述べ、Adobe MAX2024 **Project Know How**デモをリンクしている。一方、強度を上げるのは可視性とトレードオフであり、白紙で無視できる見た目とは確認できない。🟡 [FAQ印刷項目](https://github.com/adobe/trustmark/blob/main/FAQ.md)、[Know How公式](https://www.adobe.com/max/2024/sessions/project-know-how-gs3-8.html)。

TrustMarkは100bit生payloadからBCH保護IDへ変換し、スキーマで訂正強度と容量を選ぶ。JS復号はONNX＋WebGPUを利用できるが、README例は画像uploadであり、Questカメラmulti-targetの完成品ではない。モデルは数十MB、GPU timingsは作者環境の値でQuest性能ではない。🟡 [実装](https://github.com/adobe/trustmark)、[設定](https://github.com/adobe/trustmark/blob/main/python/CONFIG.md)、[JS](https://github.com/adobe/trustmark/blob/main/js/README.md)、[FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md)。

⚡ **「印刷対応」と「カメラで失敗」の整合**：TrustMark FAQは印刷対応のデモを示す一方、[issue21](https://github.com/adobe/trustmark/issues/21)はupload成功・カメラ失敗を報告し、後に“**Solved**”の一言で閉じている。解決条件は書かれていない。特定実装・環境で可能であっても、任意の遠距離・照明・露出・サイズで成功するという保証ではない。🔴 利用者報告、🟡 公式条件付き主張。

CAIのDurable Content Credentialsはmetadata＋watermark＋fingerprintingの組合せを説明し、TrustMarkはC2PA soft-bindingの一覧に載る。これは運用への接続を示すが、**StegaStampそのものの900件採用**や、白紙のロバストな読み取り件数には換算できない。🟡 [CAI](https://contentauthenticity.org/blog/durable-content-credentials)、[C2PA一覧](https://github.com/c2pa-org/softbinding-algorithm-list)、[TrustMark FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md)。

## 5. 今回の設計への提案

**設計判断（実証前の提案）**：今の「内容が自由な白紙＋目立たない上辺＋黒L字」なら、まず細い高コントラストの明示コードを改善する。大面積の薄い透かしを白余白に埋めるのは、可視性・カメラ復号・処理コストの別の研究課題。StegaStampで高容量を得ても、1枚の撮影画素が不足する問題はなくならない。[原著§5.5](https://arxiv.org/pdf/1904.05343)、[著者返信](https://github.com/tancik/StegaStamp/issues/10)、[TrustMark FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md)。

**試すなら小さく段階的に**：白一色／文字だけ／写真付きの同面積coverを作り、StegaStampとTrustMark強度1.0・1.5を比較する。まずデジタル復号→印刷1枚→Quest1枚→10枚。L字で同じ領域をrectifyし、成功bit／ECC valid／ID誤認識／見た目／速度を別計測。印刷サイズ・カメラ上のpx面積・距離を必ず残す。これは実験案で、本調査では実行していない。[StegaStamp実装](https://github.com/tancik/StegaStamp/blob/master/encode_image.py)、[TrustMark設定](https://github.com/adobe/trustmark/blob/main/python/CONFIG.md)。

**特許／利用条件**：StegaStamp公式コードはMIT license。TrustMark公式はコード・取得モデルともMITと記載する。ただしコードライセンスは関連特許を網羅したFTOの判定ではない。本報告は白紙適性の再調査で、新しい特許の権利範囲判断を行っていない。[StegaStamp LICENSE](https://github.com/tancik/StegaStamp/blob/master/LICENSE)、[TrustMark README](https://github.com/adobe/trustmark)。

## Research Log

| Round | 問い／クエリ | 方法 | 得られたこと・次の探索 |
|---|---|---|---|
| 1 | StegaStamp white blank images / citations | 既存メモ検索・web tools→direct HTTP | memory/web tools handler unavailable。既存報告と原著へ |
| 2 | paper §5.5 / code capacity / ImageNet evaluation | PDF全文・公式code | 白い領域の可視性と56bitを確認 |
| 3 | white documents / low frequency / camera | 全issue一覧＋著者返信 | issue10が直接的な反証。issue5と混同しない |
| 4 | citations vs stars / OpenAlex DOI and preprint | 公開API | 885stars、491正式引用、28preprint。Scholar未確認 |
| 5 | TrustMark print blank / browser / deployment | FAQ・paper・JS・MAX・CAI・C2PA | 印刷実例と製品接続を確認、白紙保証なし |
| 6 | camera failure / subsequent methods | issues・RoSteALS・Stable Signature・VideoSeal | 利用者反例と適用範囲の違いを確認 |

日本語「StegaStamp 白 用紙 電子透かし」も検索したがGoogle本文取得は実結果を返さず、独立した日本語評価を加えられなかった。社会的採用の総数・網羅的関連研究集合を確定する調査ではなく、対象適性に絞ったsource-grounded reviewである。

## Open Questions

- ユーザーが見た「約900」はstarsかScholar引用か。元のページでのみ確定可能。
- 白紙／白余白を用いた、既製・再学習StegaStampの印刷撮影成功率と可視性。
- TrustMark強度1.5の白紙での視覚的な受容性とQuest推論速度。
- 10枚同時に十分な透かしsignalを確保する紙サイズ・カメラpx数。
- 標準化への掲載、研究デモ、実際の製品導入件数の相互区別。公開資料に件数なし。

## Sources

取得日はいずれも2026-10-09。APIは時点snapshotで、後日リンク先の数値は変わる。複数のcode／READMEは同じ研究の資料であり独立検証ではない。

| # | 資料 | 種別 |
|---|---|---|
| 1 | [StegaStamp原論文](https://arxiv.org/pdf/1904.05343) | 学術 |
| 2 | [CVPR出版ページ](https://openaccess.thecvf.com/content_CVPR_2020/html/Tancik_StegaStamp_Invisible_Hyperlinks_in_Physical_Photographs_CVPR_2020_paper.html) | 学術 |
| 3 | [著者プロジェクト](https://www.matthewtancik.com/stegastamp) | 一次Web |
| 4 | [公式README](https://github.com/tancik/StegaStamp) | 実装 |
| 5 | [encode_image.py](https://github.com/tancik/StegaStamp/blob/master/encode_image.py) | 実装 |
| 6 | [models.py](https://github.com/tancik/StegaStamp/blob/master/models.py) | 実装 |
| 7 | [train.py](https://github.com/tancik/StegaStamp/blob/master/train.py) | 実装 |
| 8 | [白黒文書issue10・著者返信](https://github.com/tancik/StegaStamp/issues/10) | 開発者フォーラム |
| 9 | [非自然画像issue44](https://github.com/tancik/StegaStamp/issues/44) | 開発者フォーラム |
| 10 | [検出白枠issue5](https://github.com/tancik/StegaStamp/issues/5) | 開発者フォーラム |
| 11 | [OpenAlex正式出版記録](https://api.openalex.org/works/https://doi.org/10.1109/CVPR42600.2020.00219) | 書誌API |
| 12 | [OpenAlex同名検索](https://api.openalex.org/works?search=StegaStamp&per-page=5) | 書誌API |
| 13 | [GitHub統計API](https://api.github.com/repos/tancik/StegaStamp) | 実装統計 |
| 14 | [TrustMark論文](https://arxiv.org/abs/2311.18297) | 学術 |
| 15 | [TrustMark公式実装](https://github.com/adobe/trustmark) | 実装 |
| 16 | [TrustMark FAQ](https://github.com/adobe/trustmark/blob/main/FAQ.md) | 一次Web |
| 17 | [TrustMark JS](https://github.com/adobe/trustmark/blob/main/js/README.md) | 実装 |
| 18 | [TrustMark設定](https://github.com/adobe/trustmark/blob/main/python/CONFIG.md) | 実装 |
| 19 | [Project Know How](https://www.adobe.com/max/2024/sessions/project-know-how-gs3-8.html) | 一次Web・デモ |
| 20 | [CAI Durable Content Credentials](https://contentauthenticity.org/blog/durable-content-credentials) | 一次Web |
| 21 | [C2PA soft binding一覧](https://github.com/c2pa-org/softbinding-algorithm-list) | 標準実装 |
| 22 | [TrustMarkカメラissue21](https://github.com/adobe/trustmark/issues/21) | 開発者フォーラム |
| 23 | [RoSteALS](https://arxiv.org/abs/2304.03400) | 学術 |
| 24 | [Stable Signature](https://github.com/facebookresearch/stable_signature) | 実装 |
| 25 | [VideoSeal](https://github.com/facebookresearch/videoseal) | 実装 |
| 26 | [StegaStampライセンス](https://github.com/tancik/StegaStamp/blob/master/LICENSE) | 実装 |
