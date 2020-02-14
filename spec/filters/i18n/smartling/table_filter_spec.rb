require 'rails_helper'

RSpec.describe I18n::Smartling::TableFilter do
  context 'with spaces after the delimiter' do
    let(:table) do
      <<~TABLE
        选项 | 说明 | 必填
        -- | -- | --
        | `format` | 以特定的格式对通话进行录音。选项如下：

        * `mp3`
        * `wav`
        * `ogg`

        录制超过两个信道时，默认值为 `mp3` 或 `wav`。| 否 | `eventMethod` | 用于向 `eventUrl` 发出请求的 HTTP 方法。默认值为 `POST`。| 否 |

        <a id="recording_return_parameters"></a>
        以下示例显示了发送到 `eventUrl` 的返回参数：
      TABLE
    end

    it 'parses the table correctly' do
      processed = described_class.call(table)

      expect(processed).to eq(
        <<~TABLE
          选项 | 说明 | 必填
          -- | -- | --
          | `format` | 以特定的格式对通话进行录音。选项如下：</br> `mp3`</br> `wav`</br> `ogg`</br>录制超过两个信道时，默认值为 `mp3` 或 `wav`。| 否 |
          | `eventMethod` | 用于向 `eventUrl` 发出请求的 HTTP 方法。默认值为 `POST`。| 否 |

          <a id="recording_return_parameters"></a>
          以下示例显示了发送到 `eventUrl` 的返回参数：
        TABLE
      )
    end
  end

  context 'without spaces after the delimiter' do
    let(:table) do
      <<~TABLE
        | 选项 | 说明 | 必填 |
        | -- | -- | -- |
        |`format` | 以特定的格式对通话进行录音。选项如下：

        * `mp3`
        * `wav`
        * `ogg`

        录制超过两个信道时，默认值为 `mp3` 或 `wav`。| 否|
        |`eventMethod` | 用于向 `eventUrl` 发出请求的 HTTP 方法。默认值为 `POST`。| 否|

        <a id="recording_return_parameters"></a>
        以下示例显示了发送到 `eventUrl` 的返回参数：
      TABLE
    end

    it 'parses the table correctly' do
      processed = described_class.call(table)

      expect(processed).to eq(
        <<~TABLE
          | 选项 | 说明 | 必填 |
          | -- | -- | -- |
          |`format` | 以特定的格式对通话进行录音。选项如下：</br> `mp3`</br> `wav`</br> `ogg`</br>录制超过两个信道时，默认值为 `mp3` 或 `wav`。| 否|
          |`eventMethod` | 用于向 `eventUrl` 发出请求的 HTTP 方法。默认值为 `POST`。| 否|

          <a id="recording_return_parameters"></a>
          以下示例显示了发送到 `eventUrl` 的返回参数：
        TABLE
      )
    end
  end

  context 'without list' do
    let(:table) do
      <<~TABLE
        操作 | 说明 | 同步
        -- | -- | --
        | [录音](#record) | 全部或部分通话 | 否 |
        | [对话](#conversation) | 创建或加入现有的[对话](/conversation/concepts/conversation) | 是 |
        | [连接](#connect) | 到可连接的端点，例如电话号码或 VBC 分机。| 是 |
        | [通话](#talk) | 将合成语音发送到对话。| 是，除非 *bargeIn=true* |
        | [流式](#stream) | 将音频文件发送到对话。| 是，除非 *bargeIn=true* |
        | [输入](#input) | 收集来自被呼叫者的数字。| 是 |
        | [通知](#notify) | 向您的应用程序发送请求，以便通过 NCCO 跟踪进度 | 是 |

        > **注意** ：[连接呼入电话](/voice/voice-api/code-snippets/connect-an-inbound-call)提供了在启动呼叫或会议后如何为 Nexmo 提供 NCCO 服务的示例

        录音
        ---

        使用`record`操作对通话或部分通话进行录音：

      TABLE
    end

    it 'parses the table correctly' do
      processed = described_class.call(table)

      expect(processed).to eq(table)
    end
  end
end
