---
title:  使用 Python 调用 Websocket

products: voice/voice-api

description:  在本教程中，您将学习如何将呼叫连接到 WebSocket 端点，该端点会将呼叫音频回传给主叫方。

languages:
  - Python


---

使用 Python 调用 Websocket
======================

您可以使用语音 API 将呼叫连接到 [WebSocket](/voice/voice-api/guides/websockets)，从而提供通过 WebSocket 协议实时传递的双向呼叫音频流。这样您就可以处理呼叫音频，以使用人工智能执行情感分析、实时转录和决策等任务。

在本教程中，您将呼入电话连接到 WebSocket 端点。WebSocket 服务器将侦听呼叫音频并将其回传给您。您将使用 [Flask](http://flask.pocoo.org/) Web 应用程序微框架和 [Flask-Sockets](https://www.npmjs.com/package/express-ws) 来实现此目的，Flask-Sockets 允许您像定义其他 Flask 路由一样定义 WebSocket 端点。

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up) - 用于获取 API 密钥和密码
* [ngrok](https://ngrok.com/) - 使 Vonage 服务器可以通过互联网访问您的开发 Web 服务器
* [Node.js](https://nodejs.org/en/download/) - 以便您可以使用 `npm` 包安装程序来安装 Nexmo CLI

安装 Nexmo CLI
------------

您需要一个 Vonage 虚拟号码来接收呼入电话。如果您还没有，则可以在[开发人员 Dashboard](https://dashboard.nexmo.com) 中购买并配置号码，也可以使用 [Nexmo CLI](https://github.com/Nexmo/nexmo-cli)。本教程使用 CLI。

在终端提示符下运行以下 Node Package Manager (`npm`) 命令，以安装 CLI 并使用您在[开发人员 Dashboard](https://dashboard.nexmo.com) 中找到的 API 密钥和密码对其进行配置：

```sh
npm install -g nexmo-cli
nexmo setup VONAGE_API_KEY VONAGE_API_SECRET
```

购买 Vonage 号码
------------

如果您还没有 Vonage 号码，请购买一个来接听呼入电话。

首先，列出您所在国家/地区的可用号码（将 `GB` 替换为两个字符的[国家/地区代码](https://www.iban.com/country-codes)）：

```sh
nexmo number:search GB
```

购买其中一个可用号码。例如，要购买号码 `447700900001`，请执行以下命令：

```sh
nexmo number:buy 447700900001
```

创建语音 API 应用程序
-------------

使用 CLI 创建具有 Webhook 的语音 API 应用程序，这些 Webhook 将分别负责接听 Vonage 号码上的呼叫 (`/webhooks/answer`) 和记录呼叫事件 (`/webhooks/events`)。

这些 Webhook 必须可供 Vonage 服务器访问，因此在本教程中，您将使用 `ngrok` 向公共互联网公开本地开发环境。[这篇博客文章](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/)介绍了如何安装和运行 `ngrok`。

使用以下命令运行 `ngrok`：

```sh
ngrok http 3000
```

记下 `ngrok` 提供的临时主机名，并在下面的命令中用它替换 `example.com`：

```sh
nexmo app:create "My Echo Server" https://example.com/webhooks/answer https://example.com/webhooks/events
```

该命令返回一个应用程序 ID（应记下该 ID）和您的公钥信息（在本教程中，您可以放心地忽略该信息）。

链接号码
----

您需要将 Vonage 号码链接到您刚创建的语音 API 应用程序。使用以下命令：

```sh
nexmo link:app VONAGE_NUMBER VONAGE_APPLICATION_ID
```

现在可以编写应用程序代码了。

创建项目
----

为应用程序创建一个目录，使用 `cd` 进入该目录，然后创建一个名为 `server.py` 的文件，以包含您的应用程序代码。

然后，安装 [Flask](http://flask.pocoo.org/)、[Flask-Sockets](https://www.npmjs.com/package/express-ws) 和 [gevent](https://pypi.org/project/gevent/)（`Flask-Sockets` 依赖的网络库）模块：

```sh
$ pip3 install Flask gevent Flask-Sockets
```

编写应答 Webhook
------------

当 Vonage 在您的虚拟号码上收到呼入电话时，它将向您的 `/webhooks/answer` 路由发出请求。此路由应接受 HTTP `GET` 请求，并返回 [Nexmo 呼叫控制对象 (NCCO)](/voice/voice-api/ncco-reference)，告诉 Vonage 如何处理该呼叫。

NCCO 应使用 `text` 操作来问候主叫方，并使用 `connect` 操作将呼叫连接到 Webhook 端点：

```python
#!/usr/bin/env python3
from flask import Flask, request, jsonify
from flask_sockets import Sockets

app = Flask(__name__)
sockets = Sockets(app)


@app.route("/ncco")
def answer_call():
    ncco = [
        {
            "action": "talk",
            "text": "Please wait while we connect you to the echo server",
        },
        {
            "action": "connect",
            "from": "VonageTest",
            "endpoint": [
                {
                    "type": "websocket",
                    "uri": "wss://{0}/socket".format(request.host),
                    "content-type": "audio/l16;rate=16000",
                }
            ],
        },
    ]

    return jsonify(ncco)
```

`endpoint` 的 `type` 是 `websocket`，`uri` 是可以访问 WebSocket 服务器的 `/socket` 路由，`content-type` 指定音频质量。

编写事件 Webhook
------------

编写一个 Webhook，Vonage 服务器可以调用它来为您提供有关呼叫事件的更新。在本教程中，我们不会使用请求数据，因此仅返回 `HTTP 200` 响应 (`success`)：

```python
@app.route("/webhooks/event", methods=["POST"])
def events():
    return "200"
```

每当呼叫状态发生变化时，Vonage 都会向此端点发出 `POST` 请求。

创建 WebSocket
------------

为 `/socket` 路由创建路由处理程序。该处理程序将侦听 `message` 事件，每次 WebSocket 从呼叫中收到音频时都会引发此事件。您的应用程序应该通过使用 `send()` 方法将音频回传给主叫方来做出响应：

```javascript
@sockets.route("/socket", methods=["GET"])
def echo_socket(ws):
    while not ws.closed:
        message = ws.receive()
        ws.send(message)
```

创建服务器
-----

最后，编写可实例化服务器的代码：

```python
if __name__ == "__main__":
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler

    server = pywsgi.WSGIServer(("", 3000), app, handler_class=WebSocketHandler)
    server.serve_forever()
```

测试应用程序
------

1. 通过执行以下命令来运行 Python 应用程序：

```sh
python3 server.py
```

1. 拨打 Vonage 号码并收听欢迎消息。

2. 随便说点什么，您会听到您的声音由通话中的另一个参与者（您的 WebSocket 服务器）回传给您。

结语
---

在本教程中，您创建了一个使用语音 API 连接到 WebSocket 端点的应用程序。

您创建的 WebSocket 非常简单，但它能够侦听呼叫音频并做出响应。WebSocket 的功能非常强大，可以为一些非常复杂的用例提供支持，例如人工智能、呼叫音频的分析和转录。

延伸阅读
----

以下资源将帮助您深入了解如何在语音 API 应用程序中使用 WebSocket：

* GitHub 上本教程的[源代码](https://github.com/Nexmo/python-websocket-echo-server)
* [WebSocket 指南](/voice/voice-api/guides/websockets)
* [WebSocket 协议标准](https://tools.ietf.org/html/rfc6455)
* [Vonage 语音和 WebSocket 录制的网络研讨会入门](https://www.nexmo.com/blog/2017/02/15/webinar-getting-started-nexmo-voice-websockets-dr/)
* Vonage 开发人员博客上[有关 WebSocket 的文章](https://www.nexmo.com/?s=websockets)
* [NCCO 连接操作](/voice/voice-api/ncco-reference#connect)
* [端点指南](/voice/voice-api/guides/endpoints)
* [语音 API 参考文档](/voice/voice-api/api-reference)

