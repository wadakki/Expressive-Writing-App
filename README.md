# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## アプリ名
  筆記開示アプリ
## サービス概要
  ・1,980年代に生まれた心理療法である筆記開示をするためのアプリ
  ・筆記開示とは、8分以上今日起こった嫌なことを感情や思考を包み隠さず書き記すことで、メンタルを
    安定させる手法である。それを本アプリで作成・投稿する。
  ・書く前と書いた後の幸福度を数値化し、メンタルの安定度を可視化する。

## このサービスへの思い・作りたい理由
  過去、仕事で嫌なことがあったときに、メンタルが激しく落ち込んだ時がありました。その時に筆記開示の手法を知って、実施することでメンタルの安定につながることができました。当時は、グーグルカレンダーに登録して、筆記開示を実施していました。しかし、グーグルカレンダーはあくまで予定を登録するところであり、かつ一覧性がないので、過去の部分を振り返るのに使いずらいと感じていました。また、自由に書けるがゆえに最初は何から書こうかと迷ってしまうときもありました。そのため、筆記開示に特化して設問を設けるようなアプリを作成したいと考えました。

## ユーザー層について
ターゲット
  年齢層：19～50歳
  職業：会社員全般
  悩み
    日々、上司や部下の関係で悩んでおり、また、相談できる相手もいない状態である。
    それゆえSNS等を使ってつぶやきたいが、他人が見たら稚拙なような内容と感じるのでは？
    と考え、投稿するのに躊躇してしまう。しかし、吐き出しを見つけたい。
  ほしいもの
    だれにも見られたくないが、悩みを吐き出したい。

## サービスの利用イメージ
  匿名性の高いアプリ内で、設問に従って記入をすればおのずと筆記開示の手法を用いた心理療法ができ、
  感情及び思考の整理ができてメンタル面が安定する。また、メンタルが安定することで、仕事のパフォーマンス
  も上がる。

## ユーザーの獲得について
  1) 身近な家族、友人に使用して頂く
  2) Xでアプリを投稿し、使用してもらえる人を増やす。

## サービスの差別化ポイント・推しポイント
  カレンダーアプリとの比較
    …カレンダーアプリは自由に記入ができるが、筆記開示の設問が記載されているわけではないので、
      筆記開示を書くことに慣れていないと何から書いていいのかが迷ってしまう。また、一覧性がないので、
      振り返りがしにくい。
  muute
    …その日の感情や何について考えたをタグ登録し、かつ日記を書けるアプリ。
      しかし、これもカレンダーアプリと同じで自由に書けてしまうがゆえに書き出しに迷ってしまいます。
  本アプリの推しポイント
    …筆記開示ができるように設問を設けることで、この知識がなくても、筆記開示のメリットを享受できる。
    一覧性を持たせることで自分が過去に何を書いたのかを見ることができる。
    筆記開示をする前とした後の幸福度を数値化して達成感を持たせる。
    ・設問内容案(誤字脱字は気にせず書いてください。)
      1)今日、実際に起きたことを思いつく限り書いてください。
      2)1で書いた中で、ネガティブな感情を抱いたことは何ですか？
        場面ごとに巻き起こった感情を書いてください。
      3)1で書いた中で、ポジティブな感情を抱いたことは何ですか？
      　場面ごとに巻き起こった感情を書いてください。
      4)1で書いた中で、許せない相手・事象は何ですか？
      　それについて感じたことを何も考えずに吐き出してください。
      5)明日一日どういう一日にしたいですか？
    ・幸福度の数値化について
      →自己評価で1~10までの数値を選んでもらいます。1が不幸で、10が幸福となります。

## 機能候補
  ・MVPで作成したいもの
    1)ユーザー登録機能
    2)ログイン機能
    3)ログアウト機能
    4)筆記開示(登録・一覧表示・更新・削除)機能
    5)筆記開示作成時の8分タイマーの追加
    6)LINE通知機能
      →LINE通知を追加する理由としては、投稿忘れを防ぐためです。
  ・本リリースまでにほしい機能
    1)カレンダー登録機能
    2)幸福度点数をグラフ化する
    3)感情分析

## 使用する技術スタック
- 使用する言語・フレームワーク
    Ruby 3.3.10, Rails 7.2.3
- データベース
    PostgreSQL
- デプロイ先
    Render
- 使用予定のライブラリ
    LINE通知機能：line-bot-api
    定期実行処理:sidekiq-cron
    バックグラウンド処理：Sidekiq
    カレンダー登録機能：icalendar
    感情分析機能：Google Cloud Natural Language API
- Gemについて
    sidekiq
      LINE通知送信
    sidekiq-cron
      LINE定期通知
    line-bot-api
      LINEプッシュ通知
-継続的に使ってもらうために
  最初の1週間は毎日投稿していなかったら通知をして記入を促す。
  記入していない日は筆記開示による効果をLINEで通知する。

##　画面遷移図のURL
https://www.figma.com/design/iP6c8lZISGSxfOIV3WiTdz/%E7%84%A1%E9%A1%8C?node-id=0-1&t=VhqE8mXWGCtIeKfF-1

## LINE Messaging API設定

LINE通知にはLINE Developersで作成したMessaging APIチャネルが必要です。

1. [LINE Developersコンソール](https://developers.line.biz/console/)でプロバイダーを作成する
2. Messaging APIチャネルを作成する
3. Messaging API設定からチャネルアクセストークンを発行する
4. `.env.example`を参考に`.env`へ設定する

```dotenv
LINE_CHANNEL_ACCESS_TOKEN=your-channel-access-token
```

環境変数を変更した後はwebコンテナとSidekiqコンテナを再作成します。

```bash
docker compose up -d --force-recreate web sidekiq
```

テスト通知を行うユーザーには、LINEのユーザーIDを持つ`LineConnection`が必要です。
ローカル確認ではRails consoleから作成できます。

```ruby
user = User.first
user.create_line_connection!(line_user_id: "LINE_USER_ID", status: :linked)
```

ログイン後のプロフィール画面で「テスト通知を送信する」を押すと、通知ジョブがSidekiqへ登録されます。
Sidekiqによる送信成功時は`line_connections.last_notified_at`が更新されます。

## アプリURL環境変数

LINEリマインダー通知本文に含める筆記開示URLは、RailsのURLヘルパーから生成します。
本番環境ではデプロイ先の環境変数として、公開中のドメインを設定してください。

```dotenv
APP_HOST=your-production-domain.example
APP_PROTOCOL=https
```

通常の本番環境ではポート指定は不要です。非標準ポートを使う場合のみ、必要に応じて`APP_PORT`を追加してください。
開発環境では`.env`、RenderではWeb ServiceとBackground WorkerそれぞれのEnvironment Variablesに設定します。
`.env.example`はキー名の見本として使い、実際の値や秘密情報はコミットしません。

## Sidekiq・Redis設定

LINE通知はActive JobからSidekiqへ登録し、Redisをキューとして非同期送信します。
開発環境ではDocker Composeが`redis`と`sidekiq`を起動します。

```dotenv
REDIS_URL=redis://redis:6379/0
SIDEKIQ_CONCURRENCY=5
```

初回または構成変更後はサービスをビルドして起動します。

```bash
docker compose up -d --build
docker compose ps
docker compose logs -f sidekiq
```

SidekiqがRedisへ接続できることは、次のコマンドでも確認できます。

```bash
docker compose exec sidekiq bundle exec rails runner 'puts ActiveJob::Base.queue_adapter.class.name'
docker compose exec redis redis-cli ping
```

Renderでは、Web Serviceとは別に次のサービスを作成します。

1. 永続化を有効にしたRender Key Valueを作成する
2. 同じリポジトリからBackground Workerを作成する
3. Background Workerの開始コマンドを`bundle exec sidekiq -C config/sidekiq.yml`にする
4. Web ServiceとBackground Workerの両方へ`REDIS_URL`、`APP_HOST`、`APP_PROTOCOL`を設定する
5. Background Workerへ`DATABASE_URL`、`RAILS_MASTER_KEY`、`LINE_CHANNEL_ACCESS_TOKEN`を設定する
6. LINE Loginを使用するWeb Serviceへ`LINE_LOGIN_CHANNEL_ID`、`LINE_LOGIN_CHANNEL_SECRET`、`LINE_LOGIN_REDIRECT_URI`を設定する

Sidekiq用Redisはキャッシュと共用せず、ジョブが削除されない永続ストアとして使用します。

## LINEリマインダー定期実行

sidekiq-cronが日本時間で1分ごとに通知設定を確認します。
次の条件をすべて満たすユーザーへLINEリマインダーを送信します。

- 通知設定がON
- 現在の曜日が`reminder_days`に含まれる
- 現在時刻が`notification_time`と同じ時・分
- LINE連携状態が`linked`
- 同じ予定時刻のリマインダーをまだ送信していない

cron定義は`config/schedule.yml`、二重送信防止の最終送信日時は
`notification_settings.last_reminded_at`で管理します。

登録されたcron Jobは次のコマンドで確認できます。

```bash
docker compose exec sidekiq bundle exec rails runner \
  'job = Sidekiq::Cron::Job.find("line_reminder_dispatch"); puts [job&.name, job&.cron, job&.status].join(" | ")'
```

開発環境で送信対象を手動確認する場合は、プロフィール画面の通知曜日と通知時刻を
現在の日本時間に合わせ、Sidekiqログを表示します。

```bash
docker compose logs -f sidekiq
```

送信成功後はRails consoleで`last_reminded_at`を確認できます。

```ruby
user = User.find_by!(email: "登録済みメールアドレス")
user.notification_setting.last_reminded_at
```

## LINE Login設定

プロフィールからLINEアカウントを連携するには、Messaging APIチャネルと同じプロバイダーにLINE Loginチャネルを作成します。
LINE LoginチャネルのコールバックURLには、アプリの`/line_connection/callback`を登録してください。

開発環境では、`.env`に以下を設定します。

```dotenv
LINE_LOGIN_CHANNEL_ID=your-line-login-channel-id
LINE_LOGIN_CHANNEL_SECRET=your-line-login-channel-secret
LINE_LOGIN_REDIRECT_URI=http://localhost:3000/line_connection/callback
```

本番環境では、`LINE_LOGIN_REDIRECT_URI`を公開中のHTTPS URLへ変更します。

```dotenv
LINE_LOGIN_REDIRECT_URI=https://your-production-domain.example/line_connection/callback
```

LINE DevelopersのLINE Loginチャネルにも、使用する環境のコールバックURLを登録してください。
`LINE_LOGIN_REDIRECT_URI`と登録URLは、プロトコル、ドメイン、ポート、パスまで完全に一致させる必要があります。

本番環境のチャネルID、チャネルシークレット、リダイレクトURIは、デプロイ先の環境変数として設定し、リポジトリへコミットしません。
開発用と本番用でLINE Loginチャネルを分ける場合は、`LINE_LOGIN_CHANNEL_ID`と`LINE_LOGIN_CHANNEL_SECRET`も環境ごとに設定します。

環境変数を変更した後はwebコンテナを再作成します。

```bash
docker compose up -d --force-recreate web
```

プロフィール画面の「LINE連携する」からLINE認証を行います。認証に成功すると、以下の両方が保存されます。

- `authentications`: `provider: line`とLINEユーザーID
- `line_connections`: LINE通知先と連携日時

連携解除時は、ログイン中ユーザーのLINE用`Authentication`と`LineConnection`を同一トランザクションで削除します。
