---
title:  广播基于语音的重要警报

products: voice/voice-api

description:  在本教程中，您将学习如何通过电话联系人员列表、传达消息以及查看谁确认已收到消息。这些基于语音的重要警报比短信更持久，从而使您的消息更容易被注意到。此外，通过接收者确认，您可以确保消息已传递到位。

languages:
  - PHP


---

广播基于语音的重要警报
===========

持续响铃的电话比短信或推送警报更难错过，因此，当您需要确保将[重要警报](https://www.nexmo.com/use-cases/voice-based-critical-alerts)传递给正确的人时，打电话是最好的选择之一。

在本教程中，您将学习如何通过电话联系人员列表、传达消息以及查看谁确认已收到消息。这些基于语音的重要警报比短信更持久，从而使您的消息更容易被注意到。此外，通过接收者确认，您可以确保消息已传递到位。

先决条件
----

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* [Composer](http://getcomposer.org/)，用于安装 [Vonage PHP Server SDK](https://github.com/nexmo/nexmo-php)
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求；或者 [ngrok](https://ngrok.com/)，以便能够从外部访问您的本地开发平台。
* 来自 [https://github.com/Nexmo/php-voice-alerts-tutorial](https://github.com/Nexmo/php-voice-alerts-tutorial) 的教程代码 - 克隆项目或下载 zip 文件。

⚓ 创建语音应用程序
⚓ 预配虚拟号码

入门
---

我们将从注册与此应用程序一起使用的 Vonage 号码开始。请按照[应用程序入门](https://developer.nexmo.com/concepts/guides/applications#getting-started-with-applications)的说明进行操作。它将引导您完成购买号码、创建应用程序以及链接两者的过程。

配置应用程序时，您需要提供可公开访问的 Web 服务器或 ngrok 端点的 URL，作为 `answer_url` 和 `event_url` 的一部分。这些文件在本项目中分别称为 `answer.php` 和 `event.php`。例如，如果您的 ngrok URL 为 `https://25b8c071.ngrok.io`，则配置将为：

* **answer\_url** `https://25b8c071.ngrok.io/answer.php`
* **event\_url** `https://25b8c071.ngrok.io/event.php`

创建应用程序时，您将获得用于身份验证的密钥。将其保存到名为 `private.key` 的文件中，并妥善保管！您稍后需要用它拨打呼出电话。

创建、配置应用程序并将其链接到电话号码后，看看代码，然后去试一试。

⚓ 创建 Nexmo 呼叫控制对象
⚓ 创建呼叫

教您的应用程序“说话”
-----------

当某人通过电话连接到您的应用程序时，您可以通过 Vonage 呼叫控制对象 (NCCO) 控制此人听到的内容。这些对象可用于呼入和呼出电话 - 通话正在进行时，它与原来没有什么区别。

当拨打我们之前链接的号码时，Vonage 会向您在应用程序中配置的 `answer_url` 发出请求，并期望响应是一个 NCCO 数组。

看一下存储库中的 `answer.php`。此代码将返回 NCCO：在本案例中为一些文本转语音消息以及用户输入提示。

```php
$ncco = [
    [
        "action" => "talk",
        "voiceName" => "Jennifer",
        "text" => "Hello, here is your message. I hope you have a nice day."
    ],
    [
        "action" => "talk",
        "voiceName" => "Jennifer",
        "text" => "To confirm receipt of this message, please press 1 followed by the pound sign"
    ],
    [
        "action" => "input",
        "submitOnHash" => "true",
        "timeout" => 10
    ],
    [
        "action" => "talk",
        "voiceName" => "Jennifer",
        "text" => "Thank you, you may now hang up."
    ]
];

// Vonage expect you to return JSON with the correct headers
header('Content-Type: application/json');
echo json_encode($ncco);
```

这里展示了几种不同类型的 NCCO 的实际效果，希望能让您了解使用 NCCO 可以执行的操作类型（如果您感到好奇，可以查看详细的 [NCCO 参考](https://developer.nexmo.com/voice/voice-api/ncco-reference)）。这些都是 JSON 对象，您的代码将构建输出，然后使用正确的 JSON 标头将其作为响应发送。

这是用另一部电话拨打 Vonage 号码并查看上述代码实际效果的绝佳时机！接下来，随意编辑，看看还能做什么。

跟踪呼叫期间发生的事件
-----------

当您让应用程序在无人监督的情况下在电话上说话时，能够提供有关电话状态的信息会很有用。为了帮助实现这一点，Vonage 将向您在设置应用程序时配置的 `event_url` 发送 Webhook。这些 Webhook 包含状态更新，以便让您知道电话正在响起、已被接听等等。

用于实现此目的的代码在我们项目的 `event.php` 中：它会检查特定状态并将有关它们的信息写入日志文件。

```php
<?php

// Vonage sends a JSON payload to your event endpoint, so read and decode it
$request = json_decode(file_get_contents('php://input'), true);

// Work with the call status
if (isset($request['status'])) {
    switch ($request['status']) {
    case 'ringing':
        record_steps("UUID: {$request['conversation_uuid']} - ringing.");
        break;
    case 'answered':
        record_steps("UUID: {$request['conversation_uuid']} - was answered.");
        break;
    case 'complete':
        record_steps("UUID: {$request['conversation_uuid']} - complete.");
        break;
    default:
        break;
    }
}

function record_steps($message) {
    file_put_contents('./call_log.txt', $message.PHP_EOL, FILE_APPEND | LOCK_EX);
}
```

> 这里的 `record_steps()` 函数只是一个非常基本的日志记录示例，用于写入文本文件。您可以将其替换为首选的日志记录协议。

您可以通过检查 `call_log.txt` 的内容来查看之前呼叫应用程序时发生了什么。此文件保存了特定电话或“对话”经历的每个状态的记录。每一行都包含对话标识符；当我们开始同时拨打许多呼出电话来传递广播消息时，这一点就变得非常重要。我们还是会想知道哪个事件属于哪个对话！

拨打号码时可以尝试几种不同的方式，边打边看日志文件。看看在以下情况下会发生什么：

* 提示输入 `1` 时，输入其他数字
* 不接听电话，而是将其发送到语音信箱

一旦我们拨打电话，您的应用程序就可以处理它们，这说明是时候构建项目的广播部分了。

⚓ 向多人广播

拨打呼出电话
------

我们需要将[消息广播](https://www.nexmo.com/use-cases/voice-broadcast)给多个人，以避免重要消息仅传给一个人而被遗漏。因此，脚本会循环遍历您在 `config.php` 中设置的所有联系人，并要求每个人都收到一个电话。

要拨打电话，您需要使用有关 Vonage 凭据、应用程序本身以及您要呼叫的人的信息来配置 PHP 应用程序。

将 `config.php.example` 复制到 `config.php` 并进行编辑，以添加您自己的以下值：

* 您可以在 [Dashboard](https://dashboard.nexmo.com) 中找到的 API 密钥和密码
* 您在本教程开始时创建的应用程序的 ID
* 用于呼叫您的用户的 Vonage 号码
* 您的应用程序的公共 URL
* 应接收广播消息的人员的姓名和号码数组

> 还要检查您是否将创建应用程序时生成的密钥保存在项目顶层的 `private.key` 中。

您还需要运行 `composer install` 来引入项目依赖项。其中包括 [Vonage PHP Server SDK](https://github.com/nexmo/nexmo-php)，该 SDK 提供一些辅助代码，可让您使用 Vonage API 时更轻松。

回到存储库，此步骤所需的代码在 `broadcast.php` 中：

```php
require 'vendor/autoload.php';
require 'config.php';

$basic  = new \Nexmo\Client\Credentials\Basic($config['api_key'], $config['api_secret']);
$keypair = new \Nexmo\Client\Credentials\Keypair(
    file_get_contents(__DIR__ . '/private.key'),
    $config['application_id']
);

$client = new \Nexmo\Client(new \Nexmo\Client\Credentials\Container($basic, $keypair));

$contacts = $config['contacts'];

foreach ($contacts as $name => $number) {
    $client->calls()->create([
        'to' => [[
            'type' => 'phone',
            'number' => $number
        ]],
        'from' => [
            'type' => 'phone',
            'number' => $config['from_number']
        ],
        'answer_url' => [$config['base_url'] . '/answer.php'],
        'event_url' => [$config['base_url'] . '/event.php'],
        'machine_detection' => 'continue'
    ]);

    // Sleep for half a second
    usleep(500000);
}
```

`broadcast.php` 中的代码使用您配置的 API 密钥和密码、应用程序 ID 和您先前保存的 `private.key` 文件来创建 `Nexmo\Client` 对象。该对象提供一个简单的界面来拨打电话并传递所需的[呼叫选项](https://developer.nexmo.com/api/voice#createCall)。

您可能会注意到，有一条指令是使用 `usleep()` 方法进行短暂的暂停。这是为了避免达到 [API 速率限制](https://help.nexmo.com/hc/en-us/articles/207100288-What-is-the-maximum-number-of-calls-per-second-)。

现在通过以下方式来测试应用程序：运行 `php broadcast.php`，看您提供的所有电话号码是否同时响起。您可以通过修改返回给用户的 NCCO 来修改语音消息。您还可以指定不同的声音和语言（请参阅 [NCCO 参考部分](https://docs.nexmo.com/voice/voice-api/ncco-reference#talk)中的完整选项列表）。

> 如果您有额外的参数要传递给 `answer_url`，可以向该上下文添加 GET 参数。例如，您可以添加人名，然后在请求到达 `answer.php` 时访问该人名。

您还可以选择使用应用程序执行其他操作，例如使用录音而不是文本转语音功能，或者录制用户的响应。接下来的几节将介绍如何进行这些活动。

### 使用录音而不是文本转语音

要使用预先录制的消息而不是（或同时！）使用 Vonage 的文本转语音功能，请使用包含操作 `stream` 的 NCCO。`stream` 允许您向主叫方回放音频文件。“streamUrl”将指向您的音频文件。

```php
[
    "action" => "stream",
    "streamUrl" => ["https://example.com/audioFile.mp3"]
],
```

> 如果您测试录音，但声音太大或太小，则可以通过设置“音量”来调整通话中录音的音量。默认值为“0”，您可以将音量调低至 -1 或调高至 1，增量为 0\.1。

```php
[
    "action" => "stream",
    "level" => "-0.4",
    "streamUrl" => ["https://example.com/audioFile.mp3"]
],
```

有关更多信息，请查看[有关数据流的 NCCO 参考文档](https://developer.nexmo.com/voice/voice-api/ncco-reference#stream)。

### 处理答录机和语音信箱

如果您想跟踪哪些号码已转到语音信箱而不是被接听，可以在拨打呼出电话时添加 `machine_detection` 参数，就像您在 `broadcast.php` 中看到的那样。您可以为此设置两个选项，`continue` 或 `hangup`。如果要记录呼叫已转到语音信箱，请选择 `continue`，系统将向事件 Webhook（在 `event_url` 中指定的 URL）发送一个 HTTP 请求。

```php
'answer_url' => ['https://example.com/answer.php'],
'event_url' =>  ['https://example.com/event.php'],
'machine_detection' => 'continue'
```

在 `event.php` 中，脚本将查找状态“machine”并相应地记录事件。

### 确认收到消息

您会注意到，当消息被送达时，作为用户，系统会要求您按一些键来确认您已经收到消息。这是通过以下操作来实现的：先是给用户下达指令的 `talk` 操作，然后是捕获按钮按下的 `input` 操作。

```php
[
  "action" => "input",
  "submitOnHash" => "true",
  "timeout" => 10
],
```

通过将 `submitOnHash` 设置为 true，当输入井号 (`#`) 时，呼叫将移至下一个 NCCO。否则，呼叫将等待指定的 `timeout` 秒数（默认值为 3），然后自动移至下一个 NCCO。

在事件脚本中，您将看到一些代码处理输入操作。来自输入操作的数据到达 `dtmf` 键下方，并以按下的数字作为值。

```php
if (isset($request['dtmf'])) {
  switch ($request['dtmf']) {
      case '1':
          record_steps("UUID: {$request['conversation_uuid']} - confirmed receipt.");
          break;
      default:
          record_steps("UUID: {$request['conversation_uuid']} - other button pressed ({$request['dtmf']}).");
          break;
  }
}
```

在本示例中，我们只记录发生的情况，但在您自己的应用程序中，您可以根据自己的需求存储或响应用户输入。

⚓ 结语

您的广播呼叫应用程序
----------

现在，您有了一个简单但可行的语音警报系统，您可以在此系统中广播文本转语音或预先录制的消息，记录哪些呼叫被接听，哪些呼叫被发送到语音信箱，并从收到消息的用户处接收确认收到消息。

⚓ 参考

后续步骤和延伸阅读
---------

* [使用 Ngrok 进行本地开发](/tools/ngrok)
* [拨打呼出电话](/voice/voice-api/guides/outbound-calls) - 用不同编程语言编写的用于拨打电话的代码片段
* [使用 DTMF 处理用户输入](/voice/voice-api/code-snippets/handle-user-input-with-dtmf) - 使用各种技术堆栈的代码来捕获用户的按钮按下事件的示例。
* [NCCO 参考](/voice/voice-api/ncco-reference) - 有关呼叫控制对象的参考文档
* [语音 API 参考](/api/voice) - API 参考文档

