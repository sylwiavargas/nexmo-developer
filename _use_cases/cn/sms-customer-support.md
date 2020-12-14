---
title:  短信客户支持

products: messaging/sms

description:  可编程短信不仅仅对单向通知有用。当您将出站通知与入站消息结合使用时，就会在公司与客户之间建立类似于聊天的交互。

languages:
  - Ruby


---

短信客户支持
======

短信的通用性使其成为了客户支持的通用解决方案。电话号码可以打印、读出以及放在网站上，从而让线上或线下的任何人都能与您的公司互动。

通过短信提供客户支持是一种简单的方式，可以为任何有电话连接到移动网络的人提供一个完整的双向通信系统。

教程内容
----

您将使用 Vonage 的 API 和库为短信客户支持构建一个简单的系统。

为此，请执行以下操作：

* [创建基本 Web 应用](#a-basic-web-application) - 创建一个基本 Web 应用程序，其中包含用于开具支持票证的链接。
* [购买号码](#purchase-a-phone-number) - 购买 Vonage 电话号码以发送短信和接收入站短信
* [处理入站短信](#process-an-inbound-sms) - 接受并处理从客户处收到的入站短信
* [发送包含票证编号的短信回复](#send-an-sms-reply-with-a-ticket-number) - 开具票证后回复新的票证编号

先决条件
----

为了使本教程正常工作，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。如果您是在本地进行开发，则应使用诸如 [ngrok](https://ngrok.com/) 之类的工具
* 本教程的源代码来自 [https://github.com/Nexmo/ruby-sms-customer-support/](https://github.com/Nexmo/ruby-sms-customer-support/)

基本 Web 应用程序
-----------

本教程从一个只有一页的简单 Web 应用程序开始。用户可以点击链接打开自己的短信应用并请求支持。您的应用将收集入站短信并开具新票证。最后，应用将向用户回复一条新短信，以确认其票证编号。

```sequence_diagram
Participant Phone
Participant Vonage
Participant App
Phone->>Vonage: SMS 1
Vonage-->>App: Webhook
App->>Vonage: SMS Request
Vonage->>Phone: SMS 2
```

**首先创建一个基本应用。** 

```sh
rails new customer-support
cd customer-support
rake db:create db:migrate
```

该页面将位于应用程序的根目录中，并提供包含一些预填充文本的短信应用的链接。

**添加第一页** 

```sh
rails g controller pages index
```

**app/views/pages/index.html.erb** 

```erb
<h1>ACME Support</h1>

<p>
  <a href="sms://<%= ENV['VONAGE_NUMBER'] %>?body=Hi ACME, I'd like some help with: " class='button'>
    Get support via SMS
  </a>
</p>
```

有了这个，就可以启动服务器了。

**启动服务器** 

```sh
rails server
```

购买电话号码
------

必须租用一个 Vonage 电话号码，应用才能接收短信。可以从 [Dashboard](https://dashboard.nexmo.com) 购买电话号码，也可以使用 [Nexmo CLI](https://github.com/nexmo/nexmo-cli) 直接通过命令行购买。

```sh
> nexmo number:buy --country_code US --confirm
Number purchased: 447700900000
```

最后，必须向 Vonage 告知收到入站短信时要向其发出 HTTP 请求的 Webhook 端点。这可以使用 [Dashboard](https://dashboard.nexmo.com/your-numbers) 或 [Nexmo CLI](https://github.com/nexmo/nexmo-cli) 来完成。

```sh
> nexmo link:sms 447700900000 http://[your.domain.com]/support
Number updated
```

> *注意* ：在尝试为 Webhook 设置新的回调 URL 之前，请确保您的服务器正在运行并公开可用。设置新的 Webhook 时，Vonage 将调用您的服务器以确认其可用。

⚓ 处理短信

处理入站短信
------

当客户发送短信时，Vonage 将通过移动运营商网络接收它。Vonage 随后将向您的应用程序发出 Webhook。

该 Webhook 将包含已发送的原始文本、消息的源电话号码以及其他一些参数。有关更多详细信息，请参阅[入站消息](/api/sms#inbound-sms)文档。

您的应用应处理传入 Webhook、提取文本和号码、开具新票证或更新现有票证。如果这是客户的第一个请求，应用应向客户发回一条包含其票证编号的确认消息。

这通过保存传入消息并在号码还没有开票的情况下开具新票证来实现。

**添加票证和消息模型** 

```sh
rails g controller support index
rails g model Ticket number
rails g model Message text ticket:references
rake db:migrate
```

**app/controllers/support\_controller.rb** 

```ruby
class SupportController < ApplicationController
  def index
    save_message
    send_response
    render nothing: true
  end

  private

  def ticket
    @ticket ||= Ticket.where(
      number: params[:msisdn]
    ).first_or_create
  end

  def save_message
    message = Message.create(
      text: params[:text],
      ticket: ticket
    )
  end
```

发送包含票证编号的短信回复
-------------

要向客户的短信发送确认信息，请将 Vonage Server SDK 添加到您的项目中。

**Gemfile** 

```ruby
gem 'nexmo'
gem 'dotenv-rails'
```

> *注意* ：要初始化 Server SDK，您需要向其传递您的 [API 密钥和密码](https://dashboard.nexmo.com/settings)。强烈建议您不要将 API 凭据存储在代码中，而应使用环境变量。

初始化库后，应用程序现在可以[发送短信](/api/sms#send-an-sms)。仅当这是该票证上的第一条消息时才发送响应。

```ruby
def send_response
  return if ticket.messages.count > 1

  client = Nexmo::Client.new
  result = client.sms.send(
    from: ENV['VONAGE_NUMBER'],
    to: ticket.number,
    text: "Dear customer, your support" \
          "request has been registered. " \
          "Your ticket number is #{ticket.id}. " \
          "We intend to get back to any " \
          "support requests within 24h."
  )
end
```

结语
---

在本教程中，您学习了如何从客户的电话接收短信并向他们发送短信回复。通过运行这些代码片段，您现在获得了使用 Vonage 短信 API 的短信客户支持解决方案。

获取代码
----

[GitHub 提供了](https://github.com/Nexmo/ruby-sms-customer-support/)本教程的所有代码以及更多内容。

资源
---

* [短信](/sms)
* [短信 API 参考指南](/api/sms)

