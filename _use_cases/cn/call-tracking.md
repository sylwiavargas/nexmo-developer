---
title:  呼叫跟踪

products: voice/voice-api

description:  通过为每个营销活动使用不同的号码并跟踪呼入电话，来跟踪哪些营销活动效果良好。本教程介绍如何处理呼入电话，将其连接到另一个号码，以及跟踪呼叫您的每个 Vonage 号码的电话号码。

languages:
  - Node


---

跟踪 Vonage 号码的使用情况
=================

通过跟踪 Vonage 号码收到的呼叫，深入了解客户通信的有效性。通过为每个营销活动注册一个不同的号码，您可以看到哪个营销活动的效果最好，并利用该信息改进未来的营销工作。

今天的示例使用 node.js，所有代码都[可以在 GitHub 上找到](https://github.com/Nexmo/node-call-tracker)，但同样的方法也可以有效地用于任何其他技术堆栈。

先决条件
----

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 已安装并设置 [Nexmo CLI](https://github.com/nexmo/nexmo-cli)。
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。如果您在本地进行开发，建议使用 [ngrok](https://ngrok.com/)。

⚓ 创建语音应用程序
⚓ 购买支持语音的电话号码
⚓ 将电话号码链接到 Vonage 应用程序

入门
---

在获取代码并开始使用之前，您将设置一个 Vonage 应用程序，并获取一些号码与其结合使用。创建 Vonage 应用程序时，需要指定一些 [Webhook](https://developer.nexmo.com/concepts/guides/webhooks) 端点；这些端点是您自己应用程序中的 URL，这也是必须能够公开访问您的代码的原因。当主叫方拨打您的 Vonage 号码时，Vonage 将向您指定的 `answer_url` 端点发出 Web 请求，并按照在此找到的说明进行操作。

还有一个 `event_url` Webhook，每当呼叫状态发生变化时都会接收更新。为了简单起见，在此应用程序中，代码直接将事件输出到控制台，以便在开发应用程序时容易看到。

要创建初始应用程序，请使用 Nexmo CLI 运行以下命令，并在两个位置替换您的 URL：

```bash
nexmo app:create --keyfile private.key call-tracker https://your-url-here/track-call https://your-url-here/event
```

此命令返回用于标识您的应用程序的 UUID（通用唯一标识符）。将其复制到安全的地方，稍后会用到它！

参数包括：

* `call-tracker` - 为此应用程序提供的名称
* `private.key` - 存储私钥的文件的名称，`private.key` 是应用程序预期的名称
* `https://example.com/track-call` - 当您收到 Vonage 号码的呼入电话时，Vonage 会发出 `GET` 请求，并从该 Webhook 端点检索控制呼叫流程的 NCCO
* `https://example.com/event` - 当呼叫状态发生变化时，Vonage 会将状态更新发送到该 Webhook 端点

您需要使用两个 Vonage 号码来试用此应用程序。要购买号码，请再次使用 Nexmo CLI 和以下命令：

```bash
nexmo number:buy --country_code US --confirm
```

可以在此命令中使用 [ISO 3166-1 alpha-2 格式](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)的任意国家/地区代码。其结果为您购买的号码，请复制该号码（可以随时使用 `nexmo numbers:list` 获取列表）并将其链接到您创建的应用程序：

```bash
nexmo link:app [number] [application ID]
```

重复购买和链接步骤，您想用多少号码就用多少号码。

> 对于新用户，您需要先给自己的帐户充值，然后才能购买号码。

设置并运行应用程序
---------

从此处获取代码：[https://github.com/Nexmo/node-call-tracker](https://github.com/Nexmo/node-call-tracker)。要么将存储库克隆到本地计算机上，要么下载 zip 文件，无论哪种方式都可以。

使用以下命令安装依赖项： `npm install`

然后将配置模板 `example.env` 复制到名为 `.env` 的文件中。在此文件中，您需要配置 Vonage 应连接到的电话号码，因此这可以是您附近并且可以接听的任何电话。

> 您还可以通过添加 `PORT` 设置，在 `.env` 文件中设置端口号

要启动 Web 服务器，请运行以下命令： `npm start`

通过访问 http://localhost:5000，检查一切是否正常。您应该会看到“Hello Vonage”作为响应。

处理呼入语音电话
--------

当 Vonage 收到 Vonage 号码的呼入呼叫时，它会向您在[创建语音应用程序](#get-started)时设置的 Webhook 端点发出请求。

```sequence_diagram
Participant App
Participant Vonage
Participant Caller
Note over Caller,Vonage: Caller calls one of\nthe tracking numbers
Caller->>Vonage: Calls Vonage number
Vonage->>App:Inbound Call(from, to)
```

当主叫方拨打电话时，应用程序会收到传入的 Webhook。它提取主叫方的电话号码（`to` 号码）和他们拨打的号码（`from` 号码），并将这些值传递给呼叫跟踪逻辑。

传入的 Webhook 由 `/track-call` 路由接收：

```js
app.get('/track-call', function(req, res) {
  var from = req.query.from;
  var to = req.query.to;

  var ncco = callTracker.answer(from, to);
  return res.json(ncco);
});
```

⚓ 跟踪呼叫

连接主叫方之前跟踪呼叫
-----------

在示例应用程序中，用于实际跟踪呼叫的逻辑独立运行，并且超级简单。可能有点太过于简单，因为当您重启服务器时，它会丢失数据！对于您自己的应用程序，您可以扩展这部分内容，根据自己的需要写到数据库、日志记录平台或其他工具中。跟踪呼叫后，应用程序会返回一个 [Nexmo 呼叫控制对象 (NCCO)](https://developer.nexmo.com/voice/voice-api/ncco-reference)，告诉 Vonage 服务器接下来如何处理该呼叫。

您将在 `lib/CallTracker.js` 中找到以下代码：

```js
/**
 * Track the call and return an NCCO that proxies a call.
 */
CallTracker.prototype.answer = function (from, to) {
  if(!this.trackedCalls[to]) {
    this.trackedCalls[to] = [];
  }
  this.trackedCalls[to].push({timestamp: Date.now(), from: from});
  
  var ncco = [];
  
  var connectAction = {
    action: 'connect',
    from: to,
    endpoint: [{
      type: 'phone',
      number: this.config.proxyToNumber
    }]
  };
  ncco.push(connectAction);
  
  return ncco;
};
```

NCCO 使用 `connect` 操作将另一个呼叫的来电者连接到您在配置文件中指定的号码。`from` 号码必须是 Vonage 号码，因此，代码将跟踪的号码用作呼出电话的主叫方 ID。有关呼叫控制对象的更多详细信息，请查阅 [NCCO 文档中的 `connect` 操作](https://developer.nexmo.com/voice/voice-api/ncco-reference#connect)。

结语
---

借助此方法，您已经能够将一些 Vonage 号码链接到 node.js 应用程序，记录这些号码的呼入电话，并将主叫方连接到呼出号码。通过记录时间戳以及源号码和目标号码，您可以继续对此数据执行所需的任何分析，以获取最佳业务结果。

接下来做什么？
-------

这里还有一些资源建议，您可以在本教程之后的下一步骤中使用它们：

* [为呼入电话添加呼叫耳语](https://developer.nexmo.com/tutorials/add-a-call-whisper-to-an-inbound-call)，以便在连接呼入电话和呼出电话之前，向呼出电话告知有关呼入电话的一些详细信息。
* 介绍如何[使用 ngrok 隧道将本地开发服务器连接到 Vonage API](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/) 的博客文章。
* [语音 Webhook 参考](https://developer.nexmo.com/voice/voice-api/webhook-reference)介绍了 `answer_url` 和 `event_url` 端点的传入 Webhook 的详细信息。
* 请参阅 [NCCO 文档](https://developer.nexmo.com/voice/voice-api/ncco-reference)，获取有关可用于控制 Vonage 呼叫流程的其他操作的详细信息。

