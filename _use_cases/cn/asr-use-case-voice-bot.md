---
title:  语音机器人

products: voice/voice-api

description:  “本教程介绍如何使用自动语音识别来创建语音机器人/交互式语音助手应用程序。”

languages:
  - Node


---

语音机器人/交互式语音助手
=============

在本教程中，您将创建一个简单的机器人来接听呼入电话。该机器人将询问您所在的位置，并分享您的实际天气情况作为响应。您将使用 [express](https://expressjs.com/) Web 应用程序框架、[Weatherstack](https://weatherstack.com/) API 和 Vonage 自动语音识别 (ASR) 功能来实现此目的。

先决条件
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 已安装并设置 [Nexmo CLI](/application/nexmo-cli)
* [ngrok](https://ngrok.com/) - 使 Vonage 服务器可以通过互联网访问您的开发 Web 服务器
* 已安装 [Node.JS](https://nodejs.org/en/download/)

安装依赖项
-----

安装 [express](https://expressjs.com) Web 应用程序框架和 [body-parser](https://www.npmjs.com/package/body-parser) 软件包：

```sh
$ npm install express body-parser
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

这些 Webhook 必须可供 Vonage 服务器访问，因此在本教程中，您将使用 `ngrok` 向公共互联网公开本地开发环境。[这篇文章](/tools/ngrok)介绍了如何安装和运行 `ngrok`。

使用以下命令运行 `ngrok`：

```sh
ngrok http 3000
```

记下 `ngrok` 提供的临时主机名，并在下面的命令中用它替换 `example.com`：

```sh
nexmo app:create "Weather Bot" --capabilities=voice --voice-event-url=https://example.com/webhooks/event --voice-answer-url=https://example.com/webhooks/answer --keyfile=private.key
```

该命令返回一个应用程序 ID（应记下该 ID）和您的私钥信息（在本教程中，您可以放心地忽略该信息）。

链接号码
----

您需要将 Vonage 号码链接到您刚创建的语音 API 应用程序。使用以下命令：

```sh
nexmo link:app NEXMO_NUMBER NEXMO_APPLICATION_ID
```

现在可以编写应用程序代码了。

注册 Weatherstack 帐户
------------------

在本教程中，您将使用 Weatherstack API 获取天气信息。要发出请求，您必须[注册](https://weatherstack.com/signup/free)一个免费帐户来获取 API 密钥。

编写应答 Webhook
------------

当 Vonage 在您的虚拟号码上收到呼入电话时，它将向您的 `/webhooks/answer` 路由发出请求。此路由应接受 HTTP `GET` 请求，并返回 [Nexmo 呼叫控制对象 (NCCO)](/voice/voice-api/ncco-reference)，告诉 Vonage 如何处理该呼叫。

NCCO 应使用 `talk` 操作来问候主叫方，并使用 `input` 操作开始收听：

```js
'use strict'

const express = require('express')
const bodyParser = require('body-parser')
const app = express()
const http = require('http')

app.use(bodyParser.json())

app.get('/webhooks/answer', (request, response) => {

  const ncco = [{
      action: 'talk',
      text: 'Thank you for calling Weather Bot! Where are you from?'
    },
    {
      action: 'input',
      eventUrl: [
        `${request.protocol}://${request.get('host')}/webhooks/asr`],
      type: [ "speech" ]
    },
    {
      action: 'talk',
      text: 'Sorry, I don\'t hear you'
    }
  ]

  response.json(ncco)
})
```

编写事件 Webhook
------------

实现一个捕获呼叫事件的 Webhook，以便您可以在控制台中观察呼叫的生命周期：

```js
app.post('/webhooks/events', (request, response) => {
  console.log(request.body)
  response.sendStatus(200);
})
```

每当呼叫状态发生变化时，Vonage 都会向此端点发出 `POST` 请求。

编写 ASR Webhook
--------------

语音识别结果将发送到您在输入操作 `/webhooks/asr` 中设置的特定 URL。添加一个 Webhook 来处理结果和添加一些用户交互。

如果成功识别，请求有效负载将如下所示：

```json
{
  "speech": {
    "timeout_reason": "end_on_silence_timeout",
    "results": [
      {
        "confidence": 0.78097206,
        "text": "New York"
      }
    ]
  },
  "dtmf": {
    "digits": null,
    "timed_out": false
  },
  "from": "442039834429",
  "to": "442039061207",
  "uuid": "abfd679701d7f810a0a9a44f8e298b33",
  "conversation_uuid": "CON-64e6c8ef-91a9-4a21-b664-b00a1f41340f",
  "timestamp": "2020-04-17T17:31:53.638Z"
}
```

因此，您应该使用 `speech.results` 数组的第一个元素进行进一步分析。要获取天气状况数据，应向以下 URL 发出 HTTP `GET` 请求：

```http
GET http://api.weatherstack.com/current?access_key=<key>&query=<location>
```

在上一个代码块中，`access_key` 是您的 Weatherstack API 密钥，`query` 是用户说的话（或者至少是预期他们会说的话）。Weatherstack 在响应正文中提供了许多有趣的数据：

```json
{
  "request": {
    "type": "City",
    "query": "New York, United States of America",
    "language": "en",
    "unit": "m"
  },
  "location": {
    "name": "New York",
    "country": "United States of America",
    "region": "New York",
    "lat": "40.714",
    "lon": "-74.006",
    "timezone_id": "America/New_York",
    "localtime": "2020-04-17 13:33",
    "localtime_epoch": 1587130380,
    "utc_offset": "-4.0"
  },
  "current": {
    "observation_time": "05:33 PM",
    "temperature": 9,
    "weather_code": 113,
    "weather_icons": [
      "http://cdn.worldweatheronline.com/images/wsymbols01_png_64/wsymbol_0001_sunny.png"
    ],
    "weather_descriptions": [
      "Sunny"
    ],
    "wind_speed": 15,
    "wind_degree": 250,
    "wind_dir": "WSW",
    "pressure": 1024,
    "precip": 0,
    "humidity": 28,
    "cloudcover": 0,
    "feelslike": 7,
    "uv_index": 5,
    "visibility": 16,
    "is_day": "yes"
  }
}
```

在该应用中，您只需使用非常简单的参数，例如 `description`（“Sunny”）和 `temperature`。获取天气预报比获取实际温度更好，但是，由于免费的 Weatherstack 帐户只允许获取 `current` 状况，因此您将使用该数据。

收到 Weatherstack 的响应后，您将返回一个新的 NCCO，其中包含播放“今天纽约天气：晴，9 摄氏度”的通话操作。

最后，添加处理 ASR 回调的代码：

```js
app.post('/webhooks/asr', (request, response) => {

  console.log(request.body)

  if (request.body.speech.results) {

    const city = request.body.speech.results[0].text

    http.get(
      'http://api.weatherstack.com/current?access_key=WEATHERSTACK_API_KEY&query=' +
      city, (weatherResponse) => {
        let data = '';

        weatherResponse.on('data', (chunk) => {
          data += chunk;
        });

        weatherResponse.on('end', () => {
          const weather = JSON.parse(data);

          console.log(weather);

          let location = weather.location.name
          let description = weather.current.weather_descriptions[0]
          let temperature = weather.current.temperature          

          console.log("Location: " + location)
          console.log("Description: " + description)
          console.log("Temperature: " + temperature)

          const ncco = [{
            action: 'talk',
            text: `Today in ${location}: it's ${description}, ${temperature}°C`
          }]

          response.json(ncco)

        });

      }).on("error", (err) => {
      console.log("Error: " + err.message);
    });

  } else {

    const ncco = [{
      action: 'talk',
      text: `Sorry I don't understand you.`
    }]

    response.json(ncco)
  }

})
```

您可以向机器人添加一些附加逻辑，例如，如果位置在美国，则将温度转换为华氏温度。在创建 NCCO 之前添加以下代码片段：

```js
if (weather.location.country == 'United States of America') {
  temperature = Math.round((temperature * 9 / 5) + 32) + '°F'
} else {
  temperature = temperature + '°C'
}
```

不要忘记从消息文本中删除度数符号，因为它现在已包含在 `temperature` 变量值中：

```js
text: `Today in ${location}: it's ${description}, ${temperature}`
```

创建 Node.js 服务器
--------------

最后，编写可实例化 Node.js 服务器的代码：

```js
const port = 3000
app.listen(port, () => console.log(`Listening on port ${port}`))
```

测试应用程序
------

1. 通过执行以下命令来运行 Node.js 应用程序：

```sh
node index.js
```

1. 拨打 Vonage 号码并收听欢迎消息。

2. 说出您的城市名称。

3. 收听您的实际天气情况。

结语
---

在本教程中，您创建了一个应用程序，该应用程序使用语音 API 与主叫方进行交互，即，以语音消息的形式进行询问和应答。

您创建的机器人很简单，但它能够听主叫方讲话，并回复一些相关信息。您只需添加与您的案例和所用服务相关的适当业务逻辑，即可将该机器人用作 IVR 或某些客户自助服务应用的基础。

如您所见，使用自动语音识别 (ASR) 可以轻松、快速地实现对话式语音机器人或 IVR（交互式语音响应）/IVA（交互式语音助手）。如果您希望更灵活或实现近乎实时的交互，请尝试使用我们的 [WebSocket](/voice/voice-api/guides/websockets) 功能，该功能非常强大，可以为一些非常复杂的用例提供支持，例如人工智能、呼叫音频的分析和转录。

接下来做什么？
-------

这里还有一些资源建议，您可能会在本教程之后的步骤中使用它们：

* 详细了解[语音识别](/voice/voice-api/guides/speech-recognition)功能。
* 通过使用 SSML [自定义文本转语音](/voice/voice-api/guides/customizing-tts)消息，使机器人听起来更为自然。
* 了解如何通过 [WebSocket](/use-cases/voice-call-websocket-node) 连接获取和发回原始媒体。

