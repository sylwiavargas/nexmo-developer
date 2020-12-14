---
title:  通过 Facebook Messenger 自动接收产品信息

products: messages

description:  本教程探讨了一个用例，在该用例中，用户无需支持人员即可通过 Facebook Messenger 自动接收相关产品信息。

languages:
  - Python


---

通过 Facebook Messenger 自动接收产品信息
==============================

本教程介绍如何通过 Facebook Messenger 自动向用户提供相关产品信息。

在本用例中，用户通过公司的 Facebook 页面问候公司。系统自动给用户回复一条消息。使用关键字匹配，用户可以收到量身定制的产品和服务信息。

> **注意：** 本教程假定您已经创建 Facebook 个人资料和 Facebook 页面。

源代码
---

此项目的源代码可在社区 [GitHub 存储库](https://github.com/nexmo-community/fbm-product-info)中找到。

先决条件
----

1. [创建 Vonage 帐户](https://dashboard.nexmo.com/sign-in)
2. [安装 Node JS](https://nodejs.org/en/download/) - 使用 Nexmo 命令行界面 (CLI) 的必备条件。
3. [安装 Nexmo CLI 测试版](/messages/code-snippets/install-cli)
4. [知道如何在本地测试 Webhook 服务器](/messages/code-snippets/configure-webhooks#testing-locally-via-ngrok)
5. [已安装 Python 3](https://www.python.org/)
6. [已安装 Flask](http://flask.pocoo.org/)

步骤
---

满足先决条件后，步骤如下：

1. [创建 Vonage 应用程序](#create-your-nexmo-application)
2. [将 Vonage 应用程序链接到 Facebook 页面](#link-your-application-to-your-facebook-page)
3. [启动并运行 Ngrok](#get-ngrok-up-and-running)
4. [编写基本应用程序](#write-your-basic-application)
5. [与 Facebook 页面交互](#interact-with-your-facebook-page)
6. [使用 Python 发送 Facebook Messenger 消息的最简客户端](#minimal-client-for-sending-facebook-messenger-messages-using-python)
7. [重新访问用例](#the-use-case-revisited)
8. [一个简单的实现](#a-simple-implementation)

您可以使用 Vonage 通过多种方式获得相同的结果。本教程只展示了一种特定的处理方式，例如，您将看到如何使用命令行而不是 Dashboard 来创建应用程序。其他教程演示了其他处理方式。

创建 Vonage 应用程序
--------------

如果还没有为项目创建新目录，请创建一个，例如 `fbm-app`。切换到该目录。

使用 CLI 创建 Vonage 应用程序：

```shell
nexmo app:create "FBM App" https://abcd1234.ngrok.io/inbound https://abcd1234.ngrok.io/status --keyfile=private.key --type=messages
```

记下生成的应用程序 ID。您也可以在 [Dashboard](https://dashboard.nexmo.com/messages/applications) 中查看此信息。

此命令还将在当前目录中创建私钥 `private.key`。

此命令还会设置两个需要设置的 Webhook。您的应用和 Vonage 之间的所有交互都将通过这些 Webhooks 进行。您至少必须在应用中确认所有这些 WebHook。

将应用程序链接到 Facebook 页面
--------------------

```partial
source: _partials/reusable/link-facebook-to-nexmo.md
```

启动并运行 Ngrok
-----------

确保正在本地运行 Ngrok，以进行测试。要启动 Ngrok，请键入：

```shell
ngrok http 9000
```

生成一个临时的 Ngrok URL。如果您是付费订户，则可以键入：

```shell
ngrok http 9000 -subdomain=your_domain
```

> 注意：在本案例中，Ngrok 会将您在创建 Vonage 应用程序时指定的 Vonage Webhook 转移到 `localhost:9000`。

编写基本应用程序
--------

在这个最简单的案例中，您的应用程序将如下所示：

```python
from flask import Flask, request, jsonify
from pprint import pprint

app = Flask(__name__)

@app.route('/inbound', methods=['POST'])
def inbound_message():
    data = request.get_json()
    pprint(data)
    return ("200")

@app.route('/status', methods=['POST'])
def message_status():
    data = request.get_json()
    pprint(data)
    return ("200")

if __name__ == '__main__':
    app.run(host="localhost", port=9000)
```

将此代码添加到名为 `app1.py` 的文件中并保存。

使用以下命令在本地运行该文件：

```shell
python3 app1.py
```

现在，基本应用程序已启动并正在运行，并且可以开始记录事件。

与 Facebook 页面交互
---------------

基本应用已启动并运行，现在，您可以向 Facebook 页面发送消息，然后检查是否记录了该消息。如果使用 Messenger 向 Facebook 页面发送基本消息，您将看到如下日志记录：

    {'direction': 'inbound',
     'from': {'id': '1234567890123456', 'type': 'messenger'},
     'message': {'content': {'text': 'Hello Mr. Cat', 'type': 'text'}},
     'message_uuid': 'da13a7b0-307c-4029-bbcd-ec2a391873de',
     'timestamp': '2019-04-09T12:26:47.242Z',
     'to': {'id': '543210987654321', 'type': 'messenger'}}
    127.0.0.1 - - [09/Apr/2019 13:26:58] "POST /inbound HTTP/1.1" 200 -

这里有一些重要信息，您可以利用这些信息来构建应用程序，使其更加有用。

|    字段     |               描述                |
|-----------|---------------------------------|
| `from`    | 向您的页面发送消息的用户的 Facebook ID。      |
| `to`      | 您页面的 Facebook ID（用户要将消息发送到的页面）。 |
| `message` | 要发送的消息。                         |

您可以看到，该消息是一个 JSON 对象。您可以从该对象中提取消息文本。

请注意，记录您页面的 Facebook ID（您可能不知道）和向您发送消息的用户的 Facebook ID 很有用。如果您的应用程序正在处理多个 Facebook 页面，Facebook ID 尤其有用。

使用 Python 发送 Facebook Messenger 消息的最简客户端
----------------------------------------

目前，Vonage 尚未正式支持 Python Server SDK 中的消息和调度 API，但我们的 REST API 得到了完全支持，并且项目中的 [Python 代码](https://github.com/nexmo-community/fbm-product-info/blob/master/FBMClient/FBMClient.py)将在可重用类中提供给您。由于已经提供了代码，本教程将不再赘述。

重新访问用例
------

现在是时候更详细地研究这个用例了，这样您就可以更有效地构建应用程序。

假设某位用户通过 Messenger 向您的 Facebook 页面发送消息，例如“您好”。但是，由于时区原因，您没有回复该消息 - 这可能会使该用户感到沮丧。但从另一方面来看，如果您可以自动回复有用的信息，那就太好了。例如，对于诸如“您好”之类的消息，您可以回复“欢迎来到 T's Cat Supplies。我们的主要产品类别包括：玩具、食品、药品、饰品。”

通过使用诸如 `if keyword in msg` 之类的 Python 构造，您可以检测关键字并根据关键字发送资料。例如，如果用户发送诸如“您好，我的水箱需要整理”之类的消息，您可能会检测到单词 `tank`，并发送有关水箱清洁服务的信息。或者，如果您收到诸如“您好，我想我需要一台起重机来吊管道”之类的消息，您可以发送有关起重机租赁服务的信息。如果未检测到关键字，回复用户一条通用消息来帮助他们确定方向是件很简单的事。

这个自动回复功能非常实用，因为有些公司有上百种产品和服务。

另一项实用功能是可以关闭自动回复，这可能是为了直接与人打交道。您可以内置命令（例如 `auto: off` 和 `auto: on`）来控制客户与您的 Facebook 页面的交互方式。

在以下章节中，您将看到如何实现本用例。

一个简单的实现
-------

用于实现本用例的有用数据结构之一是 Python 字典。您可以在这里看到一个示例：

```python
cats_dict = {
    'other': 'Our products: toys, food, meds, and bling',
    'toys': 'More info on cat toys here https://bit.ly/abc',
    'food': 'More info on cat food here https://bit.ly/def',
    'meds': 'More info on cat meds here https://bit.ly/ghi',
    'bling': 'More info on cat bling here https://bit.ly/jkl'
}
```

要全面了解这个示例，请查看以下代码：

```python
class ProductMatcher:

    auto_mode = True

    cats_dict = {
        'other': 'Our products: toys, food, meds, and bling',
        'toys': 'More info on cat toys here https://bit.ly/abc',
        'food': 'More info on cat food here https://bit.ly/def',
        'meds': 'More info on cat meds here https://bit.ly/ghi',
        'bling': 'More info on cat bling here https://bit.ly/jkl'
    }

...

    def product_matcher(self, fb_sender, user, msg):
        product = 'other'
        msg = msg.lower().strip()
        if self.auto_mode:
            if "auto: off" in msg:
                self.auto_mode = False
                self.fbm.send_message(fb_sender, user, "Auto mode is off")
                return
            for k in self.cats_dict.keys():
                if k in msg:
                    product = k
                    break
            self.fbm.send_message(fb_sender, user, self.cats_dict[product])
        if "auto: on" in msg:
                self.auto_mode = True
                self.fbm.send_message(fb_sender, user, "Auto mode is on")
        return product
```

如果用户通过 Messenger 发送消息，但没有人回复，则会向用户发回一个简易菜单。系统会在用户的消息中提取产品并发送适当的消息。当然，这段代码采用的方法比较幼稚，但希望它预示了这种潜力。

您可能会想，如果用户想和真人对话，这样会不会很烦？但是，一旦您上线并能够接收消息，就可以禁用自动回复。该代码允许用户使用命令 `auto: off` 和 `auto: on` 来控制交互。这也可以由渠道经理控制。

在上面的代码中，还将返回用户感兴趣的产品。例如，如果您想将用户及其产品选择记录到数据库中，则可以使用此代码。您也可以在数据库中查找用户，了解他们是新客户还是以前和公司有过交易的老用户。

摘要
---

在本教程中，您看到了一个用例，在该用例中，用户可以通过 Facebook Messenger 自动接收产品信息。此功能基于简单的关键字匹配。用户还可以根据需要切换自动回复模式。

更多资源
----

* 完整[源代码](https://github.com/nexmo-community/fbm-product-info)。
* 消息 API [文档](/messages/overview)

