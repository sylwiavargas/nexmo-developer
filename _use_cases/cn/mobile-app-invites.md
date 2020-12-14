---
title:  移动应用邀请

products: messaging/sms

description:  通过短信将客户链接到您的应用

languages:
  - Ruby


---

移动应用邀请
======

随着 Android 和 iOS 上的应用数量不断增加，让人们轻松地在商店和网络上找到您的应用非常重要。

如果您的移动应用有网站，那您可能很熟悉以下按钮：

![移动应用按钮示例](/images/app_store_play_badges.png)

这些按钮使任何人都可以轻松地为其移动设备导航到正确的商店。但是，如果用户不是移动用户，则此流程会迅速崩溃。当您的用户使用台式计算机时会发生什么？通过使用 **移动应用推广** ，您可以通过以短信的形式向浏览用户发送应用链接，快速将其转化为有效客户。

教程内容
----

您会看到使用 Vonage API 和库构建移动应用邀请系统有多简单：

1. [创建 Web 应用](#create-a-web-app) - 创建具有下载按钮的 Web 应用。
2. [检测桌面用户](#detect-desktop-users) - 为桌面或移动用户显示正确的下载按钮。
3. [收集姓名和电话号码](#collect-a-name-and-phone-number) - 对于桌面浏览器，显示一个表单来收集用户信息。
4. [以短信形式发送下载链接](#send-the-download-link-in-an-sms) - 向用户发送包含应用下载链接的短信。
5. [运行本教程](#run-this-tutorial) - 运行本教程并将下载 URL 发送至您的手机号码。

先决条件
----

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。如果您在本地进行开发，则必须使用诸如 [ngrok](https://ngrok.com/)（[请参阅我们的 ngrok 教程博客文章](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)）之类的工具
* 本教程的源代码，来自 [https://github.com/Nexmo/ruby-mobile-app-promotion](https://github.com/Nexmo/ruby-mobile-app-promotion)

创建 Web 应用
---------

对于您的客户界面，请使用 [Sinatra](http://www.sinatrarb.com) 和 [rack](https://github.com/nakajima/rack-flash) 创建一个单页 Web 应用：

**Gemfile** 

```ruby
source 'https://rubygems.org'

gem 'sinatra'
gem 'rack-flash3'
```

**app.rb** 

```ruby
# web server and flash messages
require 'sinatra'
require 'rack-flash'
use Rack::Flash

# enable sessions and set the
# session secret
enable :sessions
set :session_secret, '123456'

# Index
# - shows our landing page
#   with links to download
#   from the app stores or
#   via SMS
#
get '/' do
  erb :index
end
```

将 Google 和 iOS 商店按钮添加到 Web 应用的 HTML 中：

**views/index.erb** 

```erb
<a href="https://play.google.com/store/apps/details?id=com.imdb.mobile">
  <!-- place this image in a public/ folder -->
  <img src="google-play-badge.png" />
</a>

<a href="https://geo.itunes.apple.com/us/app/google-official-search-app/id284815942">
  <!-- place this image in a public/ folder -->
  <img src='app-store-badge.svg' />
</a>
```

> 要想轻松点，可以[下载按钮](/assets/archives/app-store-badges.zip)。

检测桌面用户
------

要检查用户是从移动设备还是桌面设备进行浏览，请解析 *request.user\_agent* ：

**Gemfile** 

    gem 'browser'

**app.rb** 

```ruby
# determine the browser and platform
require 'browser'

before do
  @browser ||= Browser.new(request.user_agent)
end
```

使用 `browser.device` 的值为移动设备显示正确的商店按钮：

**views/index.erb** 

```erb
<% unless @browser.platform.ios? %>
  <a href="https://play.google.com/store/apps/details?id=com.imdb.mobile">
    <!-- place this image in a public/ folder -->
    <img src="google-play-badge.png" />
  </a>
<% end %>

<% unless @browser.platform.android? %>
  <a href="https://geo.itunes.apple.com/us/app/google-official-search-app/id284815942">
    <!-- place this image in a public/ folder -->
    <img src='app-store-badge.svg' />
  </a>
<% end %>
```

如果用户未使用移动设备，则显示短信下载按钮：

**views/index.erb** 

```erb
<% unless @browser.device.mobile? %>
  <a href="/download">
    <!-- place this image in a public/ folder -->
    <img src='sms-badge.png' />
  </a>
<% end %>
```

此按钮如下所示：

![移动应用按钮示例](/images/sms-badge.png)

收集姓名和电话号码
---------

如果用户从桌面进行浏览，则使用 HTML 表单收集将接收您的短信的电话号码和姓名（如果用户想将此链接发送给朋友）。当用户点击主页中的短信下载按钮时，向他们显示输入表单来输入电话号码。

**app.rb** 

```rb
# Download page
# - a page where the user
#   fills in their phone
#   number in order to get a
#   download link
#
get '/download' do
  erb :download
end
```

该表单以短信 API 所需的 [E.164](https://en.wikipedia.org/wiki/E.164) 格式捕获电话号码：

**views/download.erb** 

```erb
<form action="/send_sms" method="post">
  <div class="field">
    <label for="number">
      Phone number
    </label>
    <input type="text" name="number">
  </div>

  <div class="actions">
    <input type="submit" value="Continue">
  </div>
</form>
```

当用户点击 *继续* 时，使用短信 API 向他们发送一条文本消息，其中包含应用的下载 URL。

您也可以在短信中发送正确商店的直接链接。为此，您需要更新表单，以便用户可以选择他们的设备。

通过短信发送下载链接
----------

您通过调用一次短信 API 来发送短信，Vonage 负责所有路由和传递。下图显示了本教程中发送短信的工作流：

```sequence_diagram
Participant App
Participant Vonage
Participant Phone number
Note over App: Initialize library
App->>Vonage: Request to SMS API
Vonage-->>App: Response from SMS API
Note over Vonage: Request accepted
Vonage->>Phone number: Send SMS
```

在本教程中，要发送短信，需向应用添加 [Ruby Server SDK](https://github.com/Nexmo/nexmo-ruby)：

**Gemfile** 

```rb
gem 'nexmo'
```

使用您的 Vonage API [密钥和密码](/concepts/guides/authentication)初始化客户端：

**app.rb** 

```rb
# Nexmo library
require 'nexmo'
nexmo = Nexmo::Client.new(
  api_key: ENV['VONAGE_API_KEY'],
  api_secret: ENV['VONAGE_API_SECRET']
)
```

> **注意** ：请勿将 API 凭据存储在代码中，而应使用环境变量。

使用已初始化的库向[短信 API](/api/sms#send-an-sms) 发出请求：

**app.rb** 

```rb
# Send SMS
# - when submitted this action
#   sends an SMS to the user's
#   phone number with a download
#   link
#
post '/send_sms' do
  message = "Download our app on #{url('/')}"

  # send the message
  response = nexmo.sms.send(
    from: 'My App',
    to: params[:number],
    text: message
  ).messages.first

  # verify the response
  if response.status == '0'
    flash[:notice] = 'SMS sent'
    redirect '/'
  else
    flash[:error] = response.error-text
    erb :download
  end
end
```

*status* 响应参数指示 Vonage 是否已接受您的请求并发送短信。

要验证用户是否已收到此短信，请检查(link: messaging/sms-api/api-reference\#delivery\_receipt text: 传递回执)。本教程不验证传递回执。

运行本教程
-----

要运行本教程，请执行以下操作：

1. 启动应用。
2. 使用桌面浏览器导航到 Web 应用。
3. 点击短信按钮。系统会显示电话号码表单。
4. 填写并提交表单。几秒钟内，您就会收到一条包含应用链接的短信。

> **注意** ：如果短信包含 *localhost* 或 *127\.0\.0\.1* 链接，请使用诸如 [ngrok](https://ngrok.com/) 之类的工具，以便教程代码创建一个移动设备可以连接的 URL。

结语
---

至此完成。现在，您可以让任何人通过短信给自己或朋友发送一个直接链接，以下载您的移动应用。为此，您收集了电话号码，向用户发送了链接，检测了他们的平台，并向他们显示了正确的下载链接供其继续操作。

获取代码
----

本教程的所有代码都可以在[移动应用邀请教程 GitHub 存储库](https://github.com/Nexmo/ruby-customer-engagement)中找到。

资源
---

* [Ruby Server SDK](https://github.com/Nexmo/nexmo-ruby)
* [短信](/sms)
* [短信 API 参考指南](/api/sms)

