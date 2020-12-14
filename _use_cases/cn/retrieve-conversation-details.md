---
title:  检索正在进行的语音通话的对话详细信息

products: conversation

description:  “检索正在进行的语音通话的对话对象的详细信息”

languages:
  - Curl
  - Python


---

检索对话详细信息
========

您可以使用对话 API 检索语音通话的对话对象的详细信息。

尽管本教程专门探讨如何检索语音通话的详细信息，但还有许多其他功能可能的用例，例如视频通话或文本聊天会话。本教程的目的是深入了解对话结构，因为对话是许多 Vonage 技术所基于的重要对象。它是通信活动的基本数据结构，因为所有通信都是通过对话进行的。

本教程中的设置如下图所示：

![对话](/images/conversation-api/call-forward-conversation.png)

教程内容
----

* [先决条件](#prerequisites)
* [创建 Vonage 应用程序](#create-a-nexmo-application)
* [创建 JWT](#create-a-jwt)
* [运行 Webhook 服务器](#run-your-webhook-server)
* [拨打 Vonage 号码](#call-your-nexmo-number)
* [获取对话详细信息](#get-the-conversation-details)
* [结语](#conclusion)
* [资源](#resources)

先决条件
----

1. [创建 Vonage 帐户](/account/guides/management#create-and-configure-a-nexmo-account) - 没有帐户，您可执行的操作有限。
2. [租用 Vonage 号码](/account/guides/numbers#rent-virtual-numbers) - 您应该有几欧元的免费信用额度。这已经足够了。
3. [安装 Nexmo 命令行工具](/tools) - 您需要安装 [Node](https://nodejs.org)，但使用 Nexmo CLI 既快捷又方便。
4. 您应该已安装 [Python 3](https://realpython.com/installing-python/) 和 [Flask](http://flask.pocoo.org/)。这些是 Webhook 服务器的必备条件。

本教程假定您将运行 [Ngrok](https://ngrok.com)，以便在本地运行 [Webhook](/concepts/guides/webhooks) 服务器。

如果您不熟悉 Ngrok，请在继续操作前参考我们的 [Ngrok 教程](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)。

在本教程中，您还需要使用两部电话！

所以，如果您准备继续...

创建 Vonage 应用程序
--------------

如果您还没有创建 Vonage 应用程序，则需要先创建一个：

```bash
nexmo app:create "Conversation App" http://demo.ngrok.io/webhooks/answer http://demo.ngrok.io/webhooks/event --keyfile private.key
```

在上面这个命令中，您需要将 `demo` 替换为适用于您的设置的内容。

记下生成的应用程序 ID (`APP_ID`)，生成 JWT 时需要此 ID。

将 Vonage 号码链接到应用程序
------------------

假设您已经租用了一个 Vonage 号码 (`VONAGE_NUMBER`)，您可以在 Dashboard 中或通过命令行将 Vonage 号码与应用程序链接起来：

```bash
nexmo link:app VONAGE_NUMBER APP_ID
```

创建 JWT
------

对话 API 使用 JWT 进行身份验证。您可以使用以下命令生成 JWT：

```bash
JWT="$(nexmo jwt:generate private.key exp=$(($(date +%s)+86400)) application_id=APP_ID)"
```

您需要将 `APP_ID` 替换为您的应用程序的 ID。另外，`private.key` 是与此相同应用程序关联的密钥。

> **注意：** 此 JWT 的有效期为一天。

然后，您可以使用以下命令查看 JWT：

```bash
echo $JWT
```

> **提示：** 您可以在 [jwt.io](https://jwt.io) 上验证您的 JWT。

运行 Webhook 服务器
--------------

您需要运行 Webhook 服务器，以帮助获取正在进行的通话的对话 ID。下面的 Python 代码就足够了：

```python
from flask import Flask, request, jsonify
from pprint import pprint

app = Flask(__name__)

ncco = [{
        "action": "connect",
        "endpoint": [{
            "type": 'phone',
            "number": 'TO_NUMBER'
        }]
}]

@app.route("/webhooks/answer")
def answer_call():
    params = request.args
    pprint(params)
    return jsonify(ncco)

if __name__ == '__main__':
    app.run(port=3000)
```

> **重要说明：** 您需要将 `TO_NUMBER` 替换为第二部电话（电话 2 (Bob)）的号码。

使用以下命令在本地运行此 Webhook 服务器：

```bash
python3 app.py
```

拨打 Vonage 号码
------------

用电话 1 (Alice) 拨打 Vonage 号码。呼入电话转接到第二部电话，即电话 2 (Bob)。在电话 2 (Bob) 上接听电话。此时不要取消通话。

现在检查 Webhook 服务器生成的日志记录。您应该看到与下面类似的内容：

    ...
    {
       'conversation_uuid': 'CON-bc643220-2542-499a-892e-c982c4150c06',
       'from': '447700000001',
       'to': '447700000002',
       'uuid': '797168e24c19a3c45e74e05b10fef2b5'
    }
    ...

您仅对格式为 `CON-<uuid>` 的对话 ID 感兴趣。将该 ID 复制并粘贴到方便的地方。

获取对话详细信息
--------

通过在另一个终端选项卡中运行以下命令，可以检索当前通话的对话对象的详细信息。

> **注意：** 您需要确保将 `$CONVERSATION_ID` 替换为先前获取的 ID，将 `$JWT` 替换为先前创建的 JWT。

通过以下方式获取语音通话的对话详细信息：

```code_snippets
source: '_examples/conversation/conversation/get-conversation'
```

此 API 调用将为您提供类似于以下内容的响应：

```json
{
    "uuid": "CON-bc643220-2542-499a-892e-c982c4150c06",
    "name": "NAM-1b2c4274-e3f2-494e-89c4-46856ee84a8b",
    "timestamp": {
        "created": "2018-10-25T09:26:18.999Z"
    },
    "sequence_number": 8,
    "numbers": {},
    "properties": {
        "ttl": 172800,
        "video": false
    },
    "members": [
        {
            "member_id": "MEM-f44c872e-cba9-444f-88ae-0bfa630865a6",
            "user_id": "USR-33a51f4d-d06b-42f6-a525-90d2859ab9f6",
            "name": "USR-33a51f4d-d06b-42f6-a525-90d2859ab9f6",
            "state": "JOINED",
            "timestamp": {
                "joined": "2018-10-25T09:26:30.334Z"
            },
            "channel": {
                "type": "phone",
                "id": "797168e24c19a3c45e74e05b10fef2b5",
                "from": {
                    "type": "phone",
                    "number": "447700000001"
                },
                "to": {
                    "type": "phone",
                    "number": "447700000002"
                },
                "leg_ids": [
                    "797168e24c19a3c45e74e05b10fef2b5"
                ]
            },
            "initiator": {
                "joined": {
                    "isSystem": true
                }
            }
        },
        {
            "member_id": "MEM-25ccda92-839d-4ac6-a7b2-de310224878b",
            "user_id": "USR-b9948493-be4a-4b36-bb4d-c96bcc2af85b",
            "name": "vapi-user-f59c1ff26c0543fdb6c02fd30617a1c0",
            "state": "JOINED",
            "timestamp": {
                "invited": "2018-10-25T09:26:19.385Z",
                "joined": "2018-10-25T09:26:30.270Z"
            },
            "invited_by": "USR-b9948493-be4a-4b36-bb4d-c96bcc2af85b",
            "channel": {
                "type": "phone",
                "id": "30cecc87-7ac9-4d03-910a-e9d69558263c",
                "from": {
                    "number": "Unknown",
                    "type": "phone"
                },
                "leg_ids": [
                    "30cecc87-7ac9-4d03-910a-e9d69558263c"
                ],
                "to": {
                    "number": "447700000001",
                    "type": "phone"
                },
                "cpa": false,
                "preanswer": false,
                "ring_timeout": 60000,
                "cpa_time": 5000,
                "max_length": 7200000
            },
            "initiator": {
                "invited": {
                    "isSystem": true
                }
            }
        }
    ],
    "_links": {
        "self": {
            "href": "https://api.nexmo.com/beta/conversations/CON-bc643220-2542-499a-892e-c982c4150c06"
        }
    }
}
```

[对话](/conversation/concepts/conversation)主题对此响应进行了更详细的解释。

现在，您可以挂断电话 1 (Alice) 和电话 2 (Bob) 以终止通话。

结语
---

您已经了解如何使用对话 API 来获取语音通话的对话对象。

资源
---

* [对话 API 文档](/conversation/overview)
* [对话 API 参考](/api/conversation/)

