---
title:  使用消息 API 将实时数据馈入多个渠道

products: messages

description:  本教程描述了一个用例，在该用例中，用户将实时数据接收到自己的渠道中。支持的渠道包括 Facebook Messenger、WhatsApp、Viber 和短信。

languages:
  - Python


---

使用消息 API 将实时数据馈入多个渠道
====================

本教程介绍如何使用消息 API 将数据实时馈入多个渠道。本教程演示如何将数据发送到所有受支持的渠道，并提供有关如何测试所有渠道的信息。如果您有兴趣使用 Facebook Messenger 进行测试，建议您首先完成[此教程](/tutorials/fbm-product-info)，因为此教程包含许多 Facebook 特定信息。要测试 WhatsApp 和 Viber，您需要在这些提供商处开设企业帐户。

示例场景
----

在本教程中，您将通过用户选择的渠道向他们发送实时股票报价。用户可以在他们选择的任何受支持渠道上注册，以接收数据。例如，他们可以通过手机短信或 Facebook Messenger 接收股票报价。WhatsApp 和 Viber 也受支持。对于 Facebook Messenger、WhatsApp 和短信，用户可以登记他们对某只股票感兴趣。但是，Viber 不支持向企业发送入站消息，因此用户要想接收数据，就必须通过网站注册来接收消息。此外，对于 WhatsApp，还有一种复杂情况，即 WhatsApp 要求企业向用户发送 [MTM](/messages/code-snippets/send-whatsapp-template)，用户才能同意接收消息。

> 请注意，本教程仅使用模拟的股票价格。

源代码
---

此项目的 Python 源代码可在 Vonage 社区 [GitHub 存储库](https://github.com/nexmo-community/messages-api-real-time-feed)中找到。特别值得关注的是通用客户端，它提供了一种便捷的方式，可以通过单个方法调用向任何受支持的渠道发送消息。您还将看到 Python 代码处理 WhatsApp、短信和 Messenger 上的入站消息。

先决条件
----

1. [创建 Vonage 帐户](https://dashboard.nexmo.com/sign-in)
2. [安装 Node JS](https://nodejs.org/en/download/) - 使用 Nexmo 命令行界面 (CLI) 的必备条件。
3. [安装 Nexmo CLI 测试版](/messages/code-snippets/install-cli)
4. [知道如何在本地测试 Webhook 服务器](/messages/code-snippets/configure-webhooks#testing-locally-via-ngrok)
5. [已安装 Python 3](https://www.python.org/)
6. [已安装 Flask](http://flask.pocoo.org/)
7. 具有要支持的渠道（例如 Facebook、Viber 和 WhatsApp）的帐户。

您可能还会发现，查看以下概述主题很有用：

* [Facebook Messenger](/messages/concepts/facebook)
* [Viber](/messages/concepts/viber)
* [WhatsApp](/messages/concepts/whatsapp)

如果您计划使用 Facebook Messenger 测试本用例，建议您先完成[此教程](/tutorials/fbm-product-info)。

步骤
---

满足先决条件后，步骤如下：

1. [创建 Vonage 应用程序](#create-your-nexmo-application)
2. [启动并运行 Ngrok](#get-ngrok-up-and-running)
3. [在 Dashboard 中设置短信 Webhook](#set-your-sms-webhooks-in-dashboard)
4. [编写基本应用程序](#write-your-basic-application)
5. [发送短信](#send-in-an-sms)
6. [查看通用客户端代码](#generic-client)
7. [重新审视用例](#the-use-case-revisited)
8. [测试应用](#testing-the-app)

您可以使用 Vonage 通过多种方式获得相同的结果。本教程只展示了一种特定的处理方式，例如，您将看到如何使用命令行而不是 Dashboard 来创建应用程序。其他教程演示了其他处理方式。

创建 Vonage 应用程序
--------------

如果还没有为项目创建新目录，请创建一个，例如 `real-time-app`。切换到该目录。

使用 CLI 创建 Vonage 应用程序：

```shell
nexmo app:create "Real-time App" https://abcd1234.ngrok.io/webhooks/inbound https://abcd1234.ngrok.io/webhooks/status --keyfile=private.key --type=messages
```

记下生成的应用程序 ID。您也可以在 [Dashboard](https://dashboard.nexmo.com/messages/applications) 中查看此信息。

此命令还将在当前目录中创建私钥 `private.key`。

此命令还会设置两个需要设置的 Webhook。您的应用和 Vonage 之间的所有交互都将通过这些 Webhooks 进行。您至少必须在应用中确认所有这些 WebHook。

启动并运行 Ngrok
-----------

确保正在本地运行 Ngrok，以进行测试。要启动 Ngrok，请键入：

```shell
ngrok http 9000
```

生成一个临时的 Ngrok URL。如果您是付费订阅者，则可以键入：

```shell
ngrok http 9000 -subdomain=your_domain
```

> 注意：在本案例中，Ngrok 会将您在创建 Vonage 应用程序时指定的 Vonage Webhook 转移到 `localhost:9000`。

在 Dashboard 中设置短信 Webhook
-------------------------

在 Dashboard 中，转到[帐户设置](https://dashboard.nexmo.com/settings)。在这里，您可以设置帐户级别的短信 Webhook：

| Webhook |                                                      URL                                                       |
|---------|----------------------------------------------------------------------------------------------------------------|
| 传递回执    | [https://abcd1234\.ngrok.io/webhooks/delivery-receipt](https://abcd1234.ngrok.io/webhooks/delivery-receipt) |
| 入站短信    | [https://abcd1234\.ngrok.io/webhooks/inbound-sms](https://abcd1234.ngrok.io/webhooks/inbound-sms)           |

请注意，您需要将 Webhook URL 中的“abcd1234”替换为您自己的信息。如果您有 Ngrok 付费帐户，则可以替换为您的自定义域。

> **注意：** 您需要执行此步骤，因为消息和调度应用程序当前仅支持出站短信，不支持入站短信。因此，您将使用帐户级别的短信 Webhook 来支持入站短信，但使用消息 API 发送出站短信。

编写基本应用程序
--------

在这个最简单的案例中，您的应用程序将记录入站消息信息以及传递回执和消息状态数据。其代码如下所示：

```python
from flask import Flask, request, jsonify
from pprint import pprint

app = Flask(__name__)

@app.route('/webhooks/inbound', methods=['POST'])
def inbound_message():
    print ("** inbound_message **")
    data = request.get_json()
    pprint(data)
    return ("inbound_message", 200)

@app.route('/webhooks/status', methods=['POST'])
def message_status():
    print ("** message_status **")
    data = request.get_json()
    pprint(data)
    return ("message_status", 200)

@app.route('/webhooks/inbound-sms', methods=['POST'])
def inbound_sms():
    print ("** inbound_sms **")
    values = request.values
    pprint(values)
    return ("inbound_sms", 200)

@app.route('/webhooks/delivery-receipt', methods=['POST'])
def delivery_receipt():
    print ("** delivery_receipt **")
    data = request.get_json()
    pprint(data)
    return ("delivery_receipt", 200)

if __name__ == '__main__':
    app.run(host="localhost", port=9000)
```

将此代码添加到名为 `app1.py` 的文件中并保存。

使用以下命令在本地运行该文件：

```shell
python3 app1.py
```

发送短信
----

现在，基本应用程序已启动并正在运行，并且可以开始记录事件。您可以通过向链接到任何语音应用的任何 Vonage 号码（Vonage 号码具有语音和短信功能）发送短信，来测试这个基本应用程序。如果您没有语音应用程序，并且不确定如何创建语音应用程序，则可以查看[此信息](/application/code-snippets/create-application)。之所以需要执行这个附加步骤，是因为消息和调度 API 当前不支持入站短信，仅支持出站短信，因此您必须使用帐户级别的 Webhook 来接收入站短信通知。

当您检查发送短信时生成的跟踪信息时，您会看到与下面类似的内容：

    ** inbound_sms **
    {'keyword': 'MESSAGE',
     'message-timestamp': '2019-04-16 13:55:21',
     'messageId': '1700000240EAA6B6',
     'msisdn': '447700000001',
     'text': 'Message from Tony',
     'to': '447520635498',
     'type': 'text'}

通用客户端
-----

目前，Vonage 尚未正式支持 Python Server SDK 中的消息和调度 API，但我们的 REST API 受到支持（测试版），并且项目中的 [Python 代码](https://github.com/nexmo-community/messages-api-real-time-feed/blob/master/Client/Client.py)将在可重用类中提供给您。此类允许使用消息 API 向其支持的任何渠道发送消息。以下代码很值得一看：

```python
    def send_message (self, channel_type, sender, recipient, msg):
        if channel_type == 'messenger':
            from_field = "id"
            to_field = "id"
        elif channel_type == 'whatsapp' or channel_type == "sms": 
            from_field = "number"
            to_field = "number"
        elif channel_type == 'viber_service_msg':
            from_field = "id"
            to_field = "number"
               
        data_body = json.dumps({
            "from": {
	        "type": channel_type,
	        from_field: sender
            },
            "to": {
	        "type": channel_type,
	        to_field: recipient
            },
            "message": {
	        "content": {
	            "type": "text",
	            "text": msg
	        }
            }
        })
...
```

这里的代码正文是根据渠道类型为您构建的。这是因为渠道之间的细节略有不同 - 例如，Facebook 使用 ID，而 WhatsApp 和短信仅使用号码。Viber 使用 ID 和号码。然后，代码继续使用消息 API 为您发送消息。这是本用例的基础，还有一些额外的位可用于用户注册。

重新审视用例
------

现在是时候更详细地研究这个用例了，这样您就可以更有效地构建应用程序。

对于支持入站消息的渠道（Messenger、WhatsApp 和短信），您可以允许用户通过发送消息进行注册。对于 Viber，这必须通过 Web 应用的另一部分来完成。通常，您会提供一个表单，用户可以在其中注册实时源。

如果用户发送入站消息（例如“您好”），应用将以帮助消息进行响应。在我们的简单案例中，该帮助消息为“向我们发送包含 MSFT 或 GOOGL 的消息，以获取实时数据”。然后，将通过另一条确认已订阅的源的消息来确认此注册。

此后，您将收到所选股票代码的实时价格。您可以根据需要另外注册其他渠道。同样，如果您想更改股票代码，只需发送包含新代码的消息，该消息就会被确认，并且数据流也会相应更改。

实现此目标的核心代码位于 `app_funcs.py` 的函数 `proc_inbound_msg` 中。

对于 WhatsApp，您还有一个附加步骤，即，需要向用户发送 [MTM 消息](/messages/code-snippets/send-whatsapp-template)，用户才能注册接收数据。为简单起见，此步骤作为[单独的代码段](https://github.com/nexmo-community/messages-api-real-time-feed/blob/master/send_whatsapp_mtm.py)提供。

测试应用
----

可以使用以下命令运行应用：

```shell
python3 app.py APP_ID
```

其中，`APP_ID` 是您的消息应用程序的 Vonage 应用程序 ID。

### 短信

要使用短信进行测试，只需像之前那样发送短信即可。您将收到一条帮助消息。发回包含股票代码 `MSFT` 或 `GOOGL` 的消息。然后，您将定期收到（模拟的）价格更新。目前，必须退出应用才能停止接收这些消息，但是如[此教程](/tutorials/fbm-product-info)中所述，添加关闭这些消息的功能是一件很简单的事。

### Facebook Messenger

要使用 Facebook Messenger 进行测试，还需执行一些附加步骤。[此教程](/tutorials/fbm-product-info)已经详细介绍了这些步骤，因此这里不再赘述。

### Viber

要有有效的 Viber 企业帐户才能进行测试。您可以使用 Web 应用的一部分来请求用户[提供电话号码以及他们感兴趣的代码](https://github.com/nexmo-community/messages-api-real-time-feed/blob/master/app_funcs.py#L21-L29)。然后可以向用户发送一条他们能够接收或拒绝的初始消息。此处提供了一个[小型测试程序](https://github.com/nexmo-community/messages-api-real-time-feed/blob/master/test-viber.py)，可演示如何使用 Viber 测试通用客户端。

### WhatsApp

WhatsApp 需要执行额外的步骤才能进行全面测试。您需要向用户发送 WhatsApp MTM（模板），他们才能接收任何消息。本教程没有介绍执行此操作的代码，但[此处](https://github.com/nexmo-community/messages-api-real-time-feed/blob/master/send_whatsapp_mtm.py)提供了示例代码。然后，您可以使用本教程提供的通用客户端发送后续的 WhatsApp 消息。

摘要
---

在本教程中，您看到了一个用例，在该用例中，用户可以在消息 API 支持的任何渠道上接收实时数据。

更多资源
----

* [完整源代码](https://github.com/nexmo-community/messages-api-real-time-feed)。
* [消息 API 文档](/messages/overview)
* [发送 WhatsApp MTM](/messages/code-snippets/send-whatsapp-template)

