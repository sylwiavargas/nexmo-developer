---
title:  使用 Amazon Transcribe 转录通话记录

products: voice/voice-api

description:  “本教程介绍如何使用 Amazon Transcribe API 来转录通过 Vonage 语音 API 录制的电话对话。”

languages:
  - Node


---

使用 Amazon Transcribe 转录通话记录
===========================

在本教程中，您将学习如何录制语音 API 通话并使用 Amazon Transcribe API 进行转录。

![应用程序概述](/images/amazon-transcribe-vapi-tutorial.png "应用程序概述")

先决条件
----

您需要至少两个个人电话号码：

* 一个号码呼叫 [Vonage 号码](/numbers/overview)并发起电话会议。
* Vonage 号码可以呼叫另一个号码，将其加入电话会议。

如果您使用两个以上的号码，也可以将它们添加为电话会议的参与者。请参阅[添加更多主叫方](#adding-more-callers)。

您还需要一个 Vonage 帐户。如果没有，请[在这里注册](https://dashboard.nexmo.com/sign-up)。

安装并配置 Nexmo CLI
---------------

本教程使用 [Nexmo 命令行工具](https://github.com/Nexmo/nexmo-cli)，因此，请确保安装并配置该工具后再继续操作。

在终端提示符下运行以下 `npm` 命令，以安装 CLI 工具：

```sh
npm install -g nexmo-cli
```

使用 `VONAGE_API_KEY` 和 `VONAGE_API_SECRET` 配置 CLI 工具，您将在开发人员 Dashboard 中找到这些信息：

```sh
nexmo setup VONAGE_API_KEY VONAGE_API_SECRET
```

购买 Vonage 号码
------------

如果您还没有 Vonage 号码，请购买一个来接收呼入电话。

1. 列出可购买的号码，并将 `COUNTRY_CODE` 替换为您所在位置的[两个字符的国家/地区代码](https://www.iban.com/country-codes)：

   ```sh
   nexmo number:search COUNTRY_CODE
   ```

2. 购买其中一个号码：

   ```sh
   nexmo number:buy 447700900001
   ```

创建语音 API 应用程序
-------------

使用 CLI 创建一个语音 API 应用程序，该应用程序包含您要构建的应用程序的配置详细信息。这些信息包括：

* 您的 Vonage 虚拟号码
* 以下 [Webhook](/concepts/guides/webhooks) 端点： 
  * **应答 Webhook** ：当您的 Vonage 号码收到呼入电话时，Vonage 向其发出请求的端点
  * **事件 Webhook** ：Vonage 用于向您的应用程序通知呼叫状态变化或错误的端点

> **注意** ：您的 Webhook 必须可以通过公共互联网访问。请考虑使用 [ngrok](https://www.nexmo.com/blog/2017/07/04/local-development-nexmo-ngrok-tunnel-dr/) 进行测试。如果真的使用 `ngrok`，请立即使用 `ngrok http 3000` 在端口 3000 上运行它，以获取 ngrok 提供的临时 URL，并在本教程期间保持运行，以防止 URL 发生变化。

将以下命令中的 `example.com` 替换为您自己的面向公众的 URL 或 `ngrok` 主机名。在应用程序目录的根目录中运行它。此命令将返回应用程序 ID，并将身份验证详细信息下载到名为 `private.key` 的文件中。

```sh
nexmo app:create "Call Transcription" https://example.com/webhooks/answer https://example.com/webhooks/events --keyfile private.key
```

记下应用程序 ID 和 `private.key` 文件的位置。您将在后续步骤中用到它们。

链接 Vonage 号码
------------

运行以下 CLI 命令，以使用应用程序 ID 将语音 API 应用程序与 Vonage 号码链接起来：

```sh
nexmo link:app VONAGE_NUMBER APPLICATION_ID
```

配置 AWS
------

转录操作由 Amazon Transcribe API 执行，该 API 是 [Amazon Web Services (AWS)](https://aws.amazon.com/) 的一部分。要有 AWS 帐户才能使用 Transcribe API。如果您还没有 AWS 帐户，请在下一步中学习如何创建。

您还需要：

* 创建两个新的 [S3](https://aws.amazon.com/s3/) 存储桶，以存储原始通话音频和生成的脚本
* 配置 [CloudWatch 事件](https://docs.aws.amazon.com/AmazonCloudWatch/latest/events/WhatIsCloudWatchEvents.html)。此事件将在转录作业完成后触发无服务器 [Lambda 函数](https://aws.amazon.com/lambda/)。
* 创建并部署 Lambda 函数，以通知您的应用程序脚本可供下载。

### 创建 AWS 帐户

[以管理员用户的身份创建 AWS 帐户](https://docs.aws.amazon.com/transcribe/latest/dg/setting-up-asc.html)。记下您的 AWS 密钥和密码，因为您以后无法找回该密码。

### 安装 AWS CLI

使用[此指南](https://docs.aws.amazon.com/transcribe/latest/dg/setup-asc-awscli.html)安装并配置 AWS CLI。

### 创建 S3 存储桶

使用以下 AWS CLI 命令在您选择的区域（在本示例中为 `us-east-1`）中创建两个新的 S3 存储桶，一个用于原始通话音频，另一个用于生成的脚本。这些存储桶必须在 S3 中具有唯一的名称，因此取名时要有创意！

> **重要说明** ：确保您选择的 `region` [支持](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/) Amazon Transcribe API 和 CloudWatch 事件：

```sh
aws s3 mb s3://your-audio-bucket-name --region us-east-1
aws s3 mb s3://your-transcription-bucket-name --region us-east-1 
```

配置应用程序
------

### 获取代码

本项目的代码[在 GitHub 上](https://github.com/Nexmo/amazon-transcribe-call)。它是使用 [Express](https://expressjs.com/) Web 应用程序框架在 node.js 中编写的。它是一个可行示例，您可以根据自己的要求进行调整。

克隆存储库，或将存储库下载到本地计算机的新目录中。

### 安装依赖项

在应用程序目录中运行 `npm install`，以安装所需的依赖项：

* `aws-sdk`：AWS node.js SDK
* `body-parser`：node.js 正文解析中间件
* `express`：面向 node.js 的 Web 应用程序框架
* `nexmo`：Vonage Server SDK
* `serverless`：用于部署 Lambda 函数
* `shortid`：为通话记录生成随机文件名

### 配置环境变量

将下载的 `private.key` 文件移到应用程序目录的根目录中。

然后，将 `example.env` 复制到 `.env` 并配置以下设置：

设置 | 描述
--|--
`VONAGE_APPLICATION_ID` | 先前创建的 Vonage 语音应用程序 ID
`VONAGE_PRIVATE_KEY_FILE` | 例如：`private.key`
`OTHER_PHONE_NUMBER` | 可以呼叫以创建对话的另一个电话号码
`AWS_KEY` | 您的 AWS 密钥
`AWS_SECRET` | 您的 AWS 密码
`AWS_REGION` | 您的 AWS 区域，例如`us-east-1`
`S3_PATH` | S3 存储桶存储的路径，其中应包括 `AWS_REGION`，例如`https://s3-us-east-1.amazonaws.com`
`S3_AUDIO_BUCKET_NAME` | 将包含原始通话音频文件的 S3 存储桶
`S3_TRANSCRIPTS_BUCKET_NAME` | 将包含通话音频脚本的 S3 存储桶

### 部署 Lambda 函数

AWS Lambda 是一项服务，可通过运行代码来响应事件，并自动管理代码所需的计算资源。它是“无服务器”功能（也称为“功能即服务”(FAAS)）的一个示例。在本教程中，您将使用[无服务器框架](https://serverless.com/)来模板化和部署 Lambda 函数。

首先，确保安装了 `serverless` 节点包：

```sh
serverless -v
```

如果它显示版本号，则表示一切正常。如果没有，请使用 `npm` 安装 `serverless`：

```sh
npm install -g serverless
```

`transcribeReadyService` 文件夹包含用于定义 Lambda 函数的 `handler.js` 文件。当 CloudWatch 收到转录作业完成事件时，此 Lambda 会向 `/webhooks/transcription` 端点发出 `POST` 请求。

更改 `options.host` 属性，以匹配您面向公众的服务器的主机名：

```javascript
const https = require('https');

exports.transcribeJobStateChanged = (event, context) => {

  let body = '';

  const options = {
    host: 'myapp.ngrok.io', // <-- replace this
    path: '/webhooks/transcription',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    }
  };

  const req = https.request(options, (res) => {
    res.on('data', (chunk) => {
      body += chunk;
    });

    context.succeed(body);
  });

  req.write(JSON.stringify(event));
  req.end();
};
```

CloudWatch 事件处理程序在随附的 `serverless.yml` 文件中定义。确保 `provider.region` 与您的 AWS 区域匹配：

```yaml
service: vonage-transcribe

provider:
  name: aws
  runtime: nodejs10.x
  region: us-east-1 # <-- Specify your region

functions:
  transcribeJobStateChanged:
    handler: handler.transcribeJobStateChanged

    events:
      - cloudwatchEvent:
          event:
            source:
              - "aws.transcribe"
            detail-type:
              - "Transcribe Job State Change"
            detail:
              TranscriptionJobStatus:
                - COMPLETED
                - FAILED
```

使用 `serverless` 部署此 Lambda：

```sh
cd transcribeReadyService
serverless deploy
```

> **注意** ：此过程需要几分钟才能完成。如果您需要更新任何内容，后续的部署应该会更快。

检查代码
----

主要应用程序代码在 `index.js` 文件中。

应用程序目录还包含以下子文件夹：

* `recordings`：将包含原始音频通话 mp3 文件，使用 shortid 唯一命名 `shortid`
* `transcripts`：包含完成的脚本，转录作业完成后从 S3 下载
* `transcribeReadyService`：包含 Lambda 函数和 CloudWatch 事件定义 YAML

### 使用 Node Server SDK

`index.js` 中的以下代码可实例化 Node Server SDK，您将在以后使用它来保存通话记录：

```javascript
const Nexmo = require("nexmo")

const nexmo = new Nexmo({
  apiKey: "not_used", // Voice applications don't use API key or secret
  apiSecret: "not_used",
  applicationId: process.env.VONAGE_APPLICATION_ID,
  privateKey: __dirname + "/" + process.env.VONAGE_PRIVATE_KEY_FILE
})
```

### 使用 AWS SDK

以下代码将对 AWS SDK 进行身份验证，并创建新的 `TranscribeService` 和 `S3` 实例：

```javascript
const AWS = require("aws-sdk")

AWS.config.update({
  region: process.env.AWS_REGION,
  accessKeyId: process.env.AWS_KEY,
  secretAccessKey: process.env.AWS_SECRET
})

const transcribeService = new AWS.TranscribeService()
const S3 = new AWS.S3()
```

### 定义应答 Webhook

`/webhooks/answer` 端点使用 [Nexmo 呼叫控制对象 (NCCO)](/voice/voice-api/ncco-reference) 来响应呼入电话，该对象会告诉 Vonage 如何处理该呼叫。

它使用 `connect` 操作来呼叫您的另一个个人号码，使用 `record` 操作来录制通话音频，并指定有两个输入 `channels`。通话完成时，`record` 操作会触发对 `/webhooks/recording` 端点的 `POST` 请求：

```javascript
app.get('/webhooks/answer', (req, res) => {
  return res.json([{
      action: 'talk',
      text: 'Thanks for calling, we will connect you now'
    },
    {
      action: 'connect',
      endpoint: [{
        type: 'phone',
        number: process.env.OTHER_PHONE_NUMBER
      }]
    },
    {
      action: 'record',
      eventUrl: [`${req.protocol}://${req.get('host')}/webhooks/recording`],
      split: 'conversation',
      channels: 2,
      format: 'mp3'
    }
  ])
})
```

### 定义事件 Webhook

`/webhooks/events` 端点记录通话事件（由 Vonage 作为 `POST` 请求提交）并将它们显示在控制台中：

```javascript
app.post('/webhooks/events', (req, res) => {
  console.log(req.body)
  return res.status(204).send("")
})
```

### 保存录音

`/webhooks/recording` 端点将通话记录保存到 `recordings` 文件夹中，并调用 `uploadFile()` 将通话音频上传到 S3：

```javascript
app.post('/webhooks/recording', (req, res) => {

  let audioFileName = `vonage-${shortid.generate()}.mp3`
  let audioFileLocalPath = `./recordings/${audioFileName}`

  nexmo.files.save(req.body.recording_url, audioFileLocalPath, (err, res) => {
    if (err) {
      console.log("Could not save audio file")
      console.error(err)
    }
    else {
      uploadFile(audioFileLocalPath, audioFileName)
    }
  })

  return res.status(204).send("")

})
```

### 将录音上传到 S3

`uploadFile()` 函数将录音实际上传到 S3 并启动转录过程：

```javascript
function uploadFile(localPath, fileName) {

  fs.readFile(localPath, (err, data) => {
    if (err) { throw err }

    const uploadParams = {
      Bucket: process.env.S3_AUDIO_BUCKET_NAME,
      Key: fileName,
      Body: data
    }

    const putObjectPromise = S3.putObject(uploadParams).promise()
    putObjectPromise.then((data) => {
      console.log(`${fileName} uploaded to ${process.env.S3_AUDIO_BUCKET_NAME} bucket`)
      transcribeRecording({
        audioFileUri: process.env.S3_PATH + '/' + process.env.S3_AUDIO_BUCKET_NAME + '/' + fileName,
        transcriptFileName: `transcript-${fileName}`
      })
    })
  })
}
```

### 提交转录作业

`transcribeRecording()` 函数提交音频文件以供 Amazon Transcribe API 转录。

注意，在 `startTranscriptionJob()` 的参数中，`channelIdentification` 设置为 `true`。这将指示 Amazon Transcribe API 分别转录每个渠道。

参数还包括 `OutputBucketName`，用于将完成的脚本存储在指定的 S3 存储桶中。

```javascript
function transcribeRecording(params) {

  const jobParams = {
    LanguageCode: 'en-GB',
    Media: {
      MediaFileUri: params.audioFileUri
    },
    MediaFormat: 'mp3',
    OutputBucketName: process.env.S3_TRANSCRIPTS_BUCKET_NAME,
    Settings: {
      ChannelIdentification: true
    },
    TranscriptionJobName: params.transcriptFileName
  }

  console.log(`Submitting file ${jobParams.Media.MediaFileUri} for transcription...`)

  const startTranscriptionJobPromise = transcribeService.startTranscriptionJob(jobParams).promise()

  startTranscriptionJobPromise.then((data) => {
    console.log(`Started transcription job ${data.TranscriptionJob.TranscriptionJobName}...`)
  })
}
```

### 转录作业完成

当 CloudWatch 得知转录作业已完成时，它会触发我们的 Lambda。Lambda 函数使用转录结果向 `/webhooks/transcription` 端点发出 `POST` 请求：

```javascript
app.post('/webhooks/transcription', (req, res) => {

  const jobname = req.body.detail.TranscriptionJobName
  const jobstatus = req.body.detail.TranscriptionJobStatus

  if (jobstatus === "FAILED") {
    console.log(`Error processing job ${jobname}`)
  } else {
    console.log(`${jobname} job successful`)

    const params = {
      TranscriptionJobName: jobname
    }
    console.log(`Getting transcription job: ${params.TranscriptionJobName}`)

    transcribeService.getTranscriptionJob(params, (err, data) => {
      if (err) {
        console.log(err, err.stack)
      }
      else {
        console.log("Retrieved transcript")
        downloadFile(data.TranscriptionJob.TranscriptionJobName + '.json')
      }
    })
  }
  return res.status(200).send("")
})
```

### 下载完成的脚本

`downloadFile` 函数将完成的脚本文件从 S3 存储桶下载到本地 `transcripts` 文件夹中。我们希望在尝试解析文件内容之前确保文件可用，因此在调用 `displayResults` 函数之前，我们将对 `S3.getObject` 的调用包装在一个承诺中：

```javascript
function downloadFile(key) {
  console.log(`downloading ${key}`)

  const filePath = `./transcripts/${key}`

  const params = {
    Bucket: process.env.S3_TRANSCRIPTS_BUCKET_NAME,
    Key: key
  }

  const getObjectPromise = S3.getObject(params).promise()
  getObjectPromise.then((data) => {
    fs.writeFileSync(filePath, data.Body.toString())
    console.log(`Transcript: ${filePath} has been created.`)
    let transcriptJson = JSON.parse(fs.readFileSync(filePath, 'utf-8'))
    displayResults(transcriptJson)
  })

}
```

### 解析脚本

生成的脚本 JSON 文件具有相当复杂的结构。文件 (`results.transcripts`) 的顶部是整个通话的转录，在 `results.channel_labels` 中，您可以深入查看每个渠道的转录：

```json
{
	"jobName": "transcript-vonage-9Eeor0OhH.mp3",
	"accountId": "99999999999",
	"results": {
		"transcripts": [{
			"transcript": "This is a test on my mobile phone. This is a test on my landline."
		}],
		"channel_labels": {
			"channels": [{
				"channel_label": "ch_0",
				"items": [{
					"start_time": "1.94",
					"end_time": "2.14",
					"alternatives": [{
						"confidence": "1.0000",
						"content": "This"
					}],
					"type": "pronunciation"
				}, {
					"start_time": "2.14",
					"end_time": "2.28",
					"alternatives": [{
						"confidence": "1.0000",
						"content": "is"
					}],
					"type": "pronunciation"
				}, 
        ...
```

下载脚本后调用的 `displayResults()` 函数将检索每个渠道的转录并将其显示在控制台中：

```javascript
function displayResults(transcriptJson) {
  const channels = transcriptJson.results.channel_labels.channels

  channels.forEach((channel) => {
    console.log(`*** Channel: ${channel.channel_label}`)

    let words = ''

    channel.items.forEach((item) => {
      words += item.alternatives[0].content + ' '
    })
    console.log(words)
  })
}
```

试试看
---

### 运行应用程序

1. 通过在应用程序的根目录中运行以下命令来启动应用程序：

   ```sh
   node index.js
   ```

2. 用一部电话拨打 Vonage 号码。当电话被接听时，第二部电话的铃声应响起。接听电话。

3. 对着两个电话听筒各说几句话，然后将其断开。

4. 在控制台中观看正在处理的转录作业。（ **注意** ：这可能需要几分钟）：

```sh
{ end_time: '2019-08-13T11:33:10.000Z',
  uuid: 'df52c28f-d167-5319-a7e6-bc9d9c2b23d2',
  network: 'GB-FIXED',
  duration: '23',
  start_time: '2019-08-13T11:32:47.000Z',
  rate: '0.01200000',
  price: '0.00460000',
  from: '447700900002',
  to: '447700900001',
  conversation_uuid: 'CON-e01f1887-8a7e-4c6d-82ef-fd9280190e01',
  status: 'completed',
  direction: 'outbound',
  timestamp: '2019-08-13T11:33:09.380Z' }
recording...
{ start_time: '2019-08-13T11:32:47Z',
  recording_url:
   'https://api.nexmo.com/v1/files/d768cbb4-d68c-4ad0-8984-8222d2ccb6c5',
  size: 178830,
  recording_uuid: '01175e1e-f778-4b2a-aa7e-18b6fb493edf',
  end_time: '2019-08-13T11:33:10Z',
  conversation_uuid: 'CON-e01f1887-8e7e-4c6d-82ef-fd8950190e01',
  timestamp: '2019-08-13T11:33:10.449Z' }
vonage-srWr3XOmP.mp3 uploaded to vonage-transcription-audio bucket
Submitting file https://s3-us-east-1.amazonaws.com/vonage-transcription-audio/vonage-srWr3XOmP.mp3 for transcription...
Started transcription job transcript-vonage-srWr3XOmP.mp3...
transcript-vonage-srWr3XOmP.mp3 job successful
Getting transcription job: transcript-vonage-srWr3XOmP.mp3
Retrieved transcript
downloading transcript-vonage-srWr3XOmP.mp3.json
Transcript: ./transcripts/transcript-vonage-srWr3XOmP.mp3.json has been created.
*** Channel: ch_0
Hello this is channel zero .
*** Channel: ch_1
Hello back this is channel one . 
```

### 添加更多主叫方

如果您有两个以上的号码，则可以将更多主叫方添加到对话中。只需在 `/webhooks/answer` NCCO 中为每个主叫方创建一个 `connect` 操作，并相应地增加 `record` 操作中的渠道数。

延伸阅读
----

以下资源将帮助您了解更多信息：

* 语音 API 
  * [语音 API 通话录音指南](/voice/voice-api/guides/recording)
  * [“录制通话”代码片段](/voice/voice-api/code-snippets/record-a-call)
  * [语音 API 参考](/api/voice)
  * [NCCO 参考](/voice/voice-api/ncco-reference)

* AWS 
  * [AWS node.js SDK 参考](https://aws.amazon.com/sdk-for-node-js/)
  * [Amazon Transcribe API 功能](https://aws.amazon.com/transcribe/)
  * [Amazon Transcribe API 参考](https://docs.aws.amazon.com/transcribe/latest/dg/API_Reference.html)
  * [Amazon S3 文档](https://docs.aws.amazon.com/s3/)
  * [Amazon CloudWatch 文档](https://docs.aws.amazon.com/cloudwatch/)
  * [Amazon Lambda](https://docs.aws.amazon.com/lambda/)

