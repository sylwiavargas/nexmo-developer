---
title:  Number Insight Advanced API

products: number-insight

description:  了解如何获取有关号码有效性和可接通性的综合信息。

languages:
  - Node


---

Number Insight Advanced API
===========================

Number Insight API 为您提供有关全球电话号码的实时信息。它包含三个级别：Basic、Standard 和 Advanced。

Advanced 级别为您提供最全面的数据，帮助保护贵组织免受欺诈和垃圾邮件的侵害。与 Basic 和 Standard 级别不同的是，您通常通过 [Webhook](/concepts/guides/webhooks) 异步访问 Advanced API。

教程内容
----

在本教程中，您将在 Node.js 和 Express 中创建一个简单的 RESTful Web 服务，该服务接受电话号码并在号码可用时返回有关它的见解信息。

为此，请执行以下步骤：

1. [创建项目](#create-the-project) - 创建一个 Node.js/Express 应用程序。
2. [安装 `nexmo` 软件包](#install-the-nexmo-package) - 将 Vonage 功能添加到项目中。
3. [将应用程序公开到互联网](#expose-your-application-to-the-internet) - 使用 `ngrok` 支持 Vonage 通过 Webhook 访问您的应用程序。
4. [创建基本应用程序](#create-the-basic-application) - 构建基本功能。
5. [创建异步请求](#create-the-asynchronous-request) - 调用 Number Insight Advanced API。
6. [创建 Webhook](#create-the-webhook) - 编写代码来处理传入的见解数据。
7. [测试应用程序](#test-the-application) - 看看实际效果！

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up) - 用于获取 API 密钥和密码
* [ngrok](https://ngrok.com/) - 使 Vonage 服务器可以通过互联网访问您的开发 Web 服务器

创建项目
----

为应用程序创建一个目录，使用 `cd` 进入该目录，然后使用 Node.js 包管理器 `npm` 为应用程序的依赖项创建一个 `package.json` 文件：

```sh
$ mkdir myapp
$ cd myapp
$ npm init
```

按 [Enter] 键接受每个默认值。

然后，安装 [Express](https://expressjs.com) Web 应用程序框架和 [body-parser](https://www.npmjs.com/package/body-parser) 软件包：

```sh
$ npm install express body-parser  --save
```

安装 `nexmo` 软件包
--------------

在终端窗口中执行以下 `npm` 命令，以安装 Vonage Node Server SDK：

```sh
$ npm install nexmo --save
```

将应用程序公开到互联网
-----------

当 Number Insight API 处理完您的请求时，它会通过 [Webhook](/concepts/guides/webhooks) 提醒您的应用程序。Webhook 为 Vonage 服务器提供了一种与您的应用程序进行通信的机制。

为了让您的应用程序可供 Vonage 服务器访问，必须在互联网上公开它。在开发和测试期间实现此目标的一种简单方法是使用 [ngrok](https://ngrok.com)，该服务通过安全隧道将本地服务器公开到公共互联网。有关更多详细信息，请参阅[此博客文章](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)。

下载并安装 [ngrok](https://ngrok.com)，然后使用以下命令启动它：

```sh
$ ./ngrok http 5000
```

这会为本地计算机的端口 5000 上运行的任何网站创建公共 URL（HTTP 和 HTTPS）。

使用位于 http://localhost:4040 的 `ngrok` Web 接口，并记下 `ngrok` 提供的 URL：您需要它们来完成本教程。

创建基本应用程序
--------

使用以下代码在应用程序目录中创建 `index.js` 文件，并将 `VONAGE_API_KEY`、`VONAGE_API_SECRET` 和 `WEBHOOK_URL` 常量替换为您自己的值：

```javascript
const app = require('express')();
const bodyParser = require('body-parser');

app.set('port', 5000));
app.use(bodyParser.json());

const VONAGE_API_KEY = // Your Vonage API key
const VONAGE_API_SECRET = // Your Vonage API secret
const WEBHOOK_URL = // e.g. https://bcac78a0.ngrok.io/webhooks/insight

app.get('/insight/:number', function(request, response) {
    console.log("Getting information for " + request.params.number);
}); 

app.listen(app.get('port'), function() {
    console.log('Listening on port', app.get('port'));
});
```

通过在终端执行以下命令并接收所示的结果，对其进行测试：

```sh
$ node index.js
Listening on port 5000
```

在浏览器中输入以下 URL，并将 `https://bcac78a0.ngrok.io` 替换为 `ngrok` 提供的主机名：

    https://bcac78a0.ngrok.io/insight/123456

如果一切正常，终端会显示 `Getting information for 123456`。

创建异步请求
------

您的应用程序已经可以接收电话号码了，现在需要创建对 Number Insight Async API 的异步请求。

首先，编写代码，以使用帐户详细信息创建 `Nexmo` 实例：

```javascript
const Nexmo = require('nexmo');
const nexmo = new Nexmo({
    apiKey: VONAGE_API_KEY,
    apiSecret: VONAGE_API_SECRET
});
```

然后，扩展 `/insight/:number` 路由以调用 Number Insight API，并传入您感兴趣的号码以及用于处理响应的 Webhook 的 URL。您将在后面的步骤中创建该 Webhook。

```javascript
app.get('/insight/:number', function(request, response) {
    console.log("Getting information for " + request.params.number);
    nexmo.numberInsight.get({
        level: 'advancedAsync',
        number: request.params.number,
	callback: WEBHOOK_URL
    }, function (error, result) {
	if (error) {
	    console.error(error);
	} else {
	    console.log(result);
	}
    });
});
```

调用 Number Insight Advanced API 会在实际见解数据可用之前返回一个确认请求的即时响应。我们要记录到控制台的就是这个响应：

```sh
{
  request_id: '3e6e31a4-3efb-49ab-8751-5a43e4de6406',
  number: '447700900000',
  remaining_balance: '17.775',
  request_price: '0.03000000',
  status: 0
}
```

请求正文中的 `status` 字段会告诉您操作是否成功。如 [Number Insight API 参考文档](/api/number-insight#getNumberInsightAsync)中所述，零值表示成功，非零值表示失败。

创建 Webhook
----------

Insight API 通过 `POST` 请求将结果返回到您的应用程序，因此您必须按下面所示将 `/webhooks/insight` 路由处理程序定义为 `app.post()`：

```javascript
app.post('/webhooks/insight', function (request, response) {
    console.dir(request.body);
    response.status(204).send();
});
```

处理程序将传入的 JSON 数据记录到控制台，并将 `204` HTTP 响应发送到 Vonage 服务器。

> HTTP 状态代码 204 表示服务器已成功完成请求，并且在响应有效负载正文中没有其他要发送的内容。

测试应用程序
------

运行 `index.js`：

```sh
$ node index.js
```

在浏览器的地址栏中输入以下格式的 URL，并将 `https://bcac78a0.ngrok.io` 替换为您的 `ngrok` URL，将 `INSIGHT_NUMBER` 替换为您选择的电话号码：

    http://YOUR_NGROK_HOSTNAME/insight/NUMBER

在初始确认响应之后，控制台应显示类似于以下内容的信息：

```sh
{
  "status": 0,
  "status_message": "Success",
  "lookup_outcome": 0,
  "lookup_outcome_message": "Success",
  "request_id": "55a7ed8e-ba3f-4730-8b5e-c2e787cbb2b2",
  "international_format_number": "447700900000",
  "national_format_number": "07700 900000",
  "country_code": "GB",
  "country_code_iso3": "GBR",
  "country_name": "United Kingdom",
  "country_prefix": "44",
  "request_price": "0.03000000",
  "remaining_balance": "1.97",
  "current_carrier": {
    "network_code": "23410",
    "name": "Telefonica UK Limited",
    "country": "GB",
    "network_type": "mobile"
  },
  "original_carrier": {
    "network_code": "23410",
    "name": "Telefonica UK Limited",
    "country": "GB",
    "network_type": "mobile"
  },
  "valid_number": "valid",
  "reachable": "reachable",
  "ported": "not_ported",
  "roaming": {
    "status": "not_roaming"
  }
}
```

测试应用程序时，请注意以下事项：

* Insight Advanced API 不提供有关 Standard API 中不可用的固定电话的任何信息。
* 对 Insight API 的请求不是免费的。在开发过程中，请考虑使用 `ngrok` Dashboard 重播以前的请求，以避免不必要的费用。

结语
---

在本教程中，您创建了一个简单的应用程序，该应用程序使用 Number Insight Advanced Async API 将数据返回到 Webhook。

本教程未涵盖 Advanced API 特有的某些功能，例如 IP 地址匹配、可接通性和漫游状态。请查看[文档](/number-insight/overview)，了解如何使用这些功能。

接下来做什么？
-------

以下资源将帮助您在应用程序中使用 Number Insight：

* GitHub 上本教程的[源代码](https://github.com/Nexmo/ni-node-async-tutorial)
* [Number Insight API 产品页面](https://www.nexmo.com/products/number-insight)
* [比较 Basic、Standard 和 Advanced Insight API](/number-insight/overview#basic-standard-and-advanced-apis)
* [Webhook 指南](/concepts/guides/webhooks)
* [Number Insight Advanced API 参考](/api/number-insight#getNumberInsightAsync)
* [使用 ngrok 隧道将本地开发服务器连接到 Vonage API](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)
* [更多教程](/number-insight/tutorials)

