---
title:  交互式语音响应

products: voice/voice-api

description:  构建一个自动电话系统，供用户使用拨号键盘输入信息并收听语音答复

languages:
  - PHP


---

交互式语音响应
=======

对于进行简单问询的用户，通过提供交互式语音响应 (IVR) 服务，让他们的问询变得方便快捷。本教程将引导您构建一个应用程序，以使用简单的文本转语音 (TTS) 提示和拨号键盘输入来实现此目的。

场景：一个客户打电话给快递公司，想了解自己的订单状态。系统将提示他们输入自己的订单号，然后，他们会听到语音答复，获知（由我们的示例代码随机生成的）订单状态。

本教程基于[简单的 IVR](https://www.nexmo.com/use-cases/interactive-voice-response/) 用例。所有代码都可以在 [GitHub](https://github.com/Nexmo/php-phone-menu) 上找到。

教程内容
----

* [准备阶段](#setting-up-for-ivr) - 创建一个应用程序，将其配置为指向您的代码，并设置将用于本教程的号码。

* [拨打电话](#try-it-yourself) - 呼叫您的应用程序，并按提示逐步操作，直至听到语音信息。

* [代码审查：处理呼入电话](#handle-an-inbound-call) - 如何对呼入电话做出第一个响应。

* [代码审查：发送文本转语音问候语](#send-text-to-speech-greeting) - 回答时用文字转语音的方式问候用户。

* [代码审查：通过 IVR 请求用户输入](#request-user-input-via-ivr-interactive-voice-response) - 创建文本转语音提示，然后请求用户输入。

* [代码审查：响应用户输入](#respond-to-user-input) - 处理用户订单号输入，并通过文本转语音的方式播放状态。

* [改善文本转语音体验的技巧](#tips-for-better-text-to-speech-experiences) - 检查我们用来给出更好语音答复的辅助方法。

* [后续步骤](#next-steps) - 延伸阅读，供您参考。

针对 IVR 进行设置
-----------

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)。
* 已安装并设置 [Nexmo CLI](https://github.com/nexmo/nexmo-cli)。
* 可公开访问的 PHP Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。对于本地开发，我们建议使用 [ngrok](https://ngrok.com)。
* [教程代码](https://github.com/Nexmo/php-phone-menu)，克隆存储库或下载 zip 文件并将其解压缩到您的计算机中。
* [学习使用方法 `ngrok`](/tools/ngrok)

创建语音应用程序
--------

Vonage 应用程序包含连接到 Vonage 端点和轻松使用我们的产品所需的安全和配置信息。您使用应用程序中的安全信息来呼叫 Vonage 产品。电话接通后，Vonage 与您的 Webhook 端点进行通信，以便您管理通话。

您可以使用 Nexmo CLI 通过以下命令为语音 API 创建应用程序，并将 `YOUR_URL` 段替换为您自己的应用程序的 URL：

```bash
nexmo app:create phone-menu YOUR_URL/answer YOUR_URL/event
Application created: 5555f9df-05bb-4a99-9427-6e43c83849b8
```

此命令使用 `app:create` 命令创建一个新应用。参数包括：

* `phone-menu` - 为此应用程序提供的名称
* `YOUR_URL/answer` - 当您收到 Vonage 号码的呼入电话时，Vonage 会发出 [GET] 请求，并从该 Webhook 端点检索控制呼叫流程的 NCCO
* `YOUR_URL/event` - 当呼叫状态发生变化时，Vonage 会将状态更新发送到该 Webhook 端点

此命令返回用于标识应用程序的 UUID（通用唯一标识符）- 您可能需要复制并粘贴此标识符，因为我们稍后会用到它。

购买电话号码
------

要处理应用程序的呼入电话，您需要一个来自 Vonage 的号码。如果您已经有了要使用的号码，请跳到下一节，将现有号码与您的应用程序关联起来。

您可以使用 [Nexmo CLI](https://github.com/nexmo/nexmo-cli) 购买电话号码：

```bash
nexmo number:buy --country_code GB --confirm
Number purchased: 441632960960
```

`number:buy` 命令允许您使用 [ISO 3166-1 alpha-2 格式](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)指定号码应在哪个国家/地区。同样，通过指定 `--confirm`，我们无需确认号码的选择，将购买第一个可用号码。

现在，我们可以将电话号码设置为指向您先前创建的应用程序。

将电话号码链接到 Vonage 应用程序
--------------------

接下来，您将每个电话号码与您刚创建的 *phone-menu* 应用程序链接起来。当与应用程序关联的号码发生任何事件时，Vonage 向您的 Webhook 端点发送一个 Web 请求，以请求事件相关信息。为此，请在 Nexmo CLI 中使用 `link:app` 命令：

```bash
nexmo link:app 441632960960 5555f9df-05bb-4a99-9427-6e43c83849b8
```

参数包括您要使用的电话号码，以及您先前[创建语音应用程序](#create-a-voice-application)时返回的 UUID。

亲手试试吧！
------

代码示例有详细的演练，但对于急性子的人，让我们在深入之前先试试该应用程序。您应该按照上述说明创建并链接了号码和应用程序；现在，我们将获取并运行代码。

如果尚未克隆[存储库](https://github.com/Nexmo/php-phone-menu)，请先进行克隆。

在项目目录中，使用 Composer 安装依赖项：

    composer install

将 `config.php.dist` 复制到 `config.php` 并进行编辑，以添加您的基 URL（与您在上面设置应用程序时使用的 URL 相同）。

> 如果您使用 ngrok，它将随机生成一个隧道 URL。在进行其他配置之前启动 ngrok 可能会有所帮助，因为这样您就知道端点将使用哪个 URL（付费 ngrok 用户可以保留隧道名称）。如果您需要随时更新所设置的 URL，那么，知道有一个 `nexmo app:update` 命令可能也很有用。

一切就绪？则启动 PHP Web 服务器：

    php -S 0:8080 ./public/index.php

等服务器运行后，拨打 Vonage 号码并按照说明操作即可！当发生开始呼叫、铃声响起等一系列事件时，代码会收到 `/event` 的 Webhook。当系统接听电话时，一个 Webhook 进入 `/answer`，代码以文本转语音的方式进行响应，然后等待用户输入。然后，用户输入通过 Webhook 到达 `/search`，代码再次以文本转语音的方式进行响应。

现在，您已经看到了实际操作，您可能很想知道各种元素是如何工作的。继续阅读 PHP 代码的完整演练，以及它如何管理呼叫流程...

处理呼入电话
------

当 Vonage 收到 Vonage 号码的呼入电话时，它会向您在[创建语音应用程序](#create-a-voice-application)时设置的事件 Webhook 端点发出请求。每次从用户处收集 *DTMF* 输入时，也会发送一个 Webhook。

本教程代码使用一个简单的路由器来处理这些入站 Webhook。路由器确定请求的 URI 路径，并使用它通过电话菜单映射主叫方的导航 - 与 Web 应用程序中的 URL 相同。

系统捕获 Webhook 主体的数据，并在请求信息中传递给菜单：

```php
<?php

// public/index.php

require_once __DIR__ . '/../bootstrap.php';

$uri = ltrim(strtok($_SERVER["REQUEST_URI"],'?'), '/');
$data = file_get_contents('php://input');
```

Vonage 为呼叫状态的每一次更改发送一个 Webhook。例如，当电话 `ringing` 时，呼叫已 `answered` 或 `complete`。应用程序使用 `switch()` 语句记录 `/event` 端点收到的数据，以进行调试。其他所有请求都转到处理用户输入的代码。代码如下：

```php
<?php

// public/index.php

switch($uri) {
    case 'event':
        error_log($data);
        break;
    default:
        $ivr = new \NexmoDemo\Menu($config);
        $method = strtolower($uri) . 'Action';

        $ivr->$method(json_decode($data, true));

        header('Content-Type: application/json');
        echo json_encode($ivr->getStack());
}
```

任何不是针对 `/event` 的请求都会被映射到 `Menu` 对象上的 `Action` 方法。传入的请求数据将传递到该方法。路由器检索 NCCO（Nexmo 呼叫控制对象），并使用正确的 `Content-Type` 将其作为 JSON 正文在响应中发送。

`$config` 数组传递到 `Menu` 对象，因为在生成可能包含回调 URL 的 NCCO 时，它需要知道应用程序的基 URL：

```php
<?php

// src/Menu.php

public function __construct($config)
{
    $this->config = $config;
}
```

生成 NCCO
-------

Nexmo 呼叫控制对象 (NCCO) 是一个 JSON 数组，可用于控制语音 API 呼叫的流程。Vonage 预计您的应答 Webhook 返回一个 NCCO，以控制呼叫的各个阶段。

为了管理 NCCO，本示例应用程序使用数组操作和一些简单的方法。

路由器处理 JSON 编码，`Menu` 对象通过其 `getStack()` 方法提供对 NCCO 堆栈的访问：

```php
<?php

// src/Menu.php

public function getStack()
{
    return $this->ncco;
}
```

还有一些辅助方法可为管理 NCCO 堆栈提供基础。您可能会发现这些方法在您自己的应用程序中很有用：

```php
<?php

// src/Menu.php

protected function append($ncco)
{
    array_push($this->ncco, $ncco);
}

protected function prepend($ncco)
{
    array_unshift($this->ncco, $ncco);
}
```

### 发送文本转语音问候语

接听电话后，Vonage 将 Webhook 发送到应用程序的 `/answer` 端点。路由代码将此发送到 `Menu` 对象的 `answerAction()` 方法，该方法首先添加一个包含问候语的 NCCO。

```php
<?php

// src/Menu.php

public function answerAction()
{
    $this->append([
        'action' => 'talk',
        'text' => 'Thanks for calling our order status hotline.'
    ]);

    $this->promptSearch();
}
```

这个示例很好地展示了如何返回简单的文本转语音消息。

### 通过 IVR（交互式语音响应）请求用户输入

对于我们的示例应用程序，用户需要提供其订单 ID。对于这部分，首先在提示中添加另一个“talk”NCCO（如果包含了问候语，那么每次我们向用户询问订单号时，您都会向用户打招呼）。下一个 NCCO 是接收用户输入的位置：

```php
<?php

// src/Menu.php

protected function promptSearch()
{
    $this->append([
        'action' => 'talk',
        'text' => 'Using the numbers on your phone, enter your order number followed by the pound sign'
    ]);

    $this->append([
        'action' => 'input',
        'eventUrl' => [$this->config['base_path'] . '/search'],
        'timeOut' => '10',
        'submitOnHash' => true
    ]);
}
```

NCCO 中的 `eventUrl` 选项用于指定用户输入数据后将 Webhook 发送到的位置。这与您使用 HTML `<form>` 的 `action` 属性的效果基本相同。这也是使用 `$config` 数组和基 URL 的位置。

该命令还使用了一些特定于 `input` 的属性。`timeOut` 让用户有更多的时间输入订单号，`submitOnHash` 使用井号（对所有讲英式英语的人而言是一个哈希符号“\#”）结束订单 ID，让用户无需等待。

### 响应用户输入

在用户提供输入后，Vonage 向 `input` 中定义的 `eventUrl` 发送一个 Webhook。由于我们将 `eventUrl` 设置为 `/search`，因此我们的代码会将请求路由到 `searchAction`。该请求包括一个 `dtmf` 字段，其中包含用户输入的数字。我们使用这些输入数据并随机生成示例数据返回给用户，您的应用程序可能会做一些更有用的事，比如从数据库中获取信息。操作如下：

```php
<?php

// src/Menu.php

public function searchAction($request)
{
    if(isset($request['dtmf'])) {
        $dates = [new \DateTime('yesterday'), new \DateTime('today'), new \DateTime('last week')];
        $status = ['shipped', 'backordered', 'pending'];

        $this->append([
            'action' => 'talk',
            'text' => 'Your order ' . $this->talkCharacters($request['dtmf'])
                      . $this->talkStatus($status[array_rand($status)])
                      . ' as  of ' . $this->talkDate($dates[array_rand($dates)])
        ]);
    }

    $this->append([
        'action' => 'talk',
        'text' => 'If you are done, hangup at any time. If you would like to search again'
    ]);

    $this->promptSearch();
}
```

从搜索操作中可以看到，示例应用程序向用户发回了一些相当愚蠢的数据！这段代码中有一个 NCCO，它包含来自传入 `dtmf` 数据字段的订单号、随机订单状态和随机日期（今天、昨天或一周前）作为语音“更新”。在您自己的应用程序中，可能会有一些更合理的逻辑。

将订单信息传递给用户后，他们会被告知可以随时挂断电话。示例应用程序重用了添加订单提示 NCCO 的方法。这样，用户可以搜索其他订单，但不会每次都听到欢迎提示。

改善文本转语音体验的技巧
------------

`Menu` 类还有一些方法，可以改善将应用程序数据转换为语音提示的过程。此应用程序中的示例包括：

* 上次报告状态的日期
* 订单号
* 订单状态

有些方法可以帮助我们将这些值清楚地传达给用户。首先：`talkDate` 方法仅返回日期格式的字符串，这种格式非常适合口语表达。

```php
<?php

// src/Menu.php

protected function talkDate(\DateTime $date)
{
    return $date->format('l F jS');
}
```

`talkCharacters` 方法在字符串中的每个字符之间放置一个空格，以便逐字符阅读。我们会在报告订单号时使用此方法：

```php
<?php

// src/Menu.php

protected function talkCharacters($string)
{
    return implode(' ', str_split($string));
}
```

`talkStatus` 方法使用简单查找将极其简单的常量转换为更具对话性的短语：

```php
<?php

// src/Menu.php

protected function talkStatus($status)
{
    switch($status){
        case 'shipped':
            return 'has been shipped';
        case 'pending':
            return 'is still pending';
        case 'backordered':
            return 'is backordered';
        default:
            return 'can not be located at this time';
    }
}
```

结语
---

现在，您已经构建了一个交互式电话菜单，该菜单既能收集用户的输入，又能回复（尽管是假的）信息。与其使用 `talk` NCCO 通知用户，不如使用 `connect` NCCO 将呼叫转接到某个部门，或使用 `record` NCCO 捕获用户的语音信箱。

后续步骤
----

这里还有一些资源，可能对构建此类应用程序有用：

* [文本转语音指南](https://developer.nexmo.com/voice/voice-api/guides/customizing-tts) - 包括所提供的不同语音，以及用于更好地控制语音输出的 SSML（语音合成标记语言）的相关信息。
* [Twitter IVR](https://www.nexmo.com/blog/2018/06/26/twitter-interactive-voice-response-dr/) - 另一个相当愚蠢的示例，但却是用 Python 编写的优秀示例应用。
* [在 AWS Lambda 上使用 Python 对提示呼叫进行文本转语音操作](https://www.nexmo.com/blog/2018/02/16/text-speech-prompt-calls-using-python-aws-lambda-dr/) - 类似的应用程序，但这次使用 AWS Lambda（无服务器平台）和 Python。
* [处理 DTMF 的代码示例](https://developer.nexmo.com/voice/voice-api/code-snippets/handle-user-input-with-dtmf) - 本教程中使用的处理用户拨号键盘输入的各种编程语言示例。

