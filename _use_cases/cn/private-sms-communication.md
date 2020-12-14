---
title:  私人短信通信

products: messaging/sms

description:  本教程介绍如何在不透露任何一方真实电话号码的情况下促进双方之间的短信通信。

languages:
  - Node


---

私人短信通信
======

有时您希望两方在不透露真实电话号码的情况下互发短信。

例如，如果您正在经营出租车预订服务，那么您希望客户和驾驶员能够沟通协调接载时间、地点等。但是，您不希望驾驶员知道客户的电话号码，以便保护客户隐私。反过来，您也不希望客户知道驾驶员的电话号码，从而绕过您的应用程序直接预订出租车服务。

教程内容
----

本教程基于[私人短信用例](https://www.nexmo.com/use-cases/private-sms-communication)。它教您如何使用 Node.js 和 Node Server SDK 来构建一个短信代理系统，该系统使用虚拟电话号码掩盖参与者的真实号码。

要构建该应用程序，请执行以下步骤：

* [创建基本 Web 应用程序](#create-the-basic-web-application) - 构建基本应用程序框架
* [配置应用程序](#configure-the-application) - 使用您的 API 密钥和密码以及您已预配的虚拟号码
* [创建聊天](#create-a-chat) - 在用户的真实号码和虚拟号码之间建立映射
* [接收入站短信](#receive-inbound-sms) - 在虚拟号码上捕获传入短信并将其转发给目标用户的真实号码

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up) - 用于获取 API 密钥和密码以及租用虚拟号码。
* [Vonage 号码](https://developer.nexmo.com/concepts/guides/glossary#virtual-number) - 用于隐藏每个用户的真实号码。您可以在[开发人员 Dashboard](https://dashboard.nexmo.com/buy-numbers) 中租用一个号码。
* GitHub 上的[源代码](https://github.com/Nexmo/node-sms-proxy) - [README](https://github.com/Nexmo/node-sms-proxy/blob/master/README.md) 中有安装说明。
* 已安装并配置 [Node.js](https://nodejs.org/en/download/)。
* [ngrok](https://ngrok.com/) -（可选）使 Vonage 服务器可以通过互联网访问您的开发 Web 服务器。

创建基本 Web 应用程序
-------------

该应用程序使用 [Express](https://expressjs.com/) 框架进行路由，使用 [Node Server SDK](https://github.com/Nexmo/nexmo-node) 来发送和接收短信。我们使用 `dotenv`，以便在 `.env` 文本文件中配置应用程序。

在 `server.js` 中，我们初始化应用程序的依赖项并启动 Web 服务器。我们为应用程序的主页 (`/`) 提供一个路由处理程序，以便您可以通过访问 `http://localhost:3000` 来测试服务器是否正在运行：

```javascript
require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const SmsProxy = require('./SmsProxy');

const app = express();
app.set('port', (process.env.PORT || 3000));
app.use(bodyParser.urlencoded({ extended: false }));

app.listen(app.get('port'), function () {
    console.log('SMS Proxy App listening on port', app.get('port'));
});

const smsProxy = new SmsProxy();

app.get('/', (req, res) => {
    res.send('Hello world');
})
```

请注意，我们正在实例化 `SmsProxy` 类的对象，以处理发送到虚拟号码的消息到目标收件人的真实号码的路由。我们在[代理短信](#proxy-the-sms)中介绍了实际的代理过程，但现在只需要注意，该类使用将在下一步中配置的 API 密钥和密码初始化 `nexmo`。这使您的应用程序可以发送和接收短信：

```javascript
const Nexmo = require('nexmo');

class SmsProxy {

    constructor() {

        this.nexmo = new Nexmo({
            apiKey: process.env.VONAGE_API_KEY,
            apiSecret: process.env.VONAGE_API_SECRET
        }, {
                debug: true
            });
    }
    ...
```

配置应用程序
------

将提供的 `example.env` 文件复制到 `.env` 并进行修改，以包含您的 Vonage API 密钥和密码以及 Vonage 号码。您可以在[开发人员 Dashboard](https://dashboard.nexmo.com) 中找到这些信息：

    VONAGE_API_KEY=YOUR_VONAGE_API_KEY
    VONAGE_API_SECRET=YOUR_VONAGE_API_SECRET
    VONAGE_NUMBER=YOUR_VONAGE_NUMBER

创建聊天
----

要使用该应用程序，请向 `/chat` 路由发出 `POST` 请求，并传入两个用户的真实电话号码。（您可以在[开始聊天](#start-the-chat)中看到一个示例请求）。

`/chat` 的路由处理程序如下所示：

```javascript
app.post('/chat', (req, res) => {
    const userANumber = req.body.userANumber;
    const userBNumber = req.body.userBNumber;

    smsProxy.createChat(userANumber, userBNumber, (err, result) => {
        if (err) {
            res.status(500).json(err);
        }
        else {
            res.json(result);
        }
    });
    res.send('OK');

});
```

聊天对象在 `smsProxy` 类的 `createChat()` 方法中创建。它将存储每个用户的真实号码：

```javascript
createChat(userANumber, userBNumber) {
    this.chat = {
        userA: userANumber,
        userB: userBNumber
    };

    this.sendSMS();
}
```

我们已经创建了聊天，现在需要让每个用户知道他们如何与对方联系。

### 介绍用户

> **注意** ：在本教程中，各用户通过短信接收虚拟号码。在生产系统中，可以使用电子邮件、应用内通知或以预定义号码的形式提供虚拟号码。

在 `smsProxy` 类的 `sendSMS()` 方法中，我们使用 `sendSms()` 方法从每个用户的真实号码向虚拟号码发送两条消息。

```javascript
sendSMS() {
    /*  
        Send a message from userA to the virtual number
    */
    this.nexmo.message.sendSms(this.chat.userA,
                                process.env.VIRTUAL_NUMBER,
                                'Reply to this SMS to talk to UserA');

    /*  
        Send a message from userB to the virtual number
    */
    this.nexmo.message.sendSms(this.chat.userB,
                                process.env.VIRTUAL_NUMBER,
                                'Reply to this SMS to talk to UserB');
}
```

现在，我们需要在虚拟号码上拦截这些传入消息，并将它们代理到目标收件人的真实号码。

接收入站短信
------

当一个用户向另一个用户发送消息时，他们是向应用程序的虚拟号码而不是目标用户的真实号码发送消息。当 Vonage 在虚拟号码上收到入站短信时，它向与该号码关联的 Webhook 端点发出 HTTP 请求：

在 `server.js` 中，我们为 Vonage 服务器在您的虚拟号码收到短信时向应用程序发出的 `/webhooks/inbound-sms` 请求提供一个路由处理程序。我们在这里使用的是 `POST` 请求，您也可以使用 `GET` 或 `POST-JSON`。如[将应用程序公开到互联网](#expose-your-application-to-the-internet)中所述，这可以在 Dashboard 中进行配置。

我们从入站请求中检索 `from` 和 `text` 参数，并将它们传递给 `SmsProxy` 类，以确定将其发送给哪个真实号码：

```javascript
app.get('/webhooks/inbound-sms', (req, res) => {
    const from = req.query.msisdn;
    const to = req.query.to;
    const text = req.query.text;

    // Route virtual number to real number
    smsProxy.proxySms(from, text);

    res.sendStatus(204);
});
```

我们返回 `204` 状态 (`No content`) 来表示成功收到消息。这一步很重要，因为如果我们不确认收到消息，Vonage 服务器将反复尝试传递该消息。

### 确定如何路由短信

您已经知道发送短信的用户的真实号码，现在可以将消息转发给另一个用户的真实号码。此逻辑在 `SmsProxy` 类的 `getDestinationRealNumber()` 方法中实现：

```javascript
getDestinationRealNumber(from) {
    let destinationRealNumber = null;

    // Use `from` numbers to work out who is sending to whom
    const fromUserA = (from === this.chat.userA);
    const fromUserB = (from === this.chat.userB);

    if (fromUserA || fromUserB) {
        destinationRealNumber = fromUserA ? this.chat.userB : this.chat.userA;
    }

    return destinationRealNumber;
}
```

您可以确定将消息发送给哪个用户，现在要做的就是发送消息！

### 代理短信

将短信代理到目标收件人的真实电话号码。`from` 号码始终是虚拟号码（为了保持用户的匿名性），`to` 是用户的真实电话号码。

```javascript
proxySms(from, text) {
    // Determine which real number to send the SMS to
    const destinationRealNumber = this.getDestinationRealNumber(from);

    if (destinationRealNumber  === null) {
        console.log(`No chat found for this number);
        return;
    }

    // Send the SMS from the virtual number to the real number
    this.nexmo.message.sendSms(process.env.VIRTUAL_NUMBER,
                                destinationRealNumber,
                                text);
}
```

试试看
---

### 将应用程序公开到互联网

当短信 API 收到发往虚拟号码的短信时，它会通过 [Webhook](/concepts/guides/webhooks) 提醒您的应用程序。Webhook 为 Vonage 服务器提供了一种与您的应用程序进行通信的机制。

为了让您的应用程序可供 Vonage 服务器访问，必须在互联网上公开它。在开发和测试期间实现此目标的一种简单方法是使用 [ngrok](https://ngrok.com)，该服务通过安全隧道将本地服务器公开到公共互联网。有关更多详细信息，请参阅[此博客文章](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)。

下载并安装 [ngrok](https://ngrok.com)，然后使用以下命令启动它：

```sh
ngrok http 3000
```

这会为本地计算机的端口 3000 上运行的任何网站创建公共 URL（HTTP 和 HTTPS）。

使用位于 http://localhost:4040 的 `ngrok` Web 接口，并记下 `ngrok` 提供的 URL。

转到[帐户设置](https://dashboard.nexmo.com/settings)页面，然后在“入站消息”文本框中输入 Webhook 端点的完整 URL。例如，如果您使用 `ngrok`，那么您的 URL 可能类似于以下内容：

    https://33ab96a2.ngrok.io/webhooks/inbound-sms

确保从“HTTP 方法”下拉列表中选择 `POST`，以便 Vonage 知道您的应用程序希望通过 `POST` 请求来传递消息详细信息。

### 开始聊天

向应用程序的 `/chat` 端点发出 `POST` 请求，并传入用户的真实号码作为请求参数。

您可以为此使用 [Postman](https://www.getpostman.com)，也可以使用类似于以下内容的 `curl` 命令，并将 `USERA_REAL_NUMBER` 和 `USERB_REAL_NUMBER` 替换为用户的真实号码：

```sh
curl -X POST \
  'http://localhost:3000/chat?userANumber=USERA_REAL_NUMBER&userBNumber=USERB_REAL_NUMBER' 
```

### 继续聊天

每个用户都应该从应用程序的虚拟号码收到一条短信。当用户回复该号码时，回复内容将传递到另一个用户的真实号码，但显示为来自虚拟号码。

结语
---

在本教程中，您学习了如何构建短信代理，使两个用户互发短信时都不会看到对方的真实号码。

接下来做什么？
-------

要将该示例应用程序扩展为使用相同的虚拟号码主持多个聊天，可以使用 `SmsProxy.createChat()` 为不同的用户对实例化并存留一个单独的 `chat` 对象。例如，您可能有一个 `chat` 对象供 `userA` 和 `userB` 对话，另一个供 `userC` 和 `userD` 对话。

您可以创建路由，让您可以看到所有当前聊天，也可以在聊天结束时终止聊天。

以下资源将帮助您了解有关本教程中学到的知识的更多信息：

* [GitHub 上的教程代码](https://github.com/Nexmo/node-sms-proxy)
* [私人短信用例](https://www.nexmo.com/use-cases/private-sms-communication)
* [短信 API 参考指南](/api/sms)
* [其他短信 API 教程](/messaging/sms/tutorials)
* [设置并使用 Ngrok](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)

