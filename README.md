# ai-realtime-chat

Action Cable × Gemini API によるリアルタイムAIチャットアプリ。RUNTEQ「Action Cableで作る！リアルタイムAIチャット開発」コース（全12章）の学習課題として実装。

## 主な機能

- WebSocket（Action Cable）によるAI応答の逐次ストリーミング配信、停止（Stop）
- 会話履歴の永続化とスライディングウィンドウによる文脈保持
- 会話ごとのsystem prompt / モデル / 温度などの設定とプロンプトプリセット
- メール+パスワード認証、ユーザー単位の会話スコープ、Rack::Attack + Redisによる二段階レート制御
- Markdown表示・コードハイライト・コピー、トークン概算、再生成・編集して再送・送信失敗時の再試行
- 複数会話の一覧・検索・切替、送信時の自動タイトル生成
- 会話のMarkdown / HTML / PDFエクスポート、期限付き共有リンク、アーカイブ
- 画像・PDF添付のアップロードと要約（マルチモーダル）

## 技術スタック

- Ruby on Rails 7.2 / PostgreSQL / Redis / Action Cable
- Tailwind CSS v4 / Importmap
- [gemini-ai](https://github.com/gbaptista/gemini-ai) gem（Google Gemini API, `generative-language-api` / `v1beta`）
- Docker Compose（開発環境）

> 教材はOpenAI APIを前提としていますが、本実装ではGemini APIに置き換えています。

## セットアップ（開発環境）

```bash
docker compose build
docker compose run --rm app bin/rails db:create db:migrate db:seed
docker compose up
```

- アプリ: http://localhost:3001
- シードユーザー: `user@example.com` / `password`

### Gemini APIキーの設定

```bash
docker compose run --rm -e EDITOR=nano app bin/rails credentials:edit
```

```yaml
gemini:
  api_key: "AQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

## 本番デプロイについて

`Dockerfile`（本番用マルチステージビルド）、`config/database.yml` / `config/environments/production.rb` はRender × Neon × Upstash構成を想定して用意済みです（ローカルでのビルド確認のみ実施、実デプロイ・実サービスへの接続は未実施）。デプロイには以下の環境変数が必要です。

- `RAILS_MASTER_KEY`
- `DATABASE_URL`（Neon, Pooling URL推奨）
- `REDIS_URL`（Upstash）
- `ALLOWED_ORIGINS` / `CABLE_URL`（必要に応じて）
