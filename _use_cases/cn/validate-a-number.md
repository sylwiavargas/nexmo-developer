---
title:  验证号码

products: number-insight

description:  使用 Ruby 代码中的 Number Insight 和开发人员 API 来验证、清理号码以及确定向其拨打电话或发送短信的费用。

languages:
  - Ruby


---

验证号码
====

Number Insight API 可帮助您验证客户提供的号码以防止欺诈，并确保您以后可以再次联系该客户。它还为您提供其他有用的信息，例如如何设置号码格式，以及号码是手机号码还是座机号码。

Number Insight API 具有三个产品级别：

* Basic API：确定号码所属的国家/地区，并利用该信息正确设置号码的格式。
* Standard API：确定电话号码是座机号码还是手机号码（以选择语音联系或短信联系）并屏蔽虚拟号码。
* Advanced API：计算与号码相关的风险。

> 了解有关 [Basic、Standard 和 Advanced API](/number-insight/overview#basic-standard-and-advanced-apis) 的更多信息。
> **注意** ：对 Number Insight Basic API 的请求免费。其他 API 级别会产生费用。有关更多信息，请参阅 [API 参考](/api/number-insight)。

借助 [Ruby Server SDK](http://github.com/nexmo/nexmo-ruby)，不仅可以轻松访问 Number Insight API，还能够使用其他 API，例如定价 API。这意味着，除了验证和清理电话号码外，您还可以确认向其发送短信和进行语音通话的费用，正如我们在本教程的[计算费用](#calculate-the-cost)部分所演示的那样。

教程内容
----

您将学习如何使用 Ruby Server SDK 清理和验证电话号码。

* [在开始之前](#before-you-begin)，请确保您具有完成本教程所需的一切
* 通过克隆 GitHub 上的教程源代码并使用 Vonage 帐户详细信息进行配置来[创建项目](#create-the-project)
* [安装依赖项](#install-the-dependencies)，其中包括 Ruby Server SDK
* [代码演练](#code-walkthrough)，了解代码的工作原理

准备阶段
----

要完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)的 `api_key` 和 `api_secret` - 如果您还没有帐户，请注册一个
* 访问 GitHub 上的[教程源代码](https://github.com/Nexmo/ruby-ni-customer-number-validation)

创建项目
----

克隆[教程源代码](https://github.com/Nexmo/ruby-ni-customer-number-validation)存储库：

    git clone git@github.com:Nexmo/ruby-ni-customer-number-validation.git

切换到项目文件夹：

    cd ruby-ni-customer-number-validation

将 `.env-example` 文件复制到 `.env` 并编辑 `.env`，以配置 [Dashboard](https://dashboard.nexmo.com) 中的 API 密钥和密码：

    VONAGE_API_KEY="(Your API key)"
    VONAGE_API_SECRET="(Your API secret)"

安装依赖项
-----

运行 `bundle install` 以安装项目的依赖项。

```ruby
$ bundle install
Fetching gem metadata from https://rubygems.org/...
Resolving dependencies...
Using bundler 1.16.4
Using dotenv 2.1.1
Using jwt 2.1.0
Using nexmo 5.4.0
Bundle complete! 2 Gemfile dependencies, 4 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.
```

代码演练
----

本教程项目不是应用程序，而是介绍如何使用 Number Insight API 的一系列代码片段。在本演练中，您将依次执行每个代码片段并了解其工作原理。

### 确定国家/地区

本示例使用 Number Insight Basic API 找出号码所属的国家/地区。

#### 运行代码

执行 `snippets/1_country_code.rb` ruby 文件：

    $ ruby snippets/1_country_code.rb

此命令将以国际格式返回电话号码以及号码注册地的名称、代码和前缀。

```ruby
{
    "status" => 0,
    "status_message" => "Success",
    "request_id" => "923c7054-3201-4146-b6df-23bfe929cd03",
    "international_format_number" => "442079460000",
    "national_format_number" => "020 7946 0000",
    "country_code" => "GB",
    "country_code_iso3" => "GBR",
    "country_name" => "United Kingdom",
    "country_prefix" => "44"
}
```

#### 工作原理

首先，该代码使用您在 `.env` 文件中配置的 API 密钥和密码创建 `nexmo` 客户端对象：

```ruby
require 'nexmo'
nexmo = Nexmo::Client.new(
  api_key: ENV['VONAGE_API_KEY'],
  api_secret: ENV['VONAGE_API_SECRET']
)
```

然后，它调用 Number Insight Basic API，并传入要提供相关见解的 `number`：

```ruby
puts nexmo.number_insight.basic(number:  "442079460000")
```

### 清理号码

您的用户提供的电话号码可能不是国际格式。也就是说，它不包含国家/地区前缀。本示例介绍如何使用 Number Insight Basic API 正确设置号码格式。

> 大多数 Vonage API 都希望电话号码采用国际格式，因此您可以在使用号码之前通过 Number Insight Basic API 清理号码。

#### 运行代码

执行 `snippets/2_cleanup.rb` ruby 文件：

    $ ruby snippets/2_cleanup.rb

此命令将返回以国际格式提供且前缀为 `44` 的本地号码（`020 3198 0560`，英国 (`GB`) 号码）：

    "442031980560"

#### 工作原理

要检索国际格式的电话号码，请使用本地格式的电话号码和国家/地区代码调用 Number Insight Basic API：

```ruby
insight = nexmo.number_insight.basic(
  number:  "020 3198 0560",
  country: 'GB'
)

p insight.international_format_number
```

### 确定号码类型（座机号码或手机号码）

Number Insight Standard API 比 Basic API 提供更多关于电话号码的信息，并包含 Basic API 提供的所有数据。它最有用的功能之一是告诉您正在处理的号码的 *类型* ，以便您确定联系该号码的最佳方式。

#### 运行代码

执行 `snippets/3_channels.rb` ruby 文件：

    $ ruby snippets/3_channels.rb

您会看到此电话号码已分配给英国座机，因此使用语音比使用短信更好：

```ruby
{
    "network_code" => "GB-FIXED",
            "name" => "United Kingdom Landline",
         "country" => "GB",
    "network_type" => "landline"
}
```

#### 工作原理

要确定号码类型，请调用 Number Insight Standard API，并如此处所示，传入本地号码和国家/地区代码：

```ruby
insight = nexmo.number_insight.standard(
  number:  "020 3198 0560",
  country: 'GB'
)
```

您也可以传递国际格式的 `number`，而无需指定 `country`：

```ruby
insight = nexmo.number_insight.standard(
  number:  "442031980560"
)
```

然后，我们可以找到当前的运营商信息，并用它来显示号码类型（手机或座机）：

```ruby
p insight.current_carrier
```

### 计算费用

您可以结合使用 Number Insight API 和[定价](/api/developer/pricing) API 来确定号码所在的网络，以及拨打该号码或向其发送短信的费用。

#### 运行代码

执行 `snippets/4_cost.rb` ruby 文件：

    $ ruby snippets/4_cost.rb

响应指示了发送短信的费用或与该电话号码进行语音通话的每分钟价格：

```ruby
{
      :sms => [{
                "type" => "landline",
               "price" => "0.03330000",
            "currency" => "EUR",
              "ranges" => [441, 442, 443],
        "network_code" => "GB-FIXED",
        "network_name" => "United Kingdom Landline"}],
    :voice => [{
               "type" => "landline",
              "price" => "0.01200000",
           "currency" => "EUR",
             "ranges" => [441, 442, 443],
       "network_code" => "GB-FIXED",
       "network_name" => "United Kingdom Landline"}]
}
```

此输出显示该号码是座机号码，因此最适合进行语音通话，费用为每分钟 0\.12 欧元。

#### 工作原理

该代码首先调用 Number Insight Standard API，后者提供有关该号码当前注册的网络以及原籍国（Basic API 中也有此功能）的信息：

```ruby
insight = nexmo.number_insight.standard(
  number:  '020 3198 0560',
  country: 'GB'
)

# Store the network and country codes
current_network = insight.current_carrier.network_code
current_country = insight.country_code
```

然后，它使用[定价](/api/developer/pricing) API 检索该国家/地区所有运营商的通话和短信费用：

```ruby
# Fetch the voice and SMS pricing data for the country
sms_pricing = nexmo.pricing.sms.get(current_country)
voice_pricing = nexmo.pricing.voice.get(current_country)
```

在 Ruby REST Client API 中检索定价数据的其他选项包括：

* `nexmo.pricing.sms.list()` 或 `nexmo.pricing.voice.list()` - 检索 *所有* 国家/地区的定价数据
* `nexmo.pricing.sms.prefix(prefix)` 或 `nexmo.pricing.voice.prefix(prefix)` - 检索特定国际前缀代码的定价数据，例如 `44` 代表英国。

然后，该代码查找该号码所属的特定网络的费用并显示该信息：

```ruby
# Retrieve the network cost from the pricing data
sms_cost = sms_pricing.networks.select{|network| network.network_code == current_network}
voice_cost = voice_pricing.networks.select{|network| network.network_code == current_network}

p({
  sms: sms_cost,
  voice: voice_cost
})
```

### 验证手机号码

使用 Number Insight Advanced API 可以验证号码，以确定它是否有可能是真实号码以及与客户联系的可靠方式。对于手机号码，您还可以发现该号码是否处于活动状态，是否正在漫游，能否接通，以及是否与其 IP 地址位于同一位置。Advanced API 包含 Basic 和 Standard API 中的所有信息。

#### 运行代码

执行 `snippets/5_validation.rb` ruby 文件：

    $ ruby snippets/5_validation.rb

在本案例中，响应指示号码 `valid`。

```ruby
"valid"
```

如果您从电话号码中删除几位数并重新运行程序，则 Number Insight Advanced API 将报告该号码 `not_valid`。

```ruby
"not_valid"
```

如果 Number Insight Advanced API 无法确定号码是否有效，您将收到响应 `unknown`：

```ruby
"unknown"
```

#### 工作原理

该代码像之前一样请求号码的国际表示形式，但使用 Basic API 提供、Advanced API 也包含的功能：

```ruby
insight = nexmo.number_insight.advanced(
  number:  "020 3198 0560",
  country: 'GB'
)
```

它也从响应中返回并显示 `valid_number` 字段。该字段的值为 `valid`、`not_valid` 或 `unknown` 之一。

```ruby
p insight.valid_number
```

结语
---

在本教程中，您学习了如何验证和确定号码的国际格式，以及如何计算向其拨打电话或发送短信的费用。

资源和延伸阅读
-------

* 查看我们的 [Number Insight 指南](/number-insight)，了解您可以使用 Number Insight 执行的更多操作。
* 阅读有关 Number Insight 的[博客文章](https://www.nexmo.com/?s=number+insight)。
* 访问 [Number Insight API 参考](/api/number-insight)，以获取有关每个端点的详细文档。

