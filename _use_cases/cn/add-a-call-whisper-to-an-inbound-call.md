---
title:  为呼入电话添加呼叫耳语

products: voice/voice-api

description:  “电话号码在广告中随处可见：广告牌上、电视广告中、网站上、报纸上。这些号码通常都重定向到同一个呼叫中心，在那里，座席需要询问对方为什么打电话，以及他们在哪里看到的广告。呼叫耳语让这一切变得更加简单。”

languages:
  - Node


---

语音 - 为呼入电话添加呼叫耳语
==================

电话号码在广告中随处可见：广告牌上、电视广告中、网站上、报纸上。这些号码通常都重定向到同一个呼叫中心，在那里，座席需要询问对方为什么打电话，以及他们在哪里看到的广告。

通过呼叫耳语，可在将呼叫中心话务员连接到主叫方之前，告知话务员呼入电话的背景信息。本教程将展示实现此方法的应用程序。用户将拨打两个号码中的一个。应用程序接听电话，主叫方听到一条稍候消息。与此同时，应用程序向呼叫中心话务员发出呼叫，根据拨打的号码播放不同的呼叫耳语，然后将话务员与来电者连接到会议中。

这些示例是在 node.js 中用 express 编写的，您可以[在 GitHub 上](https://github.com/Nexmo/node-call-whisper)找到相应代码。

教程内容
----

您将了解如何构建“为呼入电话添加呼叫耳语”：

* [工作原理](#how-it-works) - 概述谁在呼叫谁以及整个示例应用程序的流程。
* [准备阶段](#before-you-begin) - 设置本教程所需的应用程序和号码。
* [代码入门](#getting-started-with-code) - 克隆存储库并让应用程序运行。
* [代码演练](#code-walkthrough) - 深入了解应用程序的工作原理。
* [延伸阅读](#further-reading) - 查看其他可能对您有所帮助的资源。

工作原理
----

```sequence_diagram
User->>Vonage number: User calls either of\nthe numbers linked\n to this Application
Vonage number-->>Application: /answer
Application->>Operative: Connects to operative's number
Note left of Operative: When operative\nanswers
Operative-->>Application: /answer_outbound
Application->>Operative: Announces key information\nabout original caller
Note left of Operative: Callers are connected
```

开始之前
----

在获取并运行代码之前，我们需要先做几件事。

### 注册 Vonage

如果您还没有 Vonage API 帐户，请[注册](https://dashboard.nexmo.com/sign-up)一个。

### 设置 CLI

本教程使用 [Nexmo 命令行工具](https://github.com/Nexmo/nexmo-cli)，因此在继续操作前，请检查是否已安装该工具。

### 购买两个电话号码

您需要两个电话号码，以便在拨打不同的号码时观察不同的耳语。运行此命令两次，并记下已购买的号码：

```bash
$ nexmo number:buy --country_code US --confirm
```

### 创建应用程序

创建一个新的 Vonage 应用程序并保存私钥 - 稍后需要用到。对于此命令中的“answer”和“event”参数，请将 `https://example.com` 替换为您自己的应用程序的 URL：

```bash
nexmo app:create "Call Whisper" https://example.com/answer https://example.com/event --keyfile app.key
```

此命令会获取私钥并将其安全地放入 `app.key` 中。记下应用程序 ID，因为下一个命令会用到它...

### 将号码链接到应用程序

通过为每个号码运行以下命令一次，将应用程序链接到这两个号码：

```bash
nexmo link:app [NEXMO_NUMBER] [APP_ID]
```

> 您可以随时分别使用 `nexmo app:list` 和 `nexmo number:list` 命令获取应用或号码列表。

代码入门
----

此项目的代码位于 GitHub 上，网址为 [https://github.com/Nexmo/node-call-whisper](https://github.com/Nexmo/node-call-whisper)。它由使用 Express 的 node.js 项目组成，旨在为您提供一个可行示例，您稍后可以根据自己的需求进行调整。

### 克隆存储库

克隆存储库或将存储库下载到本地计算机的新目录中。

### 配置设置

您的应用程序在运行之前，需要进一步了解您和您的应用程序。将 `.env-example` 文件复制到 `.env`，并编辑这个新文件以反映您要使用的设置：

* `CALL_CENTER_NUMBER`：联系呼叫中心话务员时所用的电话号码，例如您的手机号码
* `INBOUND_NUMBER_1`：您购买的号码之一
* `INBOUND_NUMBER_2`：您购买的另一个号码
* `DOMAIN`：您的应用将要在其中运行的域的名称，例如我的域名是： `ff7b398a.ngrok.io`

### 安装依赖项

在您下载代码所在的目录中，运行 `npm install`。这将安装 Express 以及此项目所需的其他依赖项。

### 启动服务器

完成配置并安装依赖项后，您的应用程序就可以使用了！使用以下命令运行它：

`npm start`

默认情况下，应用程序在端口 5000 上运行。如果要使用 `ngrok`，则可以立即启动隧道。

> 当 ngrok 隧道名称更改时，请记住使用 `nexmo app:update` 命令更新应用程序的 URL。

试试看
---

让我们试着演示一下。演示时，您需要两部电话（一部是“主叫方”，一部是“呼叫中心话务员”），因此您可能需要招募一个朋友或使用 Skype 来打第一个电话。

1. 拨打您购买的号码之一。
2. 主叫方将听到一条问候语，接着，呼叫中心话务员的电话号码响起。
3. 当呼叫中心话务员接听电话时，他们将在连接到原始主叫方之前听到“耳语”消息。
4. 现在再试一次，但拨打另一个号码，您会听到不同的“耳语”。

代码演练
----

这个演示很有意思，但如果您有兴趣自己构建，那么可能需要了解一些关键要点。本节介绍了该流程中每个步骤的关键代码部分，以便您可以了解各步骤对应的代码段，并根据自己的需求调整此应用程序。

### 接听呼入电话，并开始拨出电话

每当有人拨打链接到 Vonage 应用程序的某个号码时，Vonage 都会收到呼入电话。然后，Vonage 会将该呼叫通知给您的 Web 应用程序。它通过向 Web 应用的 `answer_url` 端点（在本例中为 `/answer`）发出 [Webhook 请求](/voice/voice-api/webhook-reference#answer-webhook)来完成此操作。接听电话后，应用程序将该主叫方连接到呼叫中心话务员。

**lib/routes.js** 

```js
  app.get('/answer', function(req, res) {
    var answer_url = 'http://'+process.env['DOMAIN']+'/on-answer'
    console.log(answer_url);

      res.json([
        {
          "action": "talk",
          "text": "Thanks for calling. Please wait while we connect you"
        },
        {
          "action": "connect",
          "from": req.query.to,
          "endpoint": [{
            "type": "phone",
            "number": process.env['CALL_CENTER_NUMBER'],
            "onAnswer": {"url": answer_url}
          }]
        }
      ]);
  });

```

*注意：有关更多信息，请参阅[语音 API 参考](/api/voice)。* 

我们返回的响应是一个 [NCCO](https://developer.nexmo.com/voice/voice-api/ncco-reference)（Nexmo 呼叫控制对象）数组。第一个 NCCO 是主叫方听到的语音消息；第二个 NCCO 连接到另一个主叫方，并指定当此人接听电话时应使用哪个 URL。

### 播放耳语并连接呼叫

当呼叫中心话务员接听电话时，将使用 `onAnswer` URL，在我们的应用程序中为 `/on-answer` 端点。此代码用于查找所拨打的号码并确定要发出的通知。

**lib/routes.js** 

```js
// Define the topics for the inbound numbers
var topics = {}
topics[process.env['INBOUND_NUMBER_1']] = 'the summer offer';
topics[process.env['INBOUND_NUMBER_2']] = 'the winter offer';
```

连接呼叫后，先使用 `talk` NCCO 操作向座席播放呼叫耳语，通知他们该呼叫涉及哪个广告活动，然后再将他们连接到正在会议中等待的主叫方。

**lib/routes.js** 

```js
  app.get('/on-answer', function(req, res) {
    // we determine the topic of the call based on the inbound call number
    var topic = topics[req.query.from]

    res.json([
      // We first play back a little message telling the call center operator what
      // the call relates to. This "whisper" can only be heard by the call center operator
      {
        "action": "talk",
        "text": "Incoming call regarding "+topic
      }
    ]);
  });

```

您可以通过各种可能的方式来自定义耳语。您可以使用 `onAnswer` 中的 `url` 传递来电者的号码并进行查找，从而可以按姓名打招呼或提供其他信息。可能性是无穷无尽的，但我们希望本教程能给您提供一个可行示例，让您可以在此基础上进行构建和自定义。

延伸阅读
----

* [https://github.com/Nexmo/node-call-whisper](https://github.com/Nexmo/node-call-whisper) 包含此示例应用程序的所有代码。
* 查看我们的[语音指南](/voice)，了解您可以对语音执行的更多操作。
* [语音 API 参考](/api/voice)包含每个端点的详细文档。

