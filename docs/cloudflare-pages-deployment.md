# Cloudflare Pages へのデプロイ設定

このリポジトリは GitHub Actions を使って Cloudflare Pages へ自動デプロイします。
`main` ブランチへの push で本番環境へ、Pull Request ではプレビュー環境へそれぞれデプロイされます。

## 事前準備

- Cloudflare アカウント
- Cloudflare Pages プロジェクトの作成（初回のみ）

## 手順

### 1. Cloudflare Pages プロジェクトを作成する

Cloudflare ダッシュボードで Pages プロジェクトを作成します。プロジェクト名は任意ですが、後の手順で使用します。

または、Wrangler CLI でコマンドラインから作成することもできます:

```sh
npx wrangler pages project create <プロジェクト名>
```

### 2. Cloudflare API トークンを発行する

[Cloudflare ダッシュボード](https://dash.cloudflare.com/?to=/:account/api-tokens) → **Create Token** → **Create Custom Token** で、以下の権限を設定してトークンを発行します。

| 権限 | 種別 |
|------|------|
| `Cloudflare Pages` - Edit | Account |

発行したトークンは次の手順で使います。

### 3. Cloudflare Account ID を確認する

Cloudflare ダッシュボード右サイドバーの **Account ID** をコピーします。

### 4. GitHub にシークレットと変数を登録する

GitHub リポジトリの **Settings → Secrets and variables → Actions** で以下を設定します。

#### Secrets（機密情報）

| 名前 | 値 |
|------|-----|
| `CLOUDFLARE_API_TOKEN` | 手順 2 で発行した API トークン |
| `CLOUDFLARE_ACCOUNT_ID` | 手順 3 で確認した Account ID |

#### Variables（非機密の設定値）

| 名前 | 値 |
|------|-----|
| `CLOUDFLARE_PROJECT_NAME` | 手順 1 で作成した Pages プロジェクト名 |

### 5. `wrangler.toml` を編集する

[wrangler.toml](../wrangler.toml) の `name` フィールドを、手順 1 で作成したプロジェクト名に変更します:

```toml
name = "<プロジェクト名>"
pages_build_output_dir = "_build/default/"
```

> **フォークした場合:** `name` をご自身のプロジェクト名に変更し、`CLOUDFLARE_PROJECT_NAME` 変数も同じ値に設定してください。

## ワークフローの動作

[.github/workflows/cloudflare-pages.yml](../.github/workflows/cloudflare-pages.yml) が以下の処理を行います:

1. OCaml 環境をセットアップし、`dune build @dev` でビルド
2. `_build/default/` を Cloudflare Pages へデプロイ
3. Pull Request の場合、プレビュー URL をコメントに投稿

| トリガー | デプロイ先 |
|----------|-----------|
| `main` への push | 本番環境 |
| Pull Request | プレビュー環境（PR ごとに一意の URL） |
