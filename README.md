# ゴクゴク - 双子の授乳記録

双子の授乳のタイミングを、夫婦で**ワンタップ**で記録・共有する、シンプルなアプリです。

- **1画面で2人分。** 2人を並べたホームで、「全員」ボタンなら1タップで2人分を記録できます。
- **夫婦で共有。** パートナーの記録が、数秒で自分の画面にも反映されます。
- **登録なし。** メールもパスワードも要りません。開いてすぐ使えます。招待コードで夫婦をつなぎます。
- **授乳だけ。** 機能を絞り、夜中に片手でも迷わない画面にしています。

> 開発中です(MVP)。まず作り手の家族で使い、TestFlight で配布します。

## なぜ作るか
双子の親として、既存の育児アプリは多機能すぎて続かず、シンプルなアプリには夫婦の共有と双子の記録がありませんでした。その両方を満たすものを作ります。詳しくは [競合調査](docs/competitors.md) を参照してください。

## ドキュメント
| 文書 | 内容 |
|---|---|
| [仕様書](docs/spec.md) | 何を作るか(要件、画面、受け入れ条件) |
| [設計書](docs/design.md) | どう作るか(アーキテクチャ、データモデル、API、設計判断) |
| [競合調査](docs/competitors.md) | 位置づけと差別化 |
| [ADR](docs/adr) | 設計判断の記録 |

主な設計判断:
- [0001 構成の方針](docs/adr/0001-architecture.md): API の独立、冪等な記録、論理削除
- [0002 React Native のアプリにする](docs/adr/0002-react-native.md): PWA と比較して決めた理由
- [0003 登録なしの匿名アカウント](docs/adr/0003-anonymous-account.md): メールを持たない理由と、その弱点への対策
- [0004 外からの定期実行で掃除する](docs/adr/0004-scheduled-cleanup.md): 保持期間を過ぎたデータを、ジョブ基盤なしで確実に消す方法

## 構成
| ディレクトリ | 内容 |
|---|---|
| `api/` | Rails 8.1(API mode)+ PostgreSQL |
| `app/` | React Native(Expo)のアプリ(これから作る) |
| `web/` | Next.js。説明ページ、プライバシーポリシー、招待リンクの受け口(静的出力) |

本番は、API を Fly.io、DB を Neon、Web を Cloudflare Pages に置く予定です(設計書 8 章)。

## 開発
```sh
docker compose up -d --build   # DB と API (http://localhost:3001)
curl localhost:3001/up         # ヘルスチェック
```

API のテスト / Lint:
```sh
docker compose exec api bin/rails test
docker compose exec api bin/rubocop
```

コミットのルールは [CONTRIBUTING.md](CONTRIBUTING.md) を参照してください。
