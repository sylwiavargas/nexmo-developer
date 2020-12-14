---
title:  欺诈评分和电话号码验证

products: number-insight

description:  您可以结合使用 Number Insight Advanced API 和 Verify API 来构建自己的欺诈检测系统。借助这种方法，您可以保护组织免受欺诈性交易的侵害，同时使大多数客户的流程变得顺畅。

languages:
  - Node


---

欺诈评分和电话号码验证
===========

您可以结合使用 [Number Insight Advanced API](/number-insight) 和 [Verify API](/verify/api-reference/) 来构建自己的欺诈检测系统。借助这种方法，您可以保护组织免受欺诈性交易的侵害，同时使大多数客户的流程变得顺畅。

教程内容
----

在本教程中，您将学习如何使用 Number Insight Advanced API 预筛选客户提供的号码，并且只有当您的检查表明可能存在欺诈行为时，才使用 PIN 码验证这些号码。

您将构建一个应用程序，使用户可以通过提供其电话号码来注册帐户。您将使用 Number Insight Advanced API 检查该号码，以确定该号码是否位于其 IP 地址所在的国家/地区。如果该号码所属的国家/地区（或漫游国家/地区）与用户 IP 所在的国家/地区不匹配，则将其标记为潜在的欺诈号码。然后，您将使用 Verify API 的双重认证 (2FA) 功能来确认用户拥有该号码。

为此，请执行以下操作：

* [创建应用程序](#create-an-application) - 创建一个接受用户电话号码的应用程序。
* [安装 Vonage Node Server SDK](#install-the-nexmo-rest-client-api-for-node) - 向应用程序添加 Vonage 功能。
* [配置应用程序](#configure-the-application) - 从配置文件中读取 API 密钥、密码以及其他设置。
* [处理电话号码](#process-a-phone-number) - 构建用于处理用户提交的号码的逻辑。
* [检查可能的欺诈行为](#check-for-possible-fraud) - 使用 Number Insight API 确定关联设备所在的位置。
* [发送验证码](#send-a-verification-code) - 当号码触发验证步骤时，使用 Verify API 将验证码发送到用户的手机。
* [检查验证码](#check-the-verification-code) - 检查用户提供的验证码是否有效。

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)的 `api_key` 和 `api_secret` - 如果您还没有帐户，请注册一个。
* 对 Node.js 和 `express` 软件包有基本了解。
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。对于本地开发，我们建议使用 [ngrok](https://ngrok.com/)。

> [学习使用方法 `ngrok`](/tools/ngrok)

创建应用程序
------

您将构建应用程序，使服务器和欺诈检测业务逻辑彼此独立。

1. 创建基本应用程序目录。

   ```sh
   $ mkdir fraudapp;
   $ cd fraudapp;
   $ mkdir lib views 
   ```

2. 使用 `npm init` 为项目创建 `package.json` 文件，并在出现提示时将 `lib/server.js` 文件指定为入口点。

3. 安装依赖项：

   ```javascript
   $ npm install express dotenv pug body-parser --save
   ```

4. 创建 `lib/server.js` 文件。这将是应用程序的起点，并使所有其他部分发挥作用。它将加载 `lib/app.js` 文件，实例化 `FraudDetection` 类，并纳入来自 `lib/routes.js` 的路由，所有这些都可迅速创建。

   在 `lib/server.js` 中包含以下代码：

   ```javascript
   // start a new app
   var app = require('./app')
   
   // load our fraud prevention module
   var FraudDetection = require('./FraudDetection');
   var fraudDetection = new FraudDetection();
   
   // handle all routes
   require('./routes')(app, fraudDetection);
   ```

### 定义初始路由

创建 `lib/routes.js` 文件以定义应用程序的路由。编写一个处理程序，该处理程序将在主页 (`/`) 收到 [GET] 请求时显示表单，供用户输入号码：

```javascript
module.exports = function(app, detector) {
  app.get('/', function(req, res) {
    res.render('index');
  });
};
```

### 启动 Web 服务器

创建 `lib/app.js` 文件以启动 Web 服务器。下面显示的代码在 `PORT` 环境变量指定的端口上启动服务器；如果未设置 `PORT` 环境变量，则在端口 5000 上启动服务器：

```javascript
var express = require('express');
var bodyParser = require('body-parser');

// create a new express server
var app = express();
app.set('port', (process.env.PORT || 5000));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(express.static('public'))
app.set('view engine', 'pug')

// start the app and listen on port 5000
app.listen(app.get('port'), '127.0.0.1', function() {
  console.log('Fraud app listening on port', app.get('port'));
});

module.exports = app;
```

### 创建注册表

您将使用 `pug` 模板引擎来创建应用程序所需的 HTML 表单。

1. 在 `views/layout.pug` 文件中创建基本视图，其中包含以下内容：

   ```pug
   doctype html
   html(lang="en")
     head
       title Vonage Fraud Detection
       link(href='style.css', rel='stylesheet')
     body
       #container
         block content
   ```

2. 创建 `views/index.pug` 文件，该文件使用户能够输入其号码进行注册：

   ```pug
   extends ./layout
   
   block content
     h1 Register your number
     form(method='post')
       .field
         label(for='number') Phone number
         input(type='text', name='number', placeholder='1444555666')
       .actions
         input(type='submit', value='Register')
   ```

安装 Vonage Node Server SDK
-------------------------

通过在终端提示符下执行以下命令，将 [Vonage Node Server SDK](https://github.com/Nexmo/nexmo-node) 软件包添加到项目中：

```sh
$ npm install nexmo --save
```

配置应用程序
------

通过在 `lib/server.js` 文件顶部加入以下 `require` 语句，将应用程序配置为从 `.env` 文件加载凭据：

```javascript
require('dotenv').config();
```

将以下条目添加到应用程序文件夹根目录下的 `.env` 文件中，并将 `YOUR_NEXMO_API_KEY` 和 `YOUR_NEXMO_API_SECRET` 替换为您从[开发人员 Dashboard](https://dashboard.nexmo.com) 获取的 API 密钥和密码

    NEXMO_API_KEY=YOUR_NEXMO_API_KEY
    NEXMO_API_SECRET=YOUR_NEXMO_API_SECRET
    IP=216.58.212.78 # USA IP
    # IP=212.58.244.22 # UK IP

`IP` 是我们将在后面步骤中使用的条目，用来模拟用户当前的 IP 地址，以便我们可以确定他们正在从哪个国家/地区访问您的应用程序。一个在英国，另一个在美国。美国 `IP` 已被注释掉，以便您可以更改用户的位置进行测试。

处理电话号码
------

### 如何确定潜在的欺诈行为

您已经启动并运行一个基本应用程序，现在可以编写用于处理号码的逻辑。

您将使用 Number Insight API 提供的信息来检查潜在的欺诈号码。Number Insight Advanced API 可以告诉您某个号码所属的国家/地区，（如果是移动号码并且用户正在漫游）关联设备当前所在的国家/地区，以及其他许多信息。

在生产环境中，您将以编程方式确定用户的 IP 地址。在本示例应用程序中，您将从 `.env` 文件的 `IP` 条目中读取用户当前的 IP 地址，并使用 [MaxMind GeoIP](https://www.maxmind.com) 数据库对其进行地理定位。

下载 [MaxMind GeoLite 2 国家/地区数据库](https://dev.maxmind.com/geoip/geoip2/geolite2/)，然后将 `Geolite2-Country.mmdb` 文件提取到应用程序目录的根目录下。通过在终端提示符下执行以下命令来安装它：

```sh
$ npm install maxmind --save
```

如果用户当前的 IP 地址与 Number Insight 报告的地址不同，则可以强制他们使用 Verify API 来验证号码的所有权。这样一来，只有当提供的号码与所属设备在不同的国家/地区时，才会强制执行验证步骤。

因此，您的应用程序必须触发以下事件序列：

```sequence_diagram
Participant Browser
Participant App
Participant Vonage
Note over App,Vonage: Initialization
Browser->>App: User registers by \nsubmitting number
App->>Vonage: Number Insight request
Vonage-->>App: Number Insight response
Note over App,Vonage: If Number Insight shows that the \nuser and their phone are in different \ncountries, start the verification process
App->>Vonage: Send verification code to user's phone
Vonage-->>App: Receive acknowledgement that\nverification code was sent
App->>Browser: Request the code from the user
Browser->>App: User submits the code they received
App->>Vonage: Check verification code
Vonage-->>App: Code Verification status
Note over Browser,App: If either Number Insight response or verification step \nis satisfactory, continue registration
App->>Browser: Confirm registration
```

### 创建欺诈检测逻辑

在应用程序的 `lib` 文件夹中为 `FraudDetection` 类创建 `FraudDetection.js` 文件。在类构造函数中，首先创建 `Nexmo` 的实例，向其提供 `.env` 配置文件中的 Vonage API 密钥和密码：

```javascript
var Nexmo = require('nexmo');

var FraudDetection = function(config) {
  this.nexmo = new Nexmo({
    apiKey: process.env.VONAGE_API_KEY,
    apiSecret: process.env.VONAGE_API_SECRET
  });
};

module.exports = FraudDetection;
```

然后，通过按以下方式修改 `FraudDetection.js` 文件，来创建 IP 查找：

```javascript
var Nexmo = require('nexmo');
var maxmind = require('maxmind');

var FraudDetection = function(config) {
  this.nexmo = new Nexmo({
    apiKey: process.env.VONAGE_API_KEY,
    apiSecret: process.env.VONAGE_API_SECRET
  });

  maxmind.open(__dirname + '/../GeoLite2-Country.mmdb', (err, countryLookup) => {
    this.countryLookup = countryLookup;
  });
};

module.exports = FraudDetection;
```

用户提交电话号码后，将其与用户当前的 IP 一起传递给您的欺诈检测代码。如果欺诈检测逻辑确定电话的位置和用户的位置不匹配，则发送验证码。要实现此操作，请在 `lib/routes.js` 中为 [POST] 请求添加一个 `/` 路由处理程序，如下所示：

```javascript
  app.post('/', function(req, res) {
    var number = req.body.number;

    detector.matchesLocation(number, req, function(matches){
      if (matches) {
        res.redirect('/registered');
      } else {
        detector.startVerification(number, function(error, result){
          res.redirect('/confirm?request_id='+result.request_id);
        });
      }
    });
  });
```

检查可能的欺诈行为
---------

在 `FraudDetection` 类中，从请求中提取用户的 IP，并使用 MaxMind 国家/地区数据库确定用户正在哪个国家/地区访问您的应用程序。

然后，向 Number Insight Advanced API 发出异步请求，以查看用户注册的号码当前是否正在漫游，从而确定要进行比较的正确国家/地区。

通过合并所有这些数据，您可以构建一个简单的风险模型，如果国家/地区不匹配，则触发下一步。

将以下方法添加到 `lib\FraudDetection.js` 的 `FraudDetection` 类中：

```javascript
FraudDetection.prototype.matchesLocation = function(number, request, callback) {
  var ip = process.env['IP'] || req.headers["x-forwarded-for"] || req.connection.remoteAddress;
  var geoData = this.countryLookup.get(ip);

  this.nexmo.numberInsight.get({
    level: 'advancedSync',
    number: number
  }, function(error, insight) {
    var isRoaming = insight.roaming.status !== 'not_roaming';

    if (isRoaming) {
      var matches = insight.roaming.roaming_country_code == geoData.country.iso_code;
    } else {
      var matches = insight.country_code == geoData.country.iso_code;

    }
    callback(matches)
  });
}
```

发送验证码
-----

1. 修改 `lib\FraudDetection.js`，以便当风险模型检测到可能的欺诈号码时，使用 Vonage 的 Verify API 向手机发送验证码。将以下方法添加到类中：

   ```javascript
   FraudDetection.prototype.startVerification = function(number, callback) {
     this.nexmo.verify.request({
       number: number,
       brand: 'ACME Corp'
     }, callback);
   };
   ```

2. 在 `lib/routes.js` 中添加一个新路由，让用户能够输入他们在手机上收到的验证码：

   ```javascript
   app.get('/confirm', function(req, res) {
     res.render('confirm', {
       request_id: req.query.request_id
     });
   });
   ```

3. 在 `views/confirm.pug` 中创建供用户输入确认码的视图：

   ```pug
   extends ./layout
   
   block content
     h1 Confirm the code
     #flash_alert We have sent a confirmation code to your phone number. Please fill in the code below to continue.
     form(method='post')
       .field
         label(for='code') Code
         input(type='text', name='code', placeholder='1234')
         input(type='hidden', name='request_id', value=request_id)
       .actions
         input(type='submit', value='Confirm')
   ```

检查验证码
-----

1. 在 `lib/routes.js` 中，如果用户正确输入了验证码，则将他们重定向到 `/registered`。否则，将他们发送回 `/confirm`：

   ```javascript
   app.post('/confirm', function(req, res) {
     var code = req.body.code;
     var request_id = req.body.request_id;
   
     detector.checkVerification(request_id, code, function(error, result) {
       if (result.status == '0') {
         res.redirect('/registered');
       } else {
         res.redirect('/confirm');
       }
     });
   });
   ```

2. 在 `lib/FraudDetection.js` 中，对照已发送的验证请求 ID，检查用户提交的验证码：

   ```javascript
   FraudDetection.prototype.checkVerification = function(request_id, code, callback) {
     this.nexmo.verify.check({
       code: code,
       request_id: request_id
     }, callback);
   };
   ```

3. 通过向 `lib/routes.js` 添加以下路由，向通过这些步骤的用户显示一条友好消息，以确认其注册：

   ```javascript
   app.get('/registered', function(req, res) {
     res.render('registered');
   });
   ```

4. 将视图创建为 `lib/registered.pug`：

   ```pug
   extends ./layout
   
   block content
     h1 Registered
     #flash_notice You are now fully signed up. Thank you for providing your phone number.
   ```

测试应用程序
------

1. 启动应用程序：

   ```sh
   $ node lib/server.js
   ```

2. 运行 `ngrok`：

   ```sh
   $ ./ngrok http 5000
   ```

3. 导航到 `ngrok` 在浏览器中提供的地址。例如：`https://7db5972b.ngrok.io`。

4. 输入您的电话号码。如果 `.env` 中的 `IP` 条目与您的移动设备的当前位置匹配，则应该看到设备已成功注册。否则，系统将向您发送验证码，并提示您输入验证码，然后才能注册。

结语
---

在本教程中，您构建了一个非常基本的欺诈检测系统。您使用了 [Number Insight Advanced API](/verify/api-reference/) 提供的以下信息来标记潜在的欺诈号码：

* 其当前 IP 所在的国家/地区
* 电话号码所属的国家/地区
* 号码的漫游状态
* 漫游国家/地区

您还学习了如何使用 [Verify API](/verify) 对号码进行验证。

后续步骤
----

这里有一些资源可以帮助您构建此类应用程序：

* GitHub 上本教程的[源代码](https://github.com/Nexmo/node-verify-fraud-detection)
* 代码示例，介绍您会如何： 
  * 异步[请求](/number-insight/code-snippets/number-insight-advanced-async)和[接收](/number-insight/code-snippets/number-insight-advanced-async-callback) Number Insight Advanced API 数据
  * 使用 Verify API [发送](/verify/code-snippets/send-verify-request)和[检查](/verify/code-snippets/check-verify-request)验证码

* 博客文章： 
  * [Number Insight API](https://www.nexmo.com/?s=number+insight)
  * [Verify API](https://www.nexmo.com/?s=verify)

* API 参考文档： 
  * [Number Insight API](/number-insight/api-reference)
  * [Verify API](/verify/api-reference)

