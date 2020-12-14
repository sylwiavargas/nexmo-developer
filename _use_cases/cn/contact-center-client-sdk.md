---
title:  联络中心

products: client-sdk

description:  如何构建您自己的联络中心应用程序。

languages:
    - Node


---

构建您自己的联络中心
==========

在本用例中，您将学习如何构建具有联络中心功能的应用程序。

您的联络中心应用程序有两个座席：`Jane` 和 `Joe`，他们是客户端应用程序的用户。座席拨打和接听应用内电话，而主叫方可以使用普通电话。

为实现此目标，本指南包括三个部分：

1. [**服务器端应用程序**](#set-up-your-backend)，用于执行基本的服务器端功能，例如管理用户和授权。这通过[对话 API](/conversation/overview) 实现。

2. [**客户端应用程序**](#set-up-your-client-side-application)，供联络中心用户登录、拨打和接听电话。这可以是集成了 [Vonage Client SDK](/client-sdk/in-app-voice/overview) 的 Web、iOS 或 Android 应用程序。

3. 在后端应用程序上利用[语音 API](/voice/voice-api/overview) [添加高级语音功能](#add-voice-functionality)。

> **注意：** 在后台，语音 API 和 Client SDK 都使用对话 API。这意味着所有通信都是通过[对话](/conversation/concepts/conversation)完成的。这允许您针对所有信道维护用户的通信上下文。您可以通过[对话 API](/conversation/overview)访问所有您可利用的对话和[事件](/conversation/concepts/event)。

开始之前
----

确保您拥有 Vonage 帐户，或[注册](https://dashboard.nexmo.com/)一个帐户，免费开始使用！

设置后端
----

要使用 Client SDK，您必须具有使用[对话 API](/conversation/overview) 的后端应用程序。某些功能（例如管理用户）只能通过后端完成。其他功能（例如创建对话）可以通过客户端和服务器端完成。

### 部署服务器端应用程序

您可以实现要用于[所需对话 API 功能](/conversation/guides/application-setup)的任何后端。

但是，为了帮助您开始使用本指南，您可以使用我们的演示示例后端应用程序。

#### Ruby on Rails 版本

[![部署](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/nexmo-community/contact-center-server-rails)

创建此项目的分支或参与此项目，它是一个开源项目，可从 [GitHub](https://github.com/nexmo-community/contact-center-server-rails) 上获得。

#### Node.js 版本

[![部署](https://www.herokucdn.com/deploy/button.svg)](https://heroku.com/deploy?template=https://github.com/nexmo-community/contact-center-server-node)

创建此项目的分支或参与此项目，它是一个开源项目，可从 [GitHub](https://github.com/nexmo-community/contact-center-server-node) 上获得。

### 创建 Vonage 应用程序

创建 Vonage 帐户后，您就可以创建多个 [Vonage 应用程序](/conversation/concepts/application)。Vonage 应用程序可以包含一组唯一的[用户](/conversation/concepts/user)和[对话](/conversation/concepts/conversation)。

在上一步中部署演示后端应用程序后，您需要：

1. 使用 *api 密钥* 和 *api 密码* （可以从 [Dashboard](https://dashboard.nexmo.com/) 获取）进行登录
   ![登录](/images/client-sdk/contact-center/login.png)

2. 通过键入应用程序名称并点击 *创建* ，创建一个新的 Vonage 应用程序
   ![设置](/images/client-sdk/contact-center/setup.png)

> 该操作使用 [Vonage 应用程序 API](/api/application.v2)。演示应用程序设置了所需的 Webhook 并将其公开，以方便您使用。更多内容将在下文提到。

### 连接 Vonage 号码

为了拨打和接听电话，您应该租用一个 [Vonage 号码](/numbers/overview)，并将其连接到 Vonage 应用程序。

使用我们的演示后端应用程序，导航到顶部栏上的 **号码** 选项卡，然后搜索一个号码。

![号码搜索](/images/client-sdk/contact-center/numbers-search.png)

租用号码后，将其分配给您创建的 Vonage 应用程序。

![号码分配](/images/client-sdk/contact-center/numbers.png)

> 有关更多功能和号码管理，请详细了解[号码 API](/numbers/overview) 或访问 [Dashboard](https://dashboard.nexmo.com/buy-numbers)。

### 创建用户

[用户](/conversation/concepts/user)可以登录到您的应用程序，以便创建对话、加入对话、拨打和接听电话等等。

在本指南中，您将使用两个用户，一个名为 `Jane`，另一个名为 `Joe`。每个用户代表一个可以登录到联络中心应用程序的座席。

要创建用户，请在演示后端应用程序界面的顶部菜单上选择 **用户** ，然后选择 **新建用户** 。

![新建用户](/images/client-sdk/contact-center/users-new.png)

它在后台使用[对话 API](https://developer.nexmo.com/api/conversation#createUser)。

为简单起见，演示应用程序会在用户尝试登录时创建他们。

### 验证用户身份

Vonage Client SDK 使用 [JWT](https://jwt.io/) 对登录 SDK 和 API 的用户进行身份验证。这些 JWT 使用新建 Vonage 应用程序时提供的应用程序 ID 和私钥生成。

出于安全原因，客户端应用不应持有私钥。因此，JWT 必须由后端提供。

后端应公开一个端点，该端点将允许客户端应用为每个用户请求一个有效的 JWT。在实际场景中，您可能会添加一个身份验证系统，以确保尝试登录应用的用户的身份。

在本指南中，后端演示应用程序公开了一个简单的端点，该端点使用演示应用程序提供的用户名和 API 密钥：

    POST YOUR_BACKEND/api/jwt

此请求正文中的有效负载如下：

    Payload: {"mobile_api_key":"xxxxxxx","user_name":"Jane"}

可以在 `SDK Integration` 页中找到 `mobile_api_key`，作为基本的安全机制。

> 有关在实际用例中实施身份验证系统的更多信息，可以[阅读此主题](/conversation/guides/user-authentication)。
> 您可以[在此主题中](/conversation/concepts/jwt-acl)阅读有关 JWT 和 ACL 的更多信息。

设置客户端应用程序
---------

### 选择客户端应用

Vonage Client SDK 支持 Web (JavaScript)、iOS 和 Android。

您可以[将该 SDK 集成](/client-sdk/setup/add-sdk-to-your-app)到自己的客户端应用程序中，并[添加应用内语音功能](/client-sdk/in-app-voice/guides/make-call)。

但是，要开始操作，您可以克隆并运行一个演示客户端应用程序。

#### iOS (Swift) 版本

下载、参与此项目或创建此项目的分支，它是一个开源项目，可在 [GitHub](https://github.com/nexmo-community/contact-center-client-swift) 上找到。

#### Android (Kotlin) 版本

下载、参与此项目或创建此项目的分支，它是一个开源项目，可在 [GitHub](https://github.com/nexmo-community/contact-center-client-android-kt) 上找到。

#### Web (JavaScript/React) 版本

下载、参与此项目或创建此项目的分支，它是一个开源项目，可在 [GitHub](https://github.com/nexmo-community/contact-center-client-react) 上找到。

> **重要说明：** 克隆后，请确保检查 `README` 文件并更新所需的客户端应用配置。

### 运行客户端应用

此时，您有一个客户端应用程序和一个支持它的后端应用程序。

您可以在两台不同的设备上运行客户端应用，在一台设备上以用户 `Jane` 的身份登录，在另一台设备上以用户 `Joe` 的身份登录。

您现在可以拨打和接听电话，并使用语音 API 添加其他高级语音功能。

添加语音功能
------

创建 Vonage 应用程序时，您为其分配了一个 `answer_url` [Webhook](/concepts/guides/webhooks)。`answer_url` 包含一旦向分配给 Vonage 应用程序的 Vonage 号码拨打电话就会执行的操作。这些操作在 `answer_url` 返回的 JSON 代码中定义，该代码采用 [Nexmo 呼叫控制对象 (NCCO)](/voice/voice-api/ncco-reference) 的结构。

更新从 `answer_url` 返回的 NCCO 会更改呼叫功能，并允许您向联络中心应用程序添加丰富的功能。

后端演示应用程序已经为您设置了 `answer_url` 端点。要更新它启用的 NCCO 内容和功能，请导航至顶部菜单上的 **应用设置** 。您将找到多个具有示例 NCCO 的按钮，以及一个提供自定义 NCCO 的按钮。

### 接听电话

在主要用例中，当主叫方呼叫联络中心应用程序时，请将呼叫连接到座席 `Jane`，该座席将在应用内接听电话。

点击`Inbound Call`按钮将生成如下所示的 NCCO：

```json
[
    {
        "action": "talk",
        "text": "Thank you for calling Jane"
    },
    {
        "action": "connect",
        "endpoint": [
            {
                "type": "app",
                "user": "Jane"
            }
        ]
    }
]
```

通过执行以下步骤尝试此操作：

1. 运行客户端应用。
2. 以 `Jane` 的身份登录。
3. 在另一部电话上，拨打分配给 Vonage 应用程序的 Vonage 号码。
4. 在客户端应用上接听电话。

### 拨打电话

要允许已登录的用户（例如，座席 `Jane`）在应用内拨打某个电话号码，请点击`Outbound Call`按钮。该操作将生成如下所示的 NCCO：

```json
[
    {
        "action": "talk",
        "text": "Please wait while we connect you."
    },
    {
        "action": "connect",
        "timeout": 20,
        "from": "YOUR_NEXMO_NUMBER",
        "endpoint": [
            {
                "type": "phone",
                "number": "PARAMS_TO"
            }
        ]
    }
]
```

> **注意：** `PARAMS_TO` 将在运行时被替换为应用用户拨入时使用的电话号码。应用将此号码传递给 SDK，SDK 将此号码作为 `answer_url` 请求参数中的参数传递。演示后端应用程序接收该参数，并代表您在此 NCCO 中将其替换为 `PARAMS_TO`。要详细了解如何通过 `answer_url` 传递参数，请参阅[此主题](/voice/voice-api/webhook-reference#answer-webhook-data-field-examples)。

试试看！如果您已经登录，请在客户端应用中点击“呼叫”按钮。系统将在应用内向您在 NCCO 中配置的电话号码拨打电话。

### 创建交互式语音响应 (IVR)

IVR 允许您根据用户的输入定向呼叫。例如，如果主叫方按数字 `1`，则将呼叫定向到座席 `Jane`。如果主叫方按 `2`，则将呼叫定向到座席 `Joe`。

要实现此操作，请点击 `IVR` 按钮，生成如下所示的 NCCO：

```json
[
    {
        "action": "talk",
        "text": "Thank you for calling my contact center."
    },
    {
        "action": "talk",
        "text": "To talk to Jane, please press 1, or, to talk to Joe, press 2."
    },
    {
        "action": "input",
        "eventUrl": ["DTMF_URL"]
    }
]
```

在该 NCCO 中，`input` 操作收集用户按下的数字，并将其发送到指示的 `eventUrl`。`eventUrl` 是系统执行的另一个 NCCO，用于根据用户输入继续处理呼叫。在本案例中，`DTMF_URL` 是后端演示应用程序代表您实现并公开的一个端点，用于将呼叫连接到相应座席。

在本示例中，NCCO 仅将主叫方连接到相应座席。`DTMF_URL` 与您之前看到的非常相似：

```json
[
    {
        "action": "talk",
        "text": "Please wait while we connect you to Jane"
    },
    {
        "action": "connect",
        "endpoint": [
            {
                "type": "app",
                "user": "Jane"
            }
        ]
    }
]
```

用于连接到 `Joe` 的 NCCO 非常类似，只有用户名不同。

1. 在两个模拟器、设备或浏览器选项卡上运行客户端应用的两个不同实例。
2. 在一个实例中以 `Jane` 的身份登录，在另一个实例中以 `Joe` 的身份登录。
3. 在另一部电话上，拨打分配给 Vonage 应用程序的 Vonage 号码。
4. 在电话上，按下要连接的座席的数字。
5. 在客户端应用上接听您要求连接的座席的电话。

自定义 NCCO
--------

您可以点击`Custom`按钮，探索更多 [NCCO 功能](/voice/voice-api/ncco-reference)，并更新上面使用的示例 NCCO。

摘要
---

恭喜您！您现在已经拥有一个正在运行的联络中心应用程序！

您已经：

* 使用了支持用户管理、授权、Webhook 等功能的后端应用程序。
* 使用了通过 NexmoClient SDK 拨打和接听应用内电话的客户端应用程序。
* 通过更新 Vonage 应用程序 `answer_url` 返回的 NCCO 启用了语音功能。

接下来做什么？
-------

* [详细了解不同 Vonage 组件之间的事件流](/conversation/guides/event-flow)。
* [详细了解设置对话 API 和 Client SDK 应用程序时需要的组件](/conversation/guides/application-setup)。
* [向移动应用添加推送通知](/client-sdk/setup/set-up-push-notifications)。

参考
---

* 探索 [Client SDK](/client-sdk/overview)
* 探索[语音 API](/voice/voice-api/overview)
* 探索[对话 API](/conversation/overview)

