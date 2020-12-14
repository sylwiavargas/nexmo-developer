---
title:  点击呼叫

products: client-sdk

description:  了解如何让客户直接从您的网站给您打电话。

languages:
  - Node


---

让客户从您的网站给您打电话
=============

为了向客户提供最佳服务，您希望他们能够使用他们趁手和熟悉的通信方式快速、方便地联系您。与其让他们在“联系我们”页面上搜索您的电话号码，为何不在网站上为他们设置一个可拨打电话的按钮呢？

在本用例中，我们假设您的网站上有一个支持页面。您将添加一个按钮，该按钮使用 Client SDK 呼叫您的 Vonage 虚拟号码，并将呼叫转接到“真实”号码，您可以在其中处理他们的支持查询。

本示例使用客户端 JavaScript 显示该按钮并拨打电话，在后端使用 node.js 验证用户身份并将呼叫路由到所选号码。不过，您可以改为使用客户端 [iOS](/sdk/stitch/ios/) 或 [Android](/sdk/stitch/android/) SDK 和类似的方法来构建移动应用。

所有代码都[可以在 GitHub 上找到](https://github.com/nexmo-community/client-sdk-click-to-call)

先决条件
----

为了完成本用例，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 已安装并配置 [Nexmo CLI](https://github.com/nexmo/nexmo-cli)。
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。如果您在本地进行开发，建议使用 [ngrok](https://ngrok.com/)。

入门
---

开始使用代码之前，您需要完成一些初始设置。

### 克隆存储库

从 GitHub 下载源代码：

    git clone https://github.com/nexmo-community/client-sdk-click-to-call
    cd client-sdk-click-to-call

### 安装 Nexmo CLI

您可以使用[开发人员 Dashboard](https://dashboard.nexmo.com) 执行其中一些初始步骤。但是，Nexmo CLI 通常更易使用，并且在后面的一些步骤中，我们还需要用到它，因此请在继续操作前安装 Nexmo CLI 测试版：

```sh
npm install nexmo-cli@beta 
```

然后，使用您的 API 密钥和密码配置 Nexmo CLI：

```sh
nexmo setup API_KEY API_SECRET
```

### 购买 Vonage 号码

您需要一个 Vonage 虚拟号码供客户拨打电话。您可以使用以下 CLI 命令为所选国家/地区代码购买可用的号码：

    nexmo number:buy -c GB --confirm

只需将 `GB` 替换为您自己的[国家/地区代码](https://www.iban.com/country-codes)即可。

创建应用程序
------

千万不要把包含逻辑的应用程序本身和 Vonage 应用程序混淆了。

Vonage 应用程序是存储安全信息和配置信息的容器。创建 Vonage 应用程序时，需要指定一些 [Webhook](https://developer.nexmo.com/concepts/guides/webhooks) 端点；这些端点是您的代码公开的 URL，必须能够公开访问。当主叫方拨打您的 Vonage 号码时，Vonage 会向您指定的 `answer_url` 端点发出 HTTP 请求，并按照在此找到的说明进行操作。如果您提供 `event_url` 端点，Vonage 将为您的应用程序更新呼叫事件，这些事件可以帮助您排查任何问题。

要创建 Vonage 应用程序，请使用 Nexmo CLI 运行以下命令，并将两个 URL 中的 `YOUR_SERVER_HOSTNAME` 替换为您自己的服务器的主机名：

```bash
nexmo app:create --keyfile private.key ClickToCall https://YOUR_SERVER_HOSTNAME/webhooks/answer https://YOUR_SERVER_NAME/webhooks/event
```

此命令返回唯一的应用程序 ID。将其复制到某个地方，稍后会用到它！

参数包括：

* `ClickToCall` - Vonage 应用程序的名称
* `private.key` - 存储私钥以进行身份验证的文件的名称。此文件会下载到您的应用程序的根目录中。
* `https://example.com/webhooks/answer` - 当您收到 Vonage 号码的呼入电话时，Vonage 会发出 `GET` 请求，并检索 [NCCO](/voice/voice-api/ncco-reference)，该对象会告诉 Vonage API 如何处理该呼叫
* `https://example.com/webhooks/event` - 当呼叫状态发生变化时，Vonage 会将状态更新发送到该 Webhook 端点

链接 Vonage 号码
------------

您需要告诉 Vonage，该应用程序使用哪个虚拟号码。执行以下 CLI 命令，并将 `NEXMO_NUMBER` 和 `APPLICATION_ID` 替换为您自己的值：

    nexmo link:app NEXMO_NUMBER APPLICATION_ID

创建用户
----

您需要使用 Client SDK 验证用户身份，他们才能拨打您的 Vonage 号码。使用以下 CLI 命令创建一个名为 `supportuser` 的用户，该命令将返回该用户的唯一 ID。在本示例中，您无需跟踪该 ID，因此可以放心地忽略此命令的输出：

    nexmo user:create name="supportuser"

生成 JWT
------

Client SDK 使用 [JWT](/concepts/guides/authentication#json-web-tokens-jwt) 进行身份验证。执行以下命令创建 JWT，并将 `APPLICATION_ID` 替换为您自己的 Vonage 应用程序 ID。JWT 会在一天（Vonage JWT 的最大生命周期）后过期，过期后，您需要重新生成它。

    nexmo jwt:generate ./private.key sub=supportuser exp=$(($(date +%s)+86400)) acl='{"paths":{"/*/users/**":{},"/*/conversations/**":{},"/*/sessions/**":{},"/*/devices/**":{},"/*/image/**":{},"/*/media/**":{},"/*/applications/**":{},"/*/push/**":{},"/*/knocking/**":{}}}' application_id=APPLICATION_ID

配置应用程序
------

示例代码使用 `.env` 文件存储配置详细信息。将 `example.env` 复制到 `.env` 并按如下方式进行填充：

    PORT=3000
    JWT= /* The JWT for supportuser */
    SUPPORT_PHONE_NUMBER= /* The Vonage Number that you linked to your application */
    DESTINATION_PHONE_NUMBER= /* A target number to receive calls on */

您在 `.env` 中提供的电话号码应省略所有前导零并包含国家/地区代码。

例如（使用 GB 手机号码 `07700 900000`）：`447700900000`。

试试看！
----

运行以下命令，安装所需的依赖项：

```sh
npm install
```

确保 Vonage API 可以从公共互联网访问您的应用程序。[您可以使用 ngrok 实现此目的](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr)：

```sh
ngrok http 3000
```

启动应用程序本身：

    npm start

在浏览器中访问 `http://localhost:3000`。如果一切配置正确，您将看到“Acme Inc 支持”主页，以及一条指出 `supportuser` 已登录的消息。

点击“立即呼叫\!”按钮，一两分钟后，您会听到一条欢迎消息，接着，`DESTINATION_PHONE_NUMBER` 中指定的号码会响起。点击“挂断”按钮终止呼叫。

服务器端代码
------

让我们深入研究代码，了解此示例的工作方式。这里需要考虑两个方面：用于验证用户身份和拨打电话的客户端代码，以及用于管理呼叫本身的服务器端代码。

服务器端代码包含在 `server.js` 文件中。我们使用 `express` 框架创建服务器并公开应用程序所需的 URL，使用 `pug` 模板引擎根据 `views` 目录中的模板创建网页。当用户访问应用程序的根目录 (`https://localhost:3000`) 时，我们呈现 `index.pug` 中定义的初始视图。

我们通过提供 `public` 目录中的所有内容（客户端代码和样式表）来提供客户端所需的一切。为了使 Client SDK for JavaScript 可供客户端代码使用，我们还提供了 `node_modules` 中的相应代码文件：

```javascript
const express = require('express');
const app = express();

require('dotenv').config();

app.set('view engine', 'pug');

app.use(express.static('public'))
app.use('/modules', express.static('node_modules/nexmo-client/dist/'));

const server = app.listen(process.env.PORT || 3000);

app.get('/', (req, res) => {
  res.render('index');
})
```

### 提供 JWT

客户端将调用 `/auth` 路由，以检索指定用户的正确 JWT。在本示例中，我们有一个已在 `.env` 文件中配置 JWT 的用户，但在生产应用程序中，我们希望动态生成这些 JWT。

```javascript
app.get('/auth/:userid', (req, res) => {
  console.log(`Authenticating ${req.params.userid}`)
  return res.json(process.env.JWT);
})
```

### 应答 Webhook

当客户拨打我们的 Vonage 虚拟号码时，Vonage API 将向指定为应答 URL 的 Webhook 发出 `GET` 请求，并预期检索到一个 JSON 对象（Nexmo 呼叫控制对象或 NCCO），该对象包含指示 Vonage 如何处理呼叫的操作数组。

在本实例中，我们使用 `talk` 操作读出欢迎消息，然后使用 `connect` 操作将呼叫路由到所选号码：

```javascript
app.get('/webhooks/answer', (req, res) => {
  console.log("Answer:")
  console.log(req.query)
  const ncco = [
    {
      "action": "talk",
      "text": "Thank you for calling Acme support. Transferring you now."
    },
    {
      "action": "connect",
      "from": process.env.NEXMO_NUMBER,
      "endpoint": [{
        "type": "phone",
        "number": process.env.DESTINATION_PHONE_NUMBER
      }]
    }]
  res.json(ncco);
});
```

### 事件 Webhook

每当发生与呼叫相关的事件时，Vonage API 都会向创建 Vonage 应用程序时指定的事件 Webhook 端点发出 HTTP 请求。在这里，我们直接将这些信息输出到控制台，以便可以看到发生了什么：

```javascript
app.post('/webhooks/event', (req, res) => {
  console.log("EVENT:")
  console.log(req.body)
  res.status(200).end()
});
```

客户端代码
-----

客户端代码位于 `/public/js/client.js` 中，在页面加载完成后执行。它负责验证用户身份并拨打电话。

### 验证用户身份

客户端代码要做的第一件事是从服务器上为用户获取正确的 JWT，以便我们可以使用 Client SDK 对该用户进行身份验证：

```javascript
  // Fetch a JWT from the server to authenticate the user
  const response = await fetch('/auth/supportuser');
  const jwt = await response.json();

  // Create a new NexmoClient instance and authenticate with the JWT
  let client = new NexmoClient();
  application = await client.login(jwt);
  notifications.innerHTML = `You are logged in as ${application.me.name}`;
```

### 拨打电话

当用户点击“立即呼叫\!”按钮时，我们使用经过身份验证的 `application` 对象的 `callServer` 方法来发起呼叫并更改按钮状态：

```javascript
  // Whenever we click the call button, trigger a call to the support number
  // and hide the Call Now button
  btnCall.addEventListener('click', () => {
    application.callServer();
    toggleCallStatusButton('in_progress');
  });
});

function toggleCallStatusButton(state) {
  if (state === 'in_progress') {
    btnCall.style.display = "none";
    btnHangup.style.display = "inline-block";
  } else {
    btnCall.style.display = "inline-block";
    btnHangup.style.display = "none";
  }
}
```

Vonage API 在我们的虚拟号码上收到呼入电话，并向服务器的应答 URL 端点发出请求以检索 NCCO，然后，NCCO 将呼叫转接到我们选择的设备。

### 终止通话

客户端代码要做的另一件事就是允许对话中的任一参与者通过点击“挂断”按钮来结束通话。当我们收到确认通话正在进行的事件时，我们会让该按钮变得可用。

该事件接收 `call` 对象作为参数，我们可以用它来控制通话：在本实例中，通过调用其 `hangup` 方法来终止通话。

我们还需要从 `call` 中检索活动对话，以便监视 `member:left` 事件，确定是否任何一方终止通话，并更改按钮状态作为响应：

```javascript
  // Whenever a call is made bind an event that ends the call to
  // the hangup button
  application.on("member:call", (member, call) => {
    let terminateCall = () => {
      call.hangUp();
      toggleCallStatusButton('idle');
      btnHangup.removeEventListener('click', terminateCall)
    };
    btnHangup.addEventListener('click', terminateCall);

    // Retrieve the Conversation so that we can determine if a 
    // Member has left and refresh the button state
    conversation = call.conversation;
    conversation.on("member:left", (member, event) => {
      toggleCallStatusButton('idle');
    });
  });
```

摘要
---

在本用例中，您学习了如何实现一种便捷的方式（点击网页上的按钮）让客户给您打电话。在这个过程中，您学习了如何创建 Vonage 应用程序，如何将虚拟号码链接到该应用程序，以及如何创建用户并验证其身份。

相关资源
----

* [完整源代码](https://github.com/nexmo-community/client-sdk-click-to-call)
* [Client SDK 文档](/client-sdk/overview)
* [应用内语音文档](/client-sdk/in-app-voice/overview)
* [联络中心用例](/client-sdk/in-app-voice/contact-center-overview)

