---
title:  使用子帐户 API

products: account/subaccounts

description:  本主题提供了一个案例研究，向您展示如何开始使用子帐户 API。

languages:
  - Curl


---

使用子帐户 API
=========

概述
---

本主题描述了一个用例，在该用例中，合作伙伴使用子帐户 API 成功管理最终客户。

先决条件
----

您应该熟悉与子帐户 API 相关的[主要概念](/account/subaccounts/overview)。

创建子帐户
-----

合作伙伴决定为每个最终客户创建一个子帐户，以便能够为每个最终客户使用不同的 API 凭据，并查看他们的支出。下图对此进行了说明：

![具有共享余额的子帐户](/images/subaccounts/shared_balance.png)

要创建子帐户，可以使用以下代码：

```code_snippets
source: '_examples/subaccounts/create-subaccount'
```

转移额度
----

合作伙伴无法控制其最终客户的支出，因为他们都共享相同的余额。一个最终客户曾经偶尔消耗掉所有共享余额，有效地阻止了合作伙伴的其他最终客户访问 Vonage API。合作伙伴决定设置个人余额并为该最终客户分配信用额度。

> **注意：** 合作伙伴本可以为其帐户预付款。

可以为每个子帐户分配个人余额和信用额度，如下图所示：

![额度分配](/images/subaccounts/credit_allocation.png)

以下代码片段说明了如何向子帐户分配指定的额度：

```code_snippets
source: '_examples/subaccounts/transfer-credit'
```

检查所有子帐户的余额
----------

合作伙伴决定进行监控。可以使用以下代码片段定期检查所有子帐户的余额：

```code_snippets
source: '_examples/subaccounts/get-subaccounts'
```

更多额度分配
------

一段时间后，合作伙伴发现最终客户 1 (subaccount1) 用完了自己的所有额度（共 40），无法再进行任何 API 调用。合作伙伴可以选择要么等待最终客户 1 支付调用费用（转而向 Vonage 付款，并将相应的余额转入子帐户），要么立即提高最终客户的信用额度，以便最终客户 1 可以继续使用 Vonage API。合作伙伴决定分配更多额度。合作伙伴有 40 = |-60| - |-20| 可用额度，并决定向该子帐户分配 20。下图对此进行了说明：

![更多额度](/images/subaccounts/additional_credit_allocation.png)

月底余额结转
------

月底，合作伙伴收到了来自 Vonage 的 |-20| \+ |-50| = 70 欧元发票（用于支付其所有帐户的所有支出）。最终客户 1 (subaccount1) 支付了其消费的 50 欧元中的 45 欧元。因此，合作伙伴将 45 欧元转入了 subaccount1 的余额。下图对此进行了说明：

![更多额度](/images/subaccounts/month_end_balance_transfer.png)

以下代码显示了如何将余额转入子帐户：

```code_snippets
source: '_examples/subaccounts/transfer-balance'
```

暂停子帐户
-----

合作伙伴喜欢这种控制子帐户支出的功能，并决定为最终客户 2 (subaccount2) 分配个人余额和 30 欧元的额度。合作伙伴在监控其子帐户的支出时，发现 subaccount2 消耗了 25 欧元的余额。由于对 subaccount2 的消耗速度感到震惊，合作伙伴决定暂停 subaccount2。暂停子帐户的代码如下所示：

```code_snippets
source: '_examples/subaccounts/suspend-subaccount'
```

重新激活子帐户
-------

与 subaccount2 讨论后，合作伙伴决定重新激活 subaccount2 的帐户。这可以通过以下代码来实现：

```code_snippets
source: '_examples/subaccounts/reactivate-subaccount'
```

摘要
---

在本主题中，您已经了解了如何在典型场景下使用子帐户 API 来管理最终客户。

更多资源
----

* [概念](/account/subaccounts/overview)
* [代码片段](/account/subaccounts/code-snippets/create-subaccount)
* [API 参考](/api/subaccounts)

