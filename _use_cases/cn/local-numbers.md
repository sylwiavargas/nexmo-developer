---
title:  本地号码

products: voice/voice-api

description:  “将您的免费号码（例如 800、0800）替换为本地地理号码，以便您提供更好的客户服务。用户打电话更便宜，而且与您联系时，您可以提供位置敏感型信息。”

languages:
  - Ruby


---

语音电话的本地号码
=========

尽管免费电话的价格可能很高，但它们也是为客户提供联系您的方式中最不私人的一种方式。考虑到这一点，我们将用多个本地化的区域号码代替您昂贵的免费号码。这样一来，您不仅可以提供一个友好的本地号码供客户拨打，还可以节省昂贵的免费号码租赁费用。

此外，借助本地号码的强大功能，我们将向您展示如何采取一些明智的步骤，为拨入电话的任何人提供更加量身定制的体验，同时收集有关客户不断变化的需求的宝贵信息。

在本教程中，您将为虚构的高速运输管理局创建一个应用程序，使用户可以使用本地号码拨入电话，立即获取本地交通系统的最新动态，如果需要的话，还可以获取其他城市的最新动态。

先决条件
----

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)
* 已安装并设置 [Nexmo CLI](https://github.com/nexmo/nexmo-cli)
* 可公开访问的 Web 服务器，以便 Vonage 能够向您的应用发出 Webhook 请求。有关 Webhook 的更多信息，请参阅我们的 [Webhook 指南](/concepts/guides/webhooks)，其中包含有关如何[使用 ngrok 公开本地 Web 服务器](/tools/ngrok)的信息
* 对 Ruby 和 [Sinatra](http://www.sinatrarb.com/) Web 框架有一定了解

⚓ 创建语音应用程序
⚓ 购买电话号码
⚓ 将电话号码链接到 Vonage 应用程序

入门
---

我们将从注册两个与此应用程序一起使用的 Vonage 号码开始。我们需要两个号码，以便演示如何使用不同的号码链接到不同的位置。请按照[应用程序入门](https://developer.nexmo.com/concepts/guides/applications#getting-started-with-applications)的说明进行操作。它将引导您完成购买号码、创建应用程序以及链接两者的过程（购买和链接两次，每个号码一次）。

配置应用程序时，您需要提供可公开访问的 Web 服务器或 ngrok 端点的 `answer_url`，在本项目中应为 `[YOUR_URL]/answer`。例如，如果您的 ngrok URL 为 `https://25b8c071.ngrok.io`，则 `answer_url` 将为 `https://25b8c071.ngrok.io/answer`

创建应用程序时，您将获得用于身份验证的密钥。将其保存到名为 `app.key` 的文件中，并妥善保管！您稍后需要用它拨打呼出电话。

创建、配置应用程序并将其链接到电话号码后，看看代码，然后去试一试。

⚓ 创建 Web 服务器

设置并运行应用程序代码
-----------

从 [https://github.com/Nexmo/800-replacement](https://github.com/Nexmo/800-replacement) 克隆或下载此应用程序的代码。

获取代码后，您需要：

* 运行 `bundle install` 以获取依赖项
* 将 `.env.example` 复制到 `.env`，并使用您自己的配置设置（包括您购买并链接到应用程序的两个号码）编辑这个新文件
* 使用以下命令启动应用 `ruby app.rb`

接收呼入电话
------

每当有人拨打链接到 Vonage 应用程序的某个号码时，Vonage 都会收到呼入电话。然后，Vonage 会将该呼叫通知给您的 Web 应用程序。它通过向 Web 应用的 `answer_url` 端点发出 Webhook 请求来完成此操作。您可以在开发人员文档中阅读有关[应答 Webhook](/voice/voice-api/webhook-reference#answer-webhook) 的更多信息。

用户将拨打城市特定的号码，因此我们需要知道哪个号码映射到哪个城市。在我们的简化案例中，我们将您购买的两个号码简单地配置到应用程序中，但在大多数实际环境中，此关系存储在数据库中。此配置可以在 `app.rb` 中找到：

```ruby
# Map our inbound numbers to different cities.
# In a production system this would most likely
# be queried from your database.
locations = {
  ENV['INBOUND_NUMBER_1'] => 'Chicago',
  ENV['INBOUND_NUMBER_2'] => 'San Francisco',
}

# The current statuses for the transport in the
# different cities.
statuses = {
  'Chicago'       => 'There are minor delays on the L Line. There are no further delays.',
  'San Francisco' => 'There are currently no delays',
  # An extra city that does not have its own local
  # number yet
  'Austin'        => 'There are currently no delays'
}
```

现在，我们可以处理呼入电话，提取拨打的号码，并以用户所在城市的当前交通状况回复用户。这些状况信息将以文本转语音消息的形式传递给用户。

> 急性子的人此时可能已经拨打 Vonage 号码，听应用程序的实际回复了 :)

我们先前设置的 `answer_url` 是拨打电话时将使用的路由。您可以在 `app.rb` 中找到以下代码：

```ruby
get '/answer' do
  # We map the number dialled to a location
  location = locations[params['to']]
  # We map the location to the current status
  status = statuses[location]
  # respond to the user
  respond_with(location, status)
end
```

此代码接听电话，检查呼入的电话号码，并获取与该地理号码相关的交通状况。然后，它调用负责构建 [Nexmo 呼叫控制对象 (NCCO)](/voice/guides/ncco) 的 `respond_with()` 函数。这些对象告诉 Vonage 应该向主叫方播放哪些文本转语音消息，以及应该执行哪些其他操作，例如接受号码输入。

```ruby
# This method is shared between both endpoints to play
# back the status and then ask for more input
def respond_with(location, status)
  content_type :json
  return [
    # A friendly localized welcome message
    {
      'action': 'talk',
      'text': "Current status for the #{location} Transport Authority:"
    },
    # The current transport status for this city
    {
      'action': 'talk',
      'text': status
    },
    # Next, we give the user the option to get the details for other cities as well
    {
      'action': 'talk',
      'text': 'For more info, press 1 for Chicago, 2 for San Francisco, and 3 for Austin. Or hang up to end your call.',
      'bargeIn': true
    },
    # Listen to a user's input play back that city's status
    {
      'action': 'input',
      'eventUrl': ["#{ENV['DOMAIN']}/city"],
      # we give the user a bit more time before we hang up on them
      'timeOut': 10,
      # we only expect one digit
      'maxDigits': 1
    }
  ].to_json
end
```

> *注意* ：有关其他可用操作的信息，请参阅 [NCCO 参考](/voice/guides/ncco-reference)。

拨打 Vonage 号码，确保应用程序在一个号码上播放芝加哥的（虚构）交通状况，在另一个号码上播放旧金山的交通状况，并在之后使用 `input` NCCO 操作提供多个选项。

其他地区的提示
-------

我们可以向任何主叫方提供任何城市的信息，但是，如果他们没有拨打与其所需位置相关的号码，如您在上面看到的那样，我们需要请他们输入。让我们更详细地看一下输入操作：

    {
        'action': 'input',
        'eventUrl': ["#{ENV['DOMAIN']}/city"],
        # we give the user a bit more time before we hang up on them
        'timeOut': 10,
        # we only expect one digit
        'maxDigits': 1
    }

输入将呼叫置于监听模式。该特定输入块上的配置只需要一位数，但您也可以接受多位数并以 `#` 号或其他符号结束。此处的代码还设置了 `eventUrl`：这是包含输入数据的 Webhook 将被发送到的位置。在本案例中，应用程序上的 `/city` 端点将接收数据。

```ruby
# This endpoint is called when the user has typed
# a number on their phone to choose a city
post '/city' do
  # We parse the JSON in the request body
  body = JSON.parse(request.body.read)
  # We extract the user's selection, and turn it into a number
  selection = body['dtmf'].to_i
  # We then select the city name and its status from the list
  location = statuses.keys[selection-1]
  status = statuses[location]
  # Finally, we respond to the user in the same way we have done before
  respond_with(location, status)
end
```

> *提示* ：可以跟踪在电话菜单中所做的所有选择，以衡量有关应用程序中用户行为和需求的宝贵数据

按下的按钮将到达传入该 `/city` URL 的 Webhook 的 `dtmf` 字段。有关 Webhook 有效负载的更多信息，请查看更详细的 [Webhook 文档](/voice/voice-api/webhook-reference#input)。

确定了用户请求哪个城市的数据后，您就可以从与之前相同的配置中查找城市及其交通状况，然后重新使用 `respond_with()` 函数返回 NCCO。

结语
---

您创建了语音应用程序，购买了电话号码并将其链接到 Vonage 语音应用程序。然后，您构建了一个应用程序，用来接收呼入电话，将被叫号码映射到标准输入，然后从用户处收集更多输入，以向他们播放更多信息。

⚓ 资源

接下来做什么？
-------

* [GitHub 上的代码](https://github.com/Nexmo/800-replacement)- 此应用程序中的所有代码
* [为呼入电话添加呼叫耳语](https://developer.nexmo.com/tutorials/add-a-call-whisper-to-an-inbound-call) - 如何在接通电话前播报来电者的详细信息
* [呼入电话跟踪](https://www.nexmo.com/blog/2017/08/03/inbound-voice-call-campaign-tracking-dr/) - 关于跟踪哪些入站营销活动效果最佳的博客文章
* [语音 API 参考](/api/voice) - 有关语音 API 的详细 API 文档
* [NCCO 参考](/voice/guides/ncco-reference) - 有关 Webhook 的详细文档

