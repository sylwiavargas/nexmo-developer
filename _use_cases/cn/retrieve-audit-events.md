---
title:  检索审计事件

products: audit

description:  “您可以检索过滤后的审计事件列表。审计事件将活动记录在 Vonage 帐户中。”

languages:
  - Curl


---

检索审计事件
======

您可以检索与 Vonage 帐户关联的所有审计事件的记录。也可以根据日期、关键字、用户和事件类型过滤此列表。

教程内容
----

您将了解如何检索过滤后的审计事件列表：

* [先决条件](#prerequisites)
* [检索审计事件列表](#retrieve-a-list-of-audit-events)
* [检索过滤后的审计事件列表](#retrieve-a-filtered-list-of-audit-events)
* [检索特定审计事件](#retrieve-a-specific-audit-event)
* [结语](#conclusion)
* [资源](#resources)

先决条件
----

为了完成本教程，您需要：

* [Vonage 帐户](https://dashboard.nexmo.com/sign-up)。
* 运行终端应用程序，您可以在其中键入或粘贴 Curl 命令。或者，您可以使用 Paw、Postman 或类似的应用程序。
* 您需要知道可以从 [Dashboard](https://dashboard.nexmo.com/sign-in) 获取的 `VONAGE_API_KEY` 和 `VONAGE_API_SECRET`。

您也可以参考[审计 API 文档](/audit/overview)。

> **注意：** 在下面的示例中，请将 `VONAGE_API_KEY` 和 `VONAGE_API_SECRET` 替换为从 [Dashboard](https://dashboard.nexmo.com) 获取的实际值。

检索审计事件列表
--------

要收到所有审计事件的列表，请在终端输入以下命令：

```bash
$ curl "https://api.nexmo.com/beta/audit/events" \
     -u 'VONAGE_API_KEY:VONAGE_API_SECRET'
```

运行此命令时，您将收到所有审计事件的列表。

检索过滤后的审计事件列表
------------

您在上一步中收到的审计事件列表可能会相当长，尤其是在您已经使用 Vonage 帐户一段时间的情况下。您可以根据几个参数过滤此列表：

|     查询参数      |                                                        描述                                                         |
|---------------|-------------------------------------------------------------------------------------------------------------------|
| `event_type`  | 审计事件的类型，例如：`APP_CREATE`、`NUMBER_ASSIGN` 等。您可以在此处指定以逗号分隔的[事件类型](/audit/concepts/audit-events#audit-event-types)列表。 |
| `search_text` | JSON 兼容的搜索字符串。在审计事件中查找特定文本。                                                                                       |
| `date_from`   | 检索从此日期（采用 ISO-8601 格式）开始的审计事件。                                                                                  |
| `date_to`     | 检索到此日期（采用 ISO-8601 格式）为止的审计事件。                                                                                  |
| `page`        | 从第 1 页开始的页码。                                                                                                      |
| `size`        | 每页的元素数（1 到 100 之间，默认为 30）。                                                                                        |

例如，要基于日期进行过滤，可以输入以下命令：

    $ curl "https://api.nexmo.com/beta/audit/events?date_from=2018-08-01&date_to=2018-08-31" \
         -u 'VONAGE_API_KEY:VONAGE_API_SECRET'

这将返回 2018 年 8 月发生的所有审计事件。

您可以通过各种方式进一步缩小范围。例如，您还可以根据[审计事件类型](/audit/concepts/audit-events#audit-event-types)进行过滤。

例如，要查找 8 月发生的类型为 `NUMBER_ASSIGN` 的审计事件，可以输入以下命令：

    $  curl "https://api.nexmo.com/beta/audit/events?date_from=2018-08-01&date_to=2018-08-31&event_type=NUMBER_ASSIGN" \
         -u 'VONAGE_API_KEY:VONAGE_API_SECRET'

您可以基于 `search_text` 进一步过滤。例如，要查找包含文本“password”的所有审计事件，可以输入以下命令：

    $  curl "https://api.nexmo.com/beta/audit/events?search_text=password" \
         -u 'VONAGE_API_KEY:VONAGE_API_SECRET'

检索特定审计事件
--------

如果您知道特定审计事件的 UUID，则可以仅检索该审计事件对象的信息。例如，如果事件 UUID 为 `aaaaaaaa-bbbb-cccc-dddd-0123456789ab`，则输入：

    $ curl "https://api.nexmo.com/beta/audit/events/aaaaaaaa-bbbb-cccc-dddd-0123456789ab" \
         -u 'VONAGE_API_KEY:VONAGE_API_SECRET'

这会为指定的审计事件返回审计事件对象 JSON。

结语
---

借助审计 API 的过滤功能，您可以完全控制您所检索的审计事件。

资源
---

* [审计 API 文档](/audit/overview)
* [审计 API 参考](/api/audit)

