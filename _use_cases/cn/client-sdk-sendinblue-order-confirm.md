---
title:  订单支持系统

products: client-sdk

description:  如何利用 Vonage Client SDK 和 Sendinblue 构建产品订单确认和支持系统。

languages:
    - Node


---

订单支持系统
======

开始之前
----

假定您同时具有 [Vonage 帐户](https://dashboard.nexmo.com/sign-in)和 [Sendinblue 帐户](https://app.sendinblue.com/account/register)，以及关联的 API 密钥和密码。

概述
---

在本用例中，您将学习如何使用 Vonage Client SDK 和 Sendinblue 构建订单确认和支持系统。本用例主要介绍如何与支持座席进行双向聊天，以及通过 Sendinblue 发送订单确认电子邮件。

场景如下：

1. 用户创建订单。订单确认电子邮件通过 [Sendinblue](https://www.sendinblue.com) 发送给用户。订单电子邮件中包含一个链接，用户可以点击该链接与支持座席就订单进行聊天。

2. 当确认电子邮件发出时，系统会创建一个[自定义事件](/client-sdk/custom-events)。该事件保留在该用户的对话中。

3. 系统会加载一个聊天界面，里面有当前的订单数据、订单历史记录和消息历史记录。订单和消息历史记录存储在与用户关联的对话中。

4. 然后，客户和支持座席就可以进行双向聊天了。

安装
---

以下过程假定您在命令行上可以使用 `git` 和 `npm` 命令。

**1\.** 安装 Nexmo CLI：

```bash
npm install nexmo-cli@beta -g
```

> **注意：** 本演示必需 Nexmo CLI 测试版。

**2\.** 初始化您的凭据，以便在 Nexmo CLI 中使用：

```bash
nexmo setup NEXMO_API_KEY NEXMO_API_SECRET
```

这将更新 Linux 或 macOS 上的 `~/.nexmorc` 文件。在 Windows 上，该文件存储在用户目录中，例如，`C:\Users\James\.nexmorc`。

**3\.** 克隆用于本用例的 GitHub 存储库：

```bash
git clone https://github.com/nexmo-community/sendinblue-use-case.git
```

**4\.** 切换到克隆的项目目录。

**5\.** 安装所需的 NPM 模块：

```bash
npm install
```

这会基于 `package.json` 文件安装所需的模块。

**6\.** 将 `example.env` 复制到项目目录中的 `.env`。您将在后面的步骤中编辑 `.env`，以指定凭据和其他配置信息。

**7\.** 在[交互模式](/application/nexmo-cli#interactive-mode)下创建 Vonage 应用程序。以下命令将进入交互模式：

```bash
nexmo app:create
```

a. 指定应用程序名称。按 Enter 键继续。

b. 使用箭头键指定 RTC 功能，然后按空格键进行选择。按 Enter 键继续。

c. 对于“是否使用默认的 HTTP 方法?”，按 Enter 键选择默认值。

d. 对于“RTC 事件 URL”，输入 `https://example.ngrok.io/webhooks/rtc` 或其他合适的 URL（具体取决于您的测试方式）。

e. 对于“公钥路径”，按 Enter 键选择默认值。

f. 对于“私钥路径”，输入 `private.key`，然后按 Enter 键。

即会创建该应用程序。

系统将在包含应用程序 ID 和私钥的项目目录中创建 `.nexmo-app` 文件。

**8\.** 使用编辑器打开项目目录中的 `.env` 文件。

**9\.** 将 Vonage 应用程序 ID 添加到 `.env` 文件中 (`NEXMO_APPLICATION_ID`)。

配置
---

设置以下信息：

```text
NEXMO_APPLICATION_ID=App ID for the application you just created
NEXMO_API_KEY=
NEXMO_API_SECRET=
NEXMO_APPLICATION_PRIVATE_KEY_PATH=private.key
CONVERSATION_ID=
PORT=3000
SENDINBLUE_API_KEY=
SENDINBLUE_FROM_NAME=
SENDINBLUE_FROM_EMAIL=
SENDINBLUE_TO_NAME=
SENDINBLUE_TO_EMAIL=
SENDINBLUE_TEMPLATE_ID=
```

1. 设置 Vonage API 密钥和密码。您可以从 [Dashboard](https://dashboard.nexmo.com) 中获取 Vonage API 密钥和 Vonage API 密码。
2. 设置端口号。所示示例假定您正在使用端口 3000，但您可以使用任何方便的空闲端口。

> **注意：** 对话 ID 仅供测试时使用。现阶段无需进行配置。

您现在将继续进行 Sendinblue 配置。

### Sendinblue 配置

您必须具有 [Sendinblue API 密钥](https://account.sendinblue.com/advanced/api)。

为了测试本用例，假定您具有 Sendinblue“发件人”信息。这是发送电子邮件的 **发件人** 电子邮件地址和名称。

您还应该指定一个用户名和电子邮件地址来接收订单确认电子邮件。通常，此信息会在用户数据库中按客户提供，但在本用例中，为了便于测试，它将在环境文件中设置。这是接收您发送的电子邮件的 **收件人** 电子邮件地址和名称。

您还需要提供正在使用的[电子邮件模板](https://account.sendinblue.com/camp/lists/template)的 ID。该模板在 Sendinblue UI 中创建。创建并激活模板后，您可以记下 UI 中指定的 ID。这里用的就是这个编号。

下面提供了可在本演示中使用的示例模板：

    ORDER CONFIRMATION
    
    Dear {{params.name}},
    
    Thank you for your order!
    
    ORDER_ID
    
    {{params.order_id}}
    
    ORDER_TEXT
    
    {{params.order_text}}
    
    If you would like to discuss this order with an agent please click the link below:
    
    {{params.url}}
    
    Thanks again!

您可以使用此示例在 Sendinblue 中创建模板。

有关如何创建您自己的模板的信息，请参阅[用于创建模板的 Sendinblue](https://help.sendinblue.com/hc/en-us/articles/209465345-Where-do-I-create-and-edit-the-email-templates-used-in-SendinBlue-Automation-)。

> **重要说明：** 创建模板后，确保将模板 ID（Sendinblue UI 中提供的整数）添加到 `.env` 文件中，然后再继续操作。

运行代码
----

运行本演示有几个步骤。

**1\.** 在项目目录中启动服务器：

```bash
npm start
```

这会使用 `node.js` 启动服务器。

**2\.** 使用以下 Curl 命令创建支持座席用户：

    curl -d "username=agent" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://localhost:3000/user

检查服务器控制台日志记录，其中会有如下所示的响应：

    Creating user agent
    User agent and Conversation CON-7f1ae6c9-9f52-455e-b8e4-c08e96e6abcd created.

这会创建用户“agent”。在本演示中，对于“agent”，不使用对话。

> **重要说明：** 在这个简单的演示中，必须先于其他任何用户创建支持座席。在本用例中，座席必须具有用户名 `agent`。

**3\.** 创建客户用户：

    curl -d "username=user-123" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://localhost:3000/user

这会创建用户“user-123”。您可以在此处指定任何用户名。记下指定的用户名。

您会从服务器控制台日志记录中注意到，还为该用户创建了一个对话：

    Creating user user-123
    User user-123 and Conversation CON-7f1ae6c9-9f52-455e-b8e4-c08e96e6abcd created.

**4\.** 创建客户订单：

    curl -d "username=user-123" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://localhost:3000/order

这会为用户“user-123”创建订单。为简单起见，此处创建了一个简单的预定义静态订单，而不是完整的购物车。检查服务器控制台日志记录，您将看到与下面类似的内容：

```text
Creating order...
Order URL: http://localhost:9000/chat/user-1234/CON-7f1ae6c9-9f52-455e-b8e4-c08e96e6abcd/1234
Sending order email user-1234, 1234, Dear user-1234, You purchased a widget for $4.99! Thanks for your order!, http://localhost:9000/chat/user-1234/CON-7f1ae6c9-9f52-455e-b8e4-c08e96e6abcd/1234
API called successfully. Returned data: [object Object]
```

此步骤还会生成一个类型为 `custom:order-confirm-event` 并且包含订单详情的自定义事件。

此外，还会通过 Sendinblue 发送一封确认电子邮件。此电子邮件包含一个链接，如果用户想获得订单支持，可以选择该链接开始聊天。

**5\.** 检查您是否收到了订单电子邮件。转到配置中定义的收件箱，阅读确认电子邮件。

**6\.** 点击电子邮件中的链接，让客户登录到聊天界面。

**7\.** 让座席登录到聊天中。对于此步骤，建议您在浏览器中另外启动一个“隐身”选项卡（或使用新的浏览器实例）。

为简单起见，支持座席使用与客户类似的方法登录到聊天中。您可以直接复制客户在电子邮件中点击的链接，并将链接中的用户名更改为 `agent`：

    localhost:3000/chat/agent/CON-ID/ORDER-ID

用户和支持座席现在可以参与双向聊天消息传递会话，就订单进行讨论。

探索代码
----

主要代码文件是 `client.js` 和 `server.js`。

**服务器** 实现用于创建用户和订单的简单 REST API：

1. `POST` on `/user` - 创建用户。用户名在正文中传递。
2. `POST` on `/order` - 创建订单。创建订单者的用户名在正文中传递。
3. `GET` on `/chat/:username/:conversation_id/:order_id` - 根据 `username` 将用户或座席登录到聊天室。

**客户端** 使用 Vonage Client SDK。它执行以下主要功能：

1. 创建 `NexmoClient` 实例。
2. 根据服务器生成的 JWT 将用户登录到对话中。
3. 获取对话对象。
4. 注册消息发送按钮和 `text` 事件的事件处理程序。
5. 提供基本 UI，用于显示当前订单、订单历史记录和消息历史记录以及正在进行的聊天。

摘要
---

在本用例中，您学习了如何构建订单确认和支持系统。用户通过 Sendinblue 接收订单确认电子邮件。然后，用户可以根据需要与支持座席进行双向消息传递，就订单进行讨论。

接下来做什么？
-------

关于改进演示的一些建议：

* 使用 CSS 改进 UI。
* 添加更完善的订购系统。也许每个订单都是一个 JSON 代码段。
* 添加[点击呼叫](/client-sdk/tutorials/app-to-phone/introduction)支持座席的功能。
* 当用户加入聊天室时，向座席发送短信通知。

参考
---

* [GitHub 上的演示代码存储库](https://github.com/nexmo-community/sendinblue-use-case)
* [适用于 Node 的 Sendinblue 客户端库](https://github.com/sendinblue/APIv3-nodejs-library)
* [Sendinblue 发送交易电子邮件](https://developers.sendinblue.com/docs/send-a-transactional-email)
* [Client SDK 文档](/client-sdk/overview)
* [对话 API 文档](/conversation/overview)
* [对话 API 参考](/api/conversation)

