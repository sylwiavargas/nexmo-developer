---
title:  使用 Node.js 调用 Websocket

products: voice/voice-api

description:  在本教程中，您将学习如何将呼叫连接到 WebSocket 端点，该端点会将呼叫音频回传给主叫方。

languages:
  - Node


---

使用 Node.js 调用 Websocket
=======================

您可以使用 Vonage 语音 API 将呼叫连接到 [WebSocket](/voice/voice-api/guides/websockets)，从而提供通过 WebSocket 协议实时传递的双向呼叫音频流。这样您就可以处理呼叫音频，以使用人工智能执行情感分析、实时转录和决策等任务。

在本教程中，您将呼入电话连接到 WebSocket 端点。WebSocket 服务器将侦听呼叫音频并将其回传给您。您将使用 [Express](https://expressjs.com) Web 应用程序框架和 [express-ws](https://www.npmjs.com/package/express-ws) 来实现此目的，express-ws 允许您像定义其他 `express` 路由一样定义 WebSocket 端点。

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up) - 用于获取 API 密钥和密码
* [ngrok](https://ngrok.com/) - 使 Vonage 服务器可以通过互联网访问您的开发 Web 服务器

安装 Nexmo CLI
------------

您需要一个 Vonage 虚拟号码来接收呼入电话。如果您还没有，则可以在[开发人员 Dashboard](https://dashboard.nexmo.com) 中购买并配置号码，也可以使用 [Nexmo CLI](https://github.com/Nexmo/nexmo-cli)。本教程使用 CLI。

在终端提示符下运行以下命令，以安装 CLI 并使用您在[开发人员 Dashboard](https://dashboard.nexmo.com) 中找到的 API 密钥和密码对其进行配置：

```sh
npm install -g nexmo-cli
nexmo setup NEXMO_API_KEY NEXMO_API_SECRET
```

购买 Vonage 号码
------------

如果您还没有 Vonage 虚拟号码，请购买一个来接听呼入电话。

首先，列出您所在国家/地区的可用号码（将 `GB` 替换为两个字符的[国家/地区代码](https://www.iban.com/country-codes)）：

```sh
nexmo number:search GB
```

购买其中一个可用号码。例如，要购买号码 `447700900001`，请执行以下命令：

```sh
nexmo number:buy 447700900001
```

创建语音 API 应用程序
-------------

使用 CLI 创建具有 Webhook 的语音 API 应用程序，这些 Webhook 将分别负责接听 Vonage 号码上的呼叫 (`/webhooks/answer`) 和记录呼叫事件 (`/webhooks/events`)。

这些 Webhook 必须可供 Vonage 服务器访问，因此在本教程中，您将使用 `ngrok` 向公共互联网公开本地开发环境。[这篇博客文章](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)介绍了如何安装和运行 `ngrok`。

使用以下命令运行 `ngrok`：

```sh
ngrok http 3000
```

记下 `ngrok` 提供的临时主机名，并在下面的命令中用它替换 `example.com`：

```sh
nexmo app:create "My Echo Server" https://example.com/webhooks/answer https://example.com/webhooks/events
```

该命令返回一个应用程序 ID（应记下该 ID）和您的公钥信息（在本教程中，您可以放心地忽略该信息）。

链接号码
----

您需要将 Vonage 号码链接到您刚创建的语音 API 应用程序。使用以下命令：

```sh
nexmo link:app NEXMO_NUMBER NEXMO_APPLICATION_ID
```

现在可以编写应用程序代码了。

创建项目
----

为应用程序创建一个目录，使用 `cd` 进入该目录，然后使用 Node.js 包管理器 `npm` 为应用程序的依赖项创建一个 `package.json` 文件：

```sh
$ mkdir myapp
$ cd myapp
$ npm init
```

按 [Enter] 键接受每个默认值。

然后，安装 [Express](https://expressjs.com) Web 应用程序框架、[express-ws](https://www.npmjs.com/package/express-ws) 和 [body-parser](https://www.npmjs.com/package/body-parser) 软件包：

```sh
$ npm install express express-ws body-parser
```

编写应答 Webhook
------------

当 Vonage 在您的虚拟号码上收到呼入电话时，它将向您的 `/webhooks/answer` 路由发出请求。此路由应接受 HTTP `GET` 请求，并返回 [Nexmo 呼叫控制对象 (NCCO)](/voice/voice-api/ncco-reference)，告诉 Vonage 如何处理该呼叫。

NCCO 应使用 `text` 操作来问候主叫方，并使用 `connect` 操作将呼叫连接到 Webhook 端点：

```javascript
'use strict'

const express = require('express')
const bodyParser = require('body-parser')
const app = express()
const expressWs = require('express-ws')(app)

app.use(bodyParser.json())

app.get('/webhooks/answer', (req, res) => {
  let nccoResponse = [
    {
      "action": "talk",
      "text": "Please wait while we connect you to the echo server"
    },
    {
      "action": "connect",
      "from": "NexmoTest",
      "endpoint": [
        {
          "type": "websocket",
          "uri": `wss://${req.hostname}/socket`,
          "content-type": "audio/l16;rate=16000",
        }
      ]
    }
  ]

  res.status(200).json(nccoResponse)
})
```

`endpoint` 的 `type` 是 `websocket`，`uri` 是可以访问 WebSocket 服务器的 `/socket` 路由，`content-type` 指定音频质量。

编写事件 Webhook
------------

实现一个捕获呼叫事件的 Webhook，以便您可以在控制台中观察呼叫的生命周期：

```javascript
app.post('/webhooks/events', (req, res) => {
  console.log(req.body)
  res.send(200);
})
```

每当呼叫状态发生变化时，Vonage 都会向此端点发出 `POST` 请求。

创建 WebSocket
------------

首先，处理 `connection` 事件，以便您可以报告 Webhook 服务器何时联机并准备接收呼叫音频：

```javascript
expressWs.getWss().on('connection', function (ws) {
  console.log('Websocket connection is open');
});
```

然后，为 `/socket` 路由创建路由处理程序。该处理程序将侦听 `message` 事件，每次 WebSocket 从呼叫中收到音频时都会引发此事件。您的应用程序应该通过使用 `send()` 方法将音频回传给主叫方来做出响应：

```javascript
app.ws('/socket', (ws, req) => {
  ws.on('message', (msg) => {
    ws.send(msg)
  })
})
```

创建 Node.js 服务器
--------------

最后，编写可实例化 Node 服务器的代码：

```javascript
const port = 3000
app.listen(port, () => console.log(`Listening on port ${port}`))
```

测试应用程序
------

1. 通过执行以下命令来运行 Node.js 应用程序：

```sh
node index.js
```

1. 拨打 Vonage 号码并收听欢迎消息。

2. 随便说点什么，您会听到您的声音由通话中的另一个参与者（您的 WebSocket 服务器）回传给您。

结语
---

在本教程中，您创建了一个使用语音 API 连接到 WebSocket 端点的应用程序。

您创建的 WebSocket 非常简单，但它能够侦听呼叫音频并做出响应。WebSocket 的功能非常强大，可以为一些非常复杂的用例提供支持，例如人工智能、呼叫音频的分析和转录。

延伸阅读
----

以下资源将帮助您深入了解如何在语音 API 应用程序中使用 WebSocket：

* GitHub 上本教程的[源代码](https://github.com/Nexmo/node-websocket-echo-server)
* [WebSocket 指南](/voice/voice-api/guides/websockets)
* [WebSocket 协议标准](https://tools.ietf.org/html/rfc6455)
* [Vonage 语音和 WebSocket 录制的网络研讨会入门](https://www.nexmo.com/blog/2017/02/15/webinar-getting-started-nexmo-voice-websockets-dr/)
* Vonage 开发人员博客上[有关 WebSocket 的文章](https://www.nexmo.com/?s=websockets)
* [NCCO 连接操作](/voice/voice-api/ncco-reference#connect)
* [端点指南](/voice/voice-api/guides/endpoints)
* [语音 API 参考文档](/voice/voice-api/api-reference)

