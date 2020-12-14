---
title:  接收级联短信

products: messaging/sms

description:  如果入站短信超过单条短信允许的最大长度，则会被拆分为多个部分。然后由您重组这些部分，以显示完整的消息。本教程将告诉您如何操作。

languages:
  - Node


---

接收级联短信
======

[超过一定长度](/messaging/sms/guides/concatenation-and-encoding)的短信消息会被拆分为两条或更多条较短的消息，并作为多条短信发送。

当您使用短信 API 接收可能比单条短信允许的字节长度更长的[入站短信](/messaging/sms/guides/inbound-sms)时，您必须查看传递到 [Webhook](/concepts/guides/webhooks) 的消息是独立的还是多部分短信的一部分。如果消息包含多个部分，则必须重组它们以显示完整的消息文本。

本教程将告诉您如何操作。

教程内容
----

在本教程中，您将使用 Express 框架创建一个简单的 Node.js 应用程序，该应用程序通过 Webhook 接收入站短信，并确定消息是单部分短信还是多部分短信。

如果传入短信是多部分短信，应用程序会等到收到所有的消息部分，然后按照正确的顺序组合起来显示给用户。

为此，请执行以下步骤：

1. [创建项目](#create-the-project) - 创建一个 Node.js/Express应用程序
2. [将应用程序公开到互联网](#expose-your-application-to-the-internet) - 使用 `ngrok` 支持 Vonage 通过 Webhook 访问您的应用程序
3. [创建基本应用程序](#create-the-basic-application) - 使用 Webhook 构建应用程序以接收入站短信
4. [向 Vonage 注册 Webhook](#register-your-webhook-with-nexmo) - 向 Vonage 服务器告知您的 Webhook
5. [发送测试短信](#send-a-test-sms) - 确保您的 Webhook 可以接收传入短信
6. [处理多部分短信](#handle-multi-part-sms) - 将多部分短信重组为一条消息
7. [测试级联短信的接收情况](#test-receipt-of-a-concatenated-sms) - 看看实际效果！

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up) - 用于获取 API 密钥和密码
* [ngrok](https://ngrok.com/) -（可选）使 Vonage 服务器可以通过互联网访问您的开发 Web 服务器

创建项目
----

为应用程序创建一个目录，使用 `cd` 进入该目录，然后使用 Node.js 包管理器 `npm` 为应用程序的依赖项创建一个 `package.json` 文件：

```sh
mkdir myapp
cd myapp
npm init
```

按 [Enter] 键接受每个默认值，`entry point` 除外（应为其输入 `server.js`）。

然后，安装 [Express](https://expressjs.com) Web 应用程序框架和 [body-parser](https://www.npmjs.com/package/body-parser) 软件包：

```sh
npm install express body-parser --save
```

将应用程序公开到互联网
-----------

当短信 API 收到发往您的某个虚拟号码的短信时，它会通过 [Webhook](/concepts/guides/webhooks) 提醒您的应用程序。Webhook 为 Vonage 服务器提供了一种与您的应用程序进行通信的机制。

为了让您的应用程序可供 Vonage 服务器访问，必须在互联网上公开它。在开发和测试期间实现此目标的一种简单方法是使用 [ngrok](https://ngrok.com)，该服务通过安全隧道将本地服务器公开到公共互联网。有关更多详细信息，请参阅[此博客文章](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)。

下载并安装 [ngrok](https://ngrok.com)，然后使用以下命令启动它：

```sh
ngrok http 5000
```

此命令将为本地计算机的端口 5000 上运行的任何网站创建公共 URL（HTTP 和 HTTPS）。

使用位于 http://localhost:4040 的 `ngrok` Web 接口，并记下 `ngrok` 提供的 URL：您需要它们来完成本教程。

创建基本应用程序
--------

使用以下代码在应用程序目录中创建一个 `server.js` 文件，这将是我们的起点：

```javascript
require('dotenv').config();
const app = require('express')();
const bodyParser = require('body-parser');

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

app
    .route('/webhooks/inbound-sms')
    .get(handleInboundSms)
    .post(handleInboundSms);

const handleInboundSms = (request, response) => {
    const params = Object.assign(request.query, request.body);

    // Send OK status
    response.status(204).send();
}

app.listen('5000');
```

此代码执行以下操作：

* 初始化依赖项（`express` 框架和用于解析 [POST] 请求的 `body-parser`）。
* 向 Express 注册一个 `/webhooks/inbound-sms` 路由，该路由同时接受 [GET] 和 [POST] 请求。当我们的某个虚拟号码收到短信时，Vonage API 将使用此 Webhook 与我们的应用程序进行通信。
* 为名为 `handleInboundSms()` 的路由创建一个处理程序函数，该函数显示一条消息，告诉我们已收到入站短信，并向 Vonage API 返回 HTTP `success` 响应。最后一步很重要，如果不执行这一步，Vonage 将继续尝试传递该短信，直至超时。
* 在端口 5000 上运行应用程序服务器。

向 Vonage 注册 Webhook
-------------------

您已经创建了 Webhook，现在需要告诉 Vonage 它在哪里。登录您的 [Vonage 帐户 Dashboard](https://dashboard.nexmo.com/)，访问[设置](https://dashboard.nexmo.com/settings)页面。

在您的应用程序中，Webhook 位于 `/webhooks/inbound-sms` 中。如果您使用的是 Ngrok，您需要配置的完整 Webhook 端点类似于 `https://demo.ngrok.io/webhooks/inbound-sms`，其中 `demo` 是 Ngrok 提供的子域（通常类似于 `0547f2ad`）。

在标记为 **入站消息的 Webhook URL** 的字段中输入 Webhook 端点，然后点击 [保存更改] 按钮。

```screenshot
script: app/screenshots/webhook-url-for-inbound-message.js
image: public/screenshots/smsInboundWebhook.png
```

现在，如果您的任何一个虚拟号码收到短信，Vonage 都将使用消息详细信息调用该 Webhook 端点。

发送测试短信
------

1. 打开一个新的终端窗口并运行 `server.js` 文件，以便它侦听传入短信：

   ```sh
   node server.js
   ```

2. 用您的移动设备向您的 Vonage 号码发送一条包含短文本消息的测试短信。例如，“这是一条短文本消息”。

如果一切配置正确，您应该在运行 `server.js` 的终端窗口中收到 `Inbound SMS received` 消息。

现在，让我们编写一些代码来解析传入短信，以查看消息包含的内容。

1. 按 [CTRL\+C] 终止正在运行的 `server.js` 应用程序。

2. 在 `server.js` 中创建一个名为 `displaySms()` 的新函数：

   ```javascript
   const displaySms = (msisdn, text) => {
       console.log('FROM: ' + msisdn);
       console.log('MESSAGE: ' + text);
       console.log('---');
   }
   ```

3. 同样在 `server.js` 中，就在您的代码发送 `204` 响应之前，使用以下参数添加对 `displaySms()` 的调用：

   ```javascript
   displaySms(params.msisdn, params.text);
   ```

4. 重新启动 `server.js`，然后用您的移动设备再发送一条短消息。这次，您应该在运行 `server.js` 的终端窗口中看到以下内容：

   ```sh
   Inbound SMS received
   FROM: <YOUR_MOBILE_NUMBER>
   MESSAGE: This is a short text message.
   ```

5. 让 `server.js` 保持运行，但这次使用移动设备发送的消息比单条短信允许的最大长度长得多。例如，狄更斯《双城记》的第一句话：

       It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way ... in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.'

6. 在运行 `server.js` 的终端窗口中检查输出。您应该看到与下面类似的内容：

       ---
       Inbound SMS received
       FROM: <YOUR_MOBILE_NUMBER>
       MESSAGE: It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epo
       ---
       Inbound SMS received
       FROM: <YOUR_MOBILE_NUMBER>
       MESSAGE: ch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything
       ---
       Inbound SMS received
       FROM: <YOUR_MOBILE_NUMBER>
       MESSAGE: e the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of compariso
       ---
       Inbound SMS received
       FROM: <YOUR_MOBILE_NUMBER>
       MESSAGE:  before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way ... in short, the period was so far lik
       ---
       Inbound SMS received
       FROM: <YOUR_MOBILE_NUMBER>
       MESSAGE: n only.
       ---

发生了什么？该消息超出了单条短信的字节限制，因此已作为多条短信消息发送。

为了能够以预期的格式向用户显示此类消息，我们需要检测是否以这种方式拆分了传入消息，然后根据各个部分重组该消息。

> 请注意，在以上输出中，各部分未按正确的顺序到达。这并不少见，所以我们需要编写 Webhook 来处理这种情况。

处理多部分短信
-------

当入站短信级联时，Vonage 会向您的 Webhook 传递四个特殊参数。（当短信为单部分时，这些参数不会出现在请求中。）您可以使用它们将各个部分重组为一个连贯的整体：

* `concat:true` - 当消息级联时
* `concat-ref` - 唯一的参考，使您能够确定特定消息部分属于哪条短信
* `concat-total` - 构成整条短信的各部分的总数
* `concat-part` - 此消息部分在整个消息中的位置，以便您可以按照正确的顺序重组各部分

### 检测消息是否级联

首先，您需要检测消息是否级联。修改 `handleInboundSms()` 函数，使其以通常的方式向用户显示单部分短信，但对多部分短信进行额外的处理，您将在后面的步骤中实现此操作：

```javascript
const handleInboundSms = (request, response) => {
    const params = Object.assign(request.query, request.body);

    if (params['concat'] == 'true') {
        // Perform extra processing
    } else {
        // Not a concatenated message, so just display it
        displaySms(params.msisdn, params.text);
    }   
    
    // Send OK status
    response.status(204).send();
}
```

### 存储多部分短信供以后处理

我们需要存储任何属于较大消息的入站短信，以便在得到所有部分后能够处理它们。

在 `handleInboundSms()` 函数外部声明一个名为 `concat_sms` 的数组。如果传入短信是较长消息的一部分，则将其存储在该数组中：

```javascript
let concat_sms = []; // Array of message objects

const handleInboundSms = (request, response) => {
    const params = Object.assign(request.query, request.body);

    if (params['concat'] == 'true') {
        /* This is a concatenated message. Add it to an array
           so that we can process it later. */
        concat_sms.push({
            ref: params['concat-ref'],
            part: params['concat-part'],
            from: params.msisdn,
            message: params.text
        });
    } else {
        // Not a concatenated message, so just display it
        displaySms(params.msisdn, params.text);
    }   
    
    // Send OK status
    response.status(204).send();
}
```

### 收集所有消息部分

在尝试从消息各部分重组消息之前，我们需要根据给定的消息参考，确保收集了所有部分。请记住，我们不能保证所有部分都以正确的顺序到达，因此我们要做的并不只是检查 `concart-part` 是否等于 `concat-total`。

为此，我们可以过滤 `concat_sms` 数组，以仅包含与我们刚收到的短信共用同一 `concat-ref` 的短信对象。如果过滤后的数组的长度与 `concat-total` 相同，则表示我们得到了该消息的所有部分，然后可以重组它们：

```javascript
    if (params['concat'] == 'true') {
        /* This is a concatenated message. Add it to an array
           so that we can process it later. */
        concat_sms.push({
            ref: params['concat-ref'],
            part: params['concat-part'],
            from: params.msisdn,
            message: params.text
        });

        /* Do we have all the message parts yet? They might
           not arrive consecutively. */
        const parts_for_ref = concat_sms.filter(part => part.ref == params['concat-ref']);

        // Is this the last message part for this reference?
        if (parts_for_ref.length == params['concat-total']) {
            console.dir(parts_for_ref);
            processConcatSms(parts_for_ref);
        }
    } 
```

### 重组消息部分

我们已经收集了所有消息部分，但顺序并不一定正确，现在我们可以使用 `Array.sort()` 函数按 `concat-part` 顺序重组它们。创建 `processConcatSms()` 函数以执行此操作：

```javascript
const processConcatSms = (all_parts) => {

    // Sort the message parts
    all_parts.sort((a, b) => a.part - b.part);

    // Reassemble the message from the parts
    let concat_message = '';
    for (i = 0; i < all_parts.length; i++) {
        concat_message += all_parts[i].message;
    }

    displaySms(all_parts[0].from, concat_message);
}
```

测试级联短信的接收情况
-----------

运行 `server.js`，并使用您的移动设备重新发送您在上述[发送测试短信](#send-a-test-sms)部分的步骤 5 中发送的长文本消息。

如果您已经正确编写所有代码，那么应该会看到各个消息部分到达 `server.js` 窗口。收到所有部分后，将显示完整消息：

    [ { ref: '08B5',
        part: '3',
        from: '<YOUR_MOBILE_NUMBER>',
        message: ' before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way ... in short, the period was so far lik' },
      { ref: '08B5',
        part: '1',
        from: '<YOUR_MOBILE_NUMBER>',
        message: 'It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epo' },
      { ref: '08B5', part: '5', from: 'TEST-NEXMO', message: 'n only.' },
      { ref: '08B5',
        part: '2',
        from: '<YOUR_MOBILE_NUMBER>',
        message: 'ch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything' },
      { ref: '08B5',
        part: '4',
        from: '<YOUR_MOBILE_NUMBER>',
        message: 'e the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of compariso' } ]
    FROM: <YOUR_MOBILE_NUMBER>
    MESSAGE: It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of Light, it was the season of Darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to Heaven, we were all going direct the other way ... in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.
    ---

结语
---

在本教程中，您创建了一个简单的应用程序，展示如何根据构成级联短信的消息部分重组该短信。您了解了入站短信 Webhook 的 `concat`、`concat-ref`、`concat-total` 和 `concat-part` 请求参数，以及如何使用它们来确定：

* 入站短信是否级联
* 特定消息部分属于哪条消息
* 完整消息由多少个消息部分构成
* 完整消息中特定消息部分的顺序

接下来做什么？
-------

以下资源将帮助您在应用程序中使用 Number Insight：

* GitHub 上本教程的[源代码](https://github.com/Nexmo/sms-node-concat-tutorial)
* [短信 API 产品页面](https://www.nexmo.com/products/sms)
* [入站短信概念](/messaging/sms/guides/inbound-sms)
* [Webhook 指南](/concepts/guides/webhooks)
* [短信 API 参考](/api/sms)
* [使用 ngrok 隧道将本地开发服务器连接到 Vonage API](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)
* [更多短信 API 教程](/messaging/sms/tutorials)

