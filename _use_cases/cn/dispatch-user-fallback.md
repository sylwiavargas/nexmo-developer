---
title:  使用调度 API 的多用户、多渠道故障转移

products: dispatch

description:  本教程描述了一个用例，在该用例中，应用程序尝试通过用户指定的渠道向其发送消息。如果用户未阅读该消息，则对列表中的下一个用户重复此过程。该用例使用调度 API，因为每个用户有多个指定渠道，并有故障转移。

languages:
  - Python


---

使用调度 API 的多用户、多渠道故障转移
=====================

本教程介绍如何通过自动故障转移将消息发送到用户列表。

本教程假设您有一个用户列表，每个用户都有两个或更多指定渠道，其中最后一个是最终备用渠道。应用程序尝试通过用户指定的渠道向用户优先级列表中的第一个用户发送消息。在适当的故障转移条件下依次处理每个渠道。

如果让某个用户阅读消息的所有尝试均失败，则处理进程将前进至优先级列表中的下一个用户。

举例来说，假设您的主服务器出现故障，您希望通知列表上随时待命的系统管理员。每个管理员可能有几个可联络渠道。应用程序将处理用户列表，直到至少一位管理员阅读了这条重要消息。

示例场景
----

理解本用例的最佳方法可能是查看示例配置文件 `sample.json`：

```json
{
    "APP": {
        "APP_ID": "abcd1234-8238-42d0-a03a-abcd1234...",
        "PRIVATE_KEY": "private.key"
    },
    "FROM": {
        "MESSENGER": "COMPANY MESSENGER ID",
        "VIBER": "COMPANY VIBER ID",
        "WHATSAPP": "COMPANY WHATSAPP NUMBER",
        "SMS": "COMPANY SMS NAME/NUMBER"
    },
    "USERS": [
        {
            "name": "Tony",
            "channels": [
                {
                    "type": "messenger",
                    "id_num": "USER MESSENGER ID"
                },
                {
                    "type": "sms",
                    "id_num": "USER PHONE NUMBER"
                }
            ]
        },
        {
            "name": "Michael",
            "channels": [
                {
                    "type": "viber_service_msg",
                    "id_num": "USER PHONE NUMBER"
                },
                {
                    "type": "whatsapp",
                    "id_num": "USER PHONE NUMBER"
                },
                {
                    "type": "sms",
                    "id_num": "USER PHONE NUMBER"
                }
            ]
        }
    ]
}
```

此配置文件中最重要的部分是 `USERS` 节。在该节中，您有一个用户优先级列表。在本案例中，应用程序将尝试向 Tony 发送消息，如果 Tony 未能在有效期内通过任何指定渠道阅读消息，则对 Michael 重复此过程。

> **注意：** 每个渠道为 `read` 状态且有效期为 `600` 的故障转移条件目前已被硬编码到应用程序中，但可以将其轻松地添加到配置文件中（有关如何执行此操作的代码，请参阅 [case-3](https://github.com/nexmo-community/dispatch-user-fallback/tree/master/case-3)）。

请注意，必须符合以下条件：

* 用户必须至少有两个渠道。
* 用户可以混用任意数量的渠道和类型，只要渠道数量不少于两个即可。例如，一个用户可以有 3 个短信号码和 1 个 Messenger ID。
* 为用户指定的最后一个渠道将作为最终备用渠道。它的处理方式略有不同，因为它在工作流模型中没有关联的故障转移条件。如果该渠道失败，则处理列表中的下一个用户。
* 最终备用渠道不一定是短信，尽管这是典型配置。
* 工作流是以每个用户为基础创建的，但您可以为每个用户指定唯一的工作流。
* 尝试按照用户在配置文件中的列出顺序，向每个用户应用工作流。
* 从一个渠道到下一个渠道的故障转移自动进行，并由调度 API 透明处理。

源代码
---

此项目的 Python 源代码可在社区 [GitHub 存储库](https://github.com/nexmo-community/dispatch-user-fallback)中找到。实际上，代码库包含三个用例，但本教程只介绍了 `case-2`。`case-2` 的具体代码可以在[此处](https://github.com/nexmo-community/dispatch-user-fallback/tree/master/case-2)找到。其中只有两个文件 - 示例配置文件 `sample.json` 和应用程序 `app.py`。

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

* [调度 API](/dispatch/overview)
* [Facebook Messenger](/messages/concepts/facebook)
* [Viber](/messages/concepts/viber)
* [WhatsApp](/messages/concepts/whatsapp)

如果您计划使用 Facebook Messenger 测试本用例，建议您先完成[此教程](/tutorials/fbm-product-info)。

步骤
---

满足先决条件后，步骤如下：

1. [创建 Vonage 应用程序](#create-your-nexmo-application)
2. [启动并运行 Ngrok](#get-ngrok-up-and-running)
3. [运行 Webhook 服务器](#run-your-webhook-server)
4. [查看应用程序代码](#review-the-application-code)
5. [测试应用](#test-the-app)

您可以使用 Vonage 通过多种方式获得相同的结果。本教程只展示了一种特定的处理方式，例如，您将看到如何使用命令行而不是 Dashboard 来创建应用程序。其他教程演示了其他处理方式。

创建 Vonage 应用程序
--------------

如果还没有为项目创建新目录，请创建一个，例如 `multi-user-dispatch`。切换到该目录。

使用 CLI 创建 Vonage 应用程序：

```shell
nexmo app:create "Multi-user Dispatch App" https://abcd1234.ngrok.io/webhooks/inbound https://abcd1234.ngrok.io/webhooks/status --keyfile=private.key --type=messages
```

记下生成的应用程序 ID。您也可以在 [Dashboard](https://dashboard.nexmo.com/messages/applications) 中查看此信息。

此命令还将在当前目录中创建私钥 `private.key`。

此命令还会设置两个需要设置的 Webhook。您的应用和 Vonage 之间的所有交互都将通过这些 Webhooks 进行。您至少必须在 Webhook 服务器中确认所有这些 WebHook。

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

> **注意：** 在本案例中，Ngrok 会将您在创建 Vonage 应用程序时指定的 Vonage Webhook 转移到 `localhost:9000`。

运行 Webhook 服务器
--------------

您需要启动并运行 Webhook 服务器，以便确认 Webhook，并记录已发送消息的详细信息。您的 Webhook 服务器将类似于以下内容：

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

if __name__ == '__main__':
    app.run(host="localhost", port=9000)
```

将此代码添加到名为 `server.py` 的文件中并保存。

使用以下命令在本地运行该文件：

```shell
python3 server.py
```

查看应用程序代码
--------

为方便起见，代码包含在单个文件 `app.py` 中。只有这个文件和 JSON 配置文件 `config.json` 最初可通过复制 `sample.json` 进行创建。

最重要的是，配置文件中存储了用户列表以按优先级顺序联系，并存储了他们的指定渠道。在此实现中，每个用户必须有至少有两个渠道，但每个用户可以任意组合任何方便的渠道。例如，一个用户可能有三个短信号码，另一用户可能有 Messenger ID、Viber 外加两个短信号码。

为每个用户列出的最后一个渠道被视为切换到另一个用户之前的最终备用渠道。对于每个用户，将使用调度 API 向每个渠道发送一条消息，如果在 600 秒内未阅读该消息，则会 **自动** 故障转移到下一个渠道。

应用程序代码的第一部分 `app.py` 仅读取配置文件并加载重要的变量和数据结构。假定您的公司将支持调度 API 支持的所有四个渠道（`messenger`、`viber_service_msg`、`whatsapp` 和 `sms`），但只能为目标用户分配他们的首选渠道。例如，某些用户可能只能通过短信进行联系。

辅助函数 `set_field_types` 可管理以下情况：一些渠道使用 `numbers`，一些渠道使用 `ids`，而 Viber 同时使用 `ids` 和 `numbers`。

本用例的主要功能在 `build_user_workflow` 函数中。此代码将构建如下所示的工作流：

```json
{
    "template": "failover",
    "workflow": [
        {
            "from": {
                "type": "messenger",
                "id": "from_messenger"
            },
            "to": {
                "type": "messenger",
                "id": "user_id_num"
            },
            "message": {
                "content": {
                    "type": "text",
                    "text": "This is a Facebook Messenger message sent using the Dispatch API"
                }
            },
            "failover": {
                "expiry_time": "600",
                "condition_status": "read"
            }
        },
        {
            "from": {
                "type": "viber_service_msg",
                "id": "from_viber"
            },
            "to": {
                "type": "viber_service_msg",
                "number": "user_id_num"
            },
            "message": {
                "content": {
                    "type": "text",
                    "text": "This is a Viber Service Message sent using the Dispatch API"
                }
            },
            "failover": {
                "expiry_time": "600",
                "condition_status": "read"
            }
        },
        {
            "from": {
                "type": "sms",
                "number": "from_sms"
            },
            "to": {
                "type": "sms",
                "number": "user_id_num"
            },
            "message": {
                "content": {
                    "type": "text",
                    "text": "This is an SMS sent using the Dispatch API"
                }
            }
        }
    ]
}
```

函数 `build_user_workflow` 还可确保从配置文件读取的值嵌入到工作流中。

您可能已经注意到，`expiry_time` 和 `condition_status` 被硬编码到 `build_user_workflow` 内置的工作流中。这是为了使代码尽可能简单，但您可以基于每个渠道将这些参数添加到配置文件中。在本案例中，对于某些渠道，某些用户可能有 300 秒的有效期，并且您还可以基于每个渠道指定故障转移条件 `read` 或 `delivered`。[case-3](https://github.com/nexmo-community/dispatch-user-fallback/tree/master/case-3) 已为您实现此功能，但本教程未做进一步介绍，因为所有代码和修改后的示例配置文件都已给出。

构建工作流后，使用[调度 API](/dispatch/overview) 发送消息：

```python
r = requests.post('https://api.nexmo.com/v0.1/dispatch', headers=headers, data=workflow)
```

系统将生成 JWT，以便对 API 调用进行身份验证。这就是为什么在创建 Vonage 应用程序时需要记下 `app_id` 和 `private_key` 值的原因。这些值需要添加到配置文件中。

测试应用
----

将 `sample.json` 复制到 `config.json`。

确保在 `config.json` 中为 `app_id`、`private_key` 等参数设置了适当的值，并为各种支持的渠道设置了详细信息。确保根据所需测试方式配置了用户列表。

> **提示：** 此时值得使用 [JSON linter](https://jsonlint.com/) 验证修改后的配置文件。

然后，可以使用以下命令运行应用：

```shell
python3 app.py
```

应用程序将处理配置文件并依次联系每个用户，直到消息已读。

### 短信

您可以使用任何可以接收短信的手机来测试本教程。

### Facebook Messenger

要使用 Facebook Messenger 进行测试，还需执行一些附加步骤。[此教程](/tutorials/fbm-product-info)已经详细介绍了这些步骤，因此这里不再赘述。

### Viber

要有 Viber 服务消息 ID 才能使用 Viber 测试本教程。

### WhatsApp

要有 WhatsApp 企业帐户才能使用 WhatsApp 测试本教程。此外，必须向目标用户发送 MTM，他们才能接收贵公司的消息。

摘要
---

在本教程中，您看到了一个用例，在该用例中，您可以尝试将消息发送到用户列表，其中每个用户都有多个渠道。消息已读后，应用程序终止。

更多资源
----

* [完整源代码](https://github.com/nexmo-community/dispatch-user-fallback)。
* [调度 API 文档](/dispatch/overview)
* [发送 WhatsApp MTM](/messages/code-snippets/send-whatsapp-template)

