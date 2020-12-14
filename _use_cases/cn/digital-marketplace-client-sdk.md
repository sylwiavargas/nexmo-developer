---
title:  数字市场

products: client-sdk

description:  如何构建您自己的数字市场应用程序。

languages:
    - Node


---

数字市场
====

在本用例中，您将学习如何构建数字市场。[在这里观看实际效果](https://green-crowberry.glitch.me/)。

示例应用程序是使用以下工具和技术构建的：

* Vonage Client SDK
* 用于前端的 React
* 用于后端的 Node JS/Express

在本用例中，您使用 Client SDK 中的自定义事件。此处使用自定义事件来提醒您在以下情况中的应用程序：

* 用户列出新的待售商品
* 客户使用 Stripe 购买商品

先决条件
----

假定您已完成以下操作：

1. 创建了一个 [Vonage 帐户](https://dashboard.nexmo.com/sign-up)。
2. 记录了 [Dashboard](https://dashboard.nexmo.com/getting-started-guide) 中显示的 Vonage API 密钥和 API 密码。

步骤
---

本用例中的主要步骤如下：

1. [创建 Vonage 应用程序](#create-a-nexmo-application)
2. [对应用程序进行身份验证](#authenticate-your-application)
3. [配置应用程序](#configure-your-application)
4. [代码演练](#code-walkthrough)

创建 Vonage 应用程序
--------------

您可以在 Dashboard 中创建 Vonage 应用程序。可以通过以下步骤来实现：

1. 在 Dashboard 中，转到[您的应用程序](https://dashboard.nexmo.com/applications)。
2. 点击 **新建应用程序** 。
3. 输入您的应用程序的名称，例如 **Client SDK 市场应用** 。
4. 在 **身份验证** 部分中，点击 **生成公钥和私钥** 。这将生成一个公钥/私钥对。私钥文件将下载到您的计算机中。您稍后将使用此文件。
5. 在 **功能** 部分中，选择 RTC。
6. 对于 RTC 功能，可以输入 `https://example.com/event` 的事件 URL。
7. 点击 **生成新应用程序** 。
8. 记下生成的应用程序 ID。

现在，您已经使用 Dashboard 创建了 Vonage 应用程序。

此时最重要的是私钥文件和应用程序 ID。您在以下章节需要用到它们。

代码存储库
-----

如果您想使用现有代码来构建自己的项目版本，以进行试验，则可以执行以下操作之一：

* [重新混合 Glitch 项目](https://glitch.com/edit/#!/remix/green-crowberry)
* [克隆 GitHub 存储库](https://github.com/nexmo-community/client-sdk-marketplace-use-case)

对应用程序进行身份验证
-----------

您需要使用[先前生成](#create-a-nexmo-application)的私钥文件对应用程序进行身份验证。

### 使用 Glitch

在文本编辑器中打开 `private.key` 文件。然后，在 Glitch 项目中创建文件 `/.data/private.key`，复制并粘贴 `private.key` 的内容：

![Vonage 应用程序私钥位置 Glitch 屏幕截图](/screenshots/use-cases/digital-marketplace-client-sdk/private-key-location-glitch.png)

### 使用 GitHub

将 `private.key` 文件移到项目根目录下：

![Vonage 应用程序私钥位置本地屏幕截图](/screenshots/use-cases/digital-marketplace-client-sdk/private-key-location-local.png)

配置应用程序
------

无论是重新混合 Glitch 项目，还是克隆 GitHub 存储库，都必须使用 `.env` 文件配置应用程序。

为每个变量分配从前面步骤中获得的相关值。

根据您使用的是 Glitch 还是 GitHub，`.env` 文件的结构略有不同。以下章节介绍了如何编辑 `.env` 文件。

### 对于 Glitch

按以下方式修改 `.env`，并将占位符文本替换为您的值：

    DANGEROUSLY_DISABLE_HOST_CHECK=true
    API_KEY="your-value-here"
    API_SECRET="your-value-here"
    APP_ID="your-value-here"
    PRIVATE_KEY="/.data/private.key"

### 对于 GitHub

按以下方式修改 `.env`，并将占位符文本替换为您的值：

    API_KEY="your-value-here"
    API_SECRET="your-value-here"
    APP_ID="your-value-here"
    PRIVATE_KEY="/private.key"

所有配置到此结束。

代码演练
----

本节提供应用程序最重要部分的代码演练。

### 登录

以下屏幕截图显示了登录屏幕：

![市场应用登录屏幕截图](/screenshots/use-cases/digital-marketplace-client-sdk/app-login.png)

用户输入用户名，然后选择卖家或买家角色。

`POST` 请求正文具有可用于设置用户名、显示名称和图像 URL 的属性，但没有用于指定角色的属性。您可以在 `custom_data` 中添加自己的属性，以便在其中创建 `role`：

*NexmoMarketplaceApp.js* 

```jsx
  const submitUser = async (e) => {
    try{
      const results = await fetch('/createUser', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: name.split(' ').join('-'),
          display_name: name.trim(),
          image_url: `https://robohash.org/${name.split(' ').join('-')}`,
          properties: {
            custom_data: {
              "role": role
            }
          }
        })
      });
      await results.json();
      await login();
    } catch(err){
      console.log('getJWT error: ',err);
    }
  };
```

### 身份验证

Client SDK 使用 [JWT](/concepts/guides/authentication#json-web-tokens-jwt) 进行身份验证。应用程序调用 Node Express 服务器来检索 JWT，然后将用户登录。服务器端的代码如下：

*server.js* 

```js
...
// the client calls this endpoint to request a JWT, passing it a username
app.post('/getJWT', function(req, res) {
    const jwt = nexmo.generateJwt({
        application_id: process.env.APP_ID,
        sub: req.body.name,
        exp: Math.round(new Date().getTime()/1000)+86400,
        acl: {
            "paths": {
                "/*/users/**":{},
                "/*/conversations/**":{},
                "/*/sessions/**":{},
                "/*/devices/**":{},
                "/*/image/**":{},
                "/*/media/**":{},
                "/*/applications/**":{},
                "/*/push/**":{},
                "/*/knocking/**":{}
            }
        }
    });
    res.send({jwt: jwt});
});

// the client calls this endpoint to create a new user in the Vonage application,
// passing it a username and optional display name
app.post('/createUser', function(req, res) {
    console.log('/createUser: ',req);
    nexmo.users.create({
        name: req.body.name,
        display_name: req.body.display_name || req.body.name,
        image_url: req.body.image_url,
        properties: req.body.properties
    },(err, response) => {
        if (err) {
            res.sendStatus(500);
        } else {
            res.send({id: response.id});
        }
    });
});
```

客户端应用本身具有功能可获取 JWT 并将用户登录：

*NexmoMarketplaceApp.js* 

```jsx
...
  // Get JWT to authenticate user
  const getJWT = async () => {
    try{
      const results = await fetch('/getJWT', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: name.split(' ').join('-')
        })
      });
      const data = await results.json();
      return data.jwt;
    } catch(err){
      console.log('getJWT error: ',err);
    }
  };

  // Log in the user
  const login = async () => {
    try{
      const userJWT = await getJWT();
      const app =  await new NexmoClient({ debug: false }).login(userJWT);
      setNexmoApp(app);
      await getConversations();
      setStage('listings');
    } catch(err){
      console.log('login error: ',err);
    }
  };
```

### 显示待售商品

当用户登录后，应用会检索所有待售商品的列表，这是一个对话对象列表。客户端调用服务器，服务器返回对话列表。客户端代码如下：

*NexmoMarketplaceApp.js* 

```jsx
  // Get all conversations, even the ones the user isn't a member of, yet.
  const getConversations = async() => {
    try{
        const results = await fetch('/getConversations', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({
            page_size: 100
          })
        });
        const data = await results.json();
        setItems(data.conversations);
    } catch(err) {
      console.log('getConversations error: ',err);
    }
  };
```

服务器获取对话列表并将其返回给客户端：

*server.js* 

```js
app.post('/getConversations', function(req, res) {
    console.log('/getConversations: ',req);
    nexmo.conversations.get({page_size: req.body.page_size},(err, response) => {
        if (err) {
            res.sendStatus(500);
        } else {
            res.send(response._embedded);
        }
    });
});
```

### 列出新的待售商品

如果选择了卖家角色，应用程序会显示一个表单，允许用户添加待售商品。以下屏幕截图显示了该表单：

![市场应用列出添加待售商品屏幕截图](/screenshots/use-cases/digital-marketplace-client-sdk/app-listing-item-for-sale.png)

当您填写表单并按“提交”时，Vonage Client SDK 会发出调用以创建对话。创建对话后，您可以将用户作为成员加入对话。

使用名为 `item_details` 的自定义事件来提醒应用程序，已列出新的待售商品；该事件会将商品详情传递给处理程序。

*NexmoMarketplaceApp.js* 

```jsx
  const createConversation = async() => {
    try{
      const conversation = await nexmoApp.newConversation({
        name: itemName.split(' ').join('-'), // comment out to get a GUID
        display_name: itemName.trim(),
        properties:{
          custom_data:{
            title: itemName,
            description: itemDescription,
            price: itemPrice,
            image_url: itemImage,
          }
        }
      });
      await conversation.join();
      await conversation.sendCustomEvent({ type: 'custom:item_details', body: { title: itemName, description: itemDescription, price: itemPrice, image_url: itemImage }})
      await getConversations();
      setItemName('');
      setItemImage('');
      setItemDescription('');
      setItemPrice('');
    } catch(err){
      console.log('createConversation error: ',err);
    }
  };
```

然后，应用程序会显示一个更新列表，并将您的商品置于顶端。

### 商品详情页

点击某个商品会调用 Client SDK 的 `getConversation` 函数。该代码会查看当前用户是不是该对话的成员。如果不是，它会将该用户添加为成员。

接着，加载在用户加入对话之前可能已发生的事件（例如聊天消息）。

*NexmoMarketplaceApp.js* 

```jsx
  const getConversation = async (item) => {
    try {
      const conversation = await nexmoApp.getConversation(item.uuid);
      setNexmoConversation(conversation);
      if (!conversation.me){
        await conversation.join();
      }
      let allEvents = await conversation.getEvents({page_size: 100});
      for(const [,event] of allEvents.items) {
        let user = await nexmoApp.getUser(conversation.members.get(event.from).user.id);
        switch(event.type){
          case 'text':
            setChatMessages(chatMessages => [...chatMessages,{avatar: user.image_url, sender:conversation.members.get(event.from), message:event, me:conversation.me}]);
            break;
          case 'custom:item_details':
            setConversationItem({...conversationItem,...event.body, seller: user});
            break;
          case 'custom:stripe_payment':
            setChatMessages(chatMessages => [...chatMessages,{avatar: '', sender:{user:{name:'Stripe'}}, message:{body:{text:`${event.body.paymentDetails.description}: ${event.body.paymentDetails.status}`}}, me:''}]);
            if (event.body.paymentDetails.status === 'succeeded'){
              setConversationItem(prevState => {
                return { ...prevState, status: 'Sold' }
              });
            }
            break;
          default:
        }
      }
      setStage('conversation');
    } catch(err){
      console.log('getConversation error: ',err);
    }
  };
```

### 购买商品

假设您要购买商品。当您点击 **立即付款** 按钮时，Vonage Client SDK 会引发另一个自定义事件 `stripe_payment`。

> **注意：** 在本用例中，Stripe 的响应是模拟的。付款网关由您自己根据首选提供商来实现。

*NexmoMarketplaceApp.js* 

```jsx
  // Mock a Stripe Payment call. Reference: https://stripe.com/docs/api/charges/create
  const postStripePayment = async() => {
    try{
      const results = await fetch('https://green-crowberry.glitch.me/stripePayment', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          amount: parseFloat(conversationItem.price.replace('$','')) * 100,
          currency: "usd",
          source: "tok_amex", // obtained with Stripe.js
          description: `Charge for ${conversationItem.title} from ${name}.`
        })
      });
      const data = await results.json();
      await nexmoConversation.sendCustomEvent({ type: 'custom:stripe_payment', body: { paymentDetails: data.response }});
    } catch(err){
      console.log('createConversation error: ',err);
    }
  };
```

*server.js* 

```js
// Create a mock Stripe API Response Reference: https://stripe.com/docs/api/charges/create
app.post('/stripePayment', function(req, res) {
    console.log('/stripePayment: ',req);
    res.send({
        response: {
            "id": "ch_1FSNhf2eZvKYlo2CodbBPmwQ",
            "object": "charge",
            "amount": req.body.amount,
            "amount_refunded": 0,
            "application": null,
            "application_fee": null,
            "application_fee_amount": null,
            "balance_transaction": "txn_19XJJ02eZvKYlo2ClwuJ1rbA",
            "billing_details": {
                "address": {
                    "city": null,
                    "country": null,
                    "line1": null,
                    "line2": null,
                    "postal_code": null,
                    "state": null
                },
                "email": null,
                "name": null,
                "phone": null
            },
            "captured": false,
            "created": 1570798723,
            "currency": req.body.currency,
            "customer": null,
            "description": req.body.description,
            "destination": null,
            "dispute": null,
            "failure_code": null,
            "failure_message": null,
            "fraud_details": {},
            "invoice": null,
            "livemode": false,
            "metadata": {},
            "on_behalf_of": null,
            "order": null,
            "outcome": null,
            "paid": true,
            "payment_intent": null,
            "payment_method": "card_1FSNha2eZvKYlo2CtZjDglzU",
            "payment_method_details": {
                "card": {
                    "brand": "visa",
                    "checks": {
                        "address_line1_check": null,
                        "address_postal_code_check": null,
                        "cvc_check": null
                    },
                    "country": "US",
                    "exp_month": 8,
                    "exp_year": 2020,
                    "fingerprint": "Xt5EWLLDS7FJjR1c",
                    "funding": "credit",
                    "installments": null,
                    "last4": "4242",
                    "network": "visa",
                    "three_d_secure": null,
                    "wallet": null
                },
                "type": "card"
            },
            "receipt_email": null,
            "receipt_number": null,
            "receipt_url": "https://pay.stripe.com/receipts/acct_1032D82eZvKYlo2C/ch_1FSNhf2eZvKYlo2CodbBPmwQ/rcpt_FyKMJVAk8reFPxol3uqojWqKWDWCRsv",
            "refunded": false,
            "refunds": {
                "object": "list",
                "data": [],
                "has_more": false,
                "total_count": 0,
                "url": "/v1/charges/ch_1FSNhf2eZvKYlo2CodbBPmwQ/refunds"
            },
            "review": null,
            "shipping": null,
            "source": {
                "id": "card_1FSNha2eZvKYlo2CtZjDglzU",
                "object": "card",
                "address_city": null,
                "address_country": null,
                "address_line1": null,
                "address_line1_check": null,
                "address_line2": null,
                "address_state": null,
                "address_zip": null,
                "address_zip_check": null,
                "brand": "Visa",
                "country": "US",
                "customer": null,
                "cvc_check": null,
                "dynamic_last4": null,
                "exp_month": 8,
                "exp_year": 2020,
                "fingerprint": "Xt5EWLLDS7FJjR1c",
                "funding": "credit",
                "last4": "4242",
                "metadata": {},
                "name": null,
                "tokenization_method": null
            },
            "source_transfer": null,
            "statement_descriptor": null,
            "statement_descriptor_suffix": null,
            "status": "succeeded",
            "transfer_data": null,
            "transfer_group": null
        }
    })
});
```

系统将为 `stripe_payment` 事件注册一个处理程序：

*NexmoMarketplaceApp.js* 

```jsx
  useEffect(()=>{
    const setStripePayment = async (sender, event) => {
      setChatMessages(chatMessages => [...chatMessages,{sender:{user:{name:'Stripe'}}, message:{body:{text:`${event.body.paymentDetails.description}: ${event.body.paymentDetails.status}`}}, me:''}]);
      if (event.body.paymentDetails.status === 'succeeded'){
        setConversationItem(prevState => {
          return { ...prevState, status: 'Sold' }
        });
      }
    };
    if(nexmoConversation){
      nexmoConversation.on('custom:stripe_payment', setStripePayment);
      return () => {
        nexmoConversation.off('custom:stripe_payment', setStripePayment);
      };
    }
  });
```

侦听器将付款通知显示为聊天消息。如果付款 `succeeded`，则商品的状态更新为 `Sold`，并且 UI 刷新。

结语
---

在本用例中，您学习了如何构建可以买卖商品的数字市场。该用例演示了如何使用 Vonage Client SDK 来构建客户端应用程序以发送自定义事件，然后侦听这些事件以更新应用程序的状态。服务器代码响应了客户端应用的请求，例如实施身份验证并返回对话列表。

接下来做什么？
-------

如果您将此示例用作生产应用程序的基础，则应添加更可靠的身份验证。您还可以添加自定义事件，改善用户的购买和销售体验。例如，您可以允许用户将他们有兴趣购买的商品添加到收藏列表中。此外，您可以允许卖家编辑他们列出的待售商品。

有用的链接
-----

* [概述](/client-sdk/overview)
* [教程](/client-sdk/tutorials)
* [用例](/client-sdk/use-cases)

