---
title:  双向短信支持客户互动

products: messaging/sms

description:  可编程短信不仅仅对单向通知有用。当您将出站通知与入站消息结合使用时，就会在公司与客户之间建立类似于聊天的交互。

languages:
  - Ruby


---

双向短信支持客户互动
==========

可编程短信不仅仅对单向通知有用。当您将出站通知与入站消息结合使用时，就会在公司与客户之间建立类似于聊天的交互。

教程内容
----

您会看到在应用中建立双向通信有多简单；您向客户的电话号码发送送货通知，并在客户想要更改送货时段时处理他们的回复。

您的应用的工作流为：

```sequence_diagram
Participant App
Participant Vonage
Participant Phone number
App->>Vonage: Request to SMS API
Vonage-->>App: Response from SMS API
Note over Vonage: Request accepted
Vonage->>Phone number: Send delivery notification SMS
Phone number->>Vonage: Reply to delivery notification
Vonage-->>App: Send reply to webhook endpoint
App->>Vonage: Request to SMS API
Vonage-->>App: Response from SMS API
Note over Vonage: Request accepted
Vonage->>Phone number: Send acknowledgement in SMS
```

为此，请执行以下操作：

1. [配置 Vonage 虚拟号码](#configure-a-nexmo-virtual-number) - 租用虚拟号码并为入站消息设置 Webhook 端点
2. [创建基本 Web 应用](#create-a-basic-web-app) - 创建一个 Web 应用来收集客户的电话号码。
3. [发送短信通知](#send-an-sms-notification) - 通过短信向客户发送送货通知并请求回复。
4. [处理回复短信](#process-the-reply-sms) - 处理并确认短信回复。

先决条件
----

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。如果您是在本地进行开发，则必须使用诸如 [ngrok](https://ngrok.com/) 之类的工具
* 本教程的源代码来自 [https://github.com/Nexmo/ruby-customer-engagement/](https://github.com/Nexmo/ruby-customer-engagement/)。

配置 Vonage 虚拟号码
--------------

Vonage 将入站消息转发到与您的 Vonage 虚拟号码关联的 Webhook 端点。

您使用[开发人员 API](/api/developer/numbers) 或 [Nexmo CLI](https://github.com/nexmo/nexmo-cli) 管理虚拟号码。以下示例使用 [Nexmo CLI](https://github.com/nexmo/nexmo-cli) 租用 Vonage 号码：

```sh
$ nexmo number:buy --country_code US --confirm
Number purchased: 441632960960
```

然后将虚拟号码与 (link: \#process-inbound-sms text: 处理入站短信) 的 Webhook 端点关联：

```sh
> nexmo link:sms 441632960960 http://www.example.com/update
Number updated
```

> **注意** ：在将 Webhook 端点与虚拟号码关联之前，请确保服务器正在运行并公开可用。Vonage 必须从 Webhook 端点收到 200 OK 响应才能成功完成配置。如果您是在本地进行开发，则使用诸如 [ngrok](https://ngrok.com/) 之类的工具将本地 Web 服务器公开到互联网。

您已经配置了虚拟号码，现在可以发送短信送货通知。

创建基本 Web 应用
-----------

使用 [Sinatra](http://www.sinatrarb.com/) 创建单页 Web 应用：

**Gemfile** 

```ruby
source 'https://rubygems.org'

# our web server
gem 'sinatra'
```

**app.rb** 

```ruby
# web server and flash messages
require 'sinatra'

# load environment variables
# from .env file
require 'dotenv'
Dotenv.load

# Index
# - collects a phone number
#
get '/' do
  erb :index
end
```

添加 HTML 表单以收集您将向其发送通知短信的电话号码：

**views/index.erb** 

```erb
<form action="/notify" method="post">
  <div class="field">
    <label for="number">
      Phone number
    </label>
    <input type="text" name="number">
  </div>

  <div class="actions">
    <input type="submit" value="Notify">
  </div>
</form>
```

该表单以短信 API 所需的 [E.164](https://en.wikipedia.org/wiki/E.164) 格式捕获电话号码：

发送短信通知
------

在本教程中，要发送短信，需向应用添加 [Vonage Server SDK for Ruby](https://github.com/Nexmo/nexmo-ruby)：

**Gemfile** 

```ruby
# the nexmo library
gem 'nexmo'
# a way to load environment
# variables
gem 'dotenv'
```

使用您的 Vonage API [密钥和密码](/concepts/guides/authentication)初始化客户端：

**app.rb** 

```ruby
# nexmo library
require 'nexmo'
nexmo = Nexmo::Client.new(
  api_key: ENV['VONAGE_API_KEY'],
  api_secret: ENV['VONAGE_API_SECRET']
)
```

> **注意** ：请勿将 API 凭据存储在代码中，而应使用环境变量。

要接收通知短信回复，请在向[短信 API](/api/sms) 发出请求时将虚拟号码设置为出站消息的 SenderID：

**app.rb** 

```ruby
# Notify
# - Send the user their delivery
#   notification, asking them
#   to respond back if they
#   want to make any changes
#
post '/notify' do
  notification = "Your delivery is scheduled for tomorrow between " +
                 "8am and 2pm. If you wish to change the delivery date please " +
                 "reply by typing 1 (tomorrow), 2 (Thursday) or 3 (deliver to"
                 "post office) below.\n\n";

  nexmo.sms.send(
    from: ENV['VONAGE_NUMBER'],
    to: params['number'],
    text: notification
  )

  "Notification sent to #{params['number']}"
end
```

要验证客户是否已收到此短信，请检查[传递回执](/messaging/sms/guides/delivery-receipts)。本教程不验证传递回执。

处理回复短信
------

当客户回复您的通知短信时，Vonage 会将[入站消息](/api/sms#inbound-sms)转发到与您的虚拟号码关联的 Webhook 端点。

在本教程应用中，您将处理传入 Webhook，提取文本和号码，并向客户发回确认消息。

**app.rb** 

```ruby
# Receive incoming message
#
# - Receives incoming SMS
#   message, stores it, and
#   notifies sender
#
get '/update' do
  choice = params['text']
  number = params['msisdn']

  # You can store or validate
  # the choice made here

  message = "Thank you for picking option #{choice}. " +
            "Your delivery is now fully scheduled in."

  nexmo.sms.send(
    from: ENV['VONAGE_NUMBER'],
    to: number,
    text: message
  )

  body ''
end
```

存储和验证客户输入超出了本教程的范围。

现在，回复您先前收到的短信。您应该看到它被您的应用处理，并在几秒钟内收到您选择的确认消息。

结语
---

在应用中收发短信就是这么简单。通过几行代码，你已经用短信 API 向客户的手机发送了一条短信，处理了一条回复，并回复了一条确认消息。

获取代码
----

本教程的所有代码都可以在[双向短信支持客户互动 GitHub 存储库](https://github.com/Nexmo/ruby-customer-engagement)中找到。

资源
---

* [Ruby Server SDK](https://github.com/Nexmo/nexmo-ruby)
* [短信](/sms)
* [短信 API 参考指南](/api/sms)

