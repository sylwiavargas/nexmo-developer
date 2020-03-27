---
title: Add Send Sms Action
description: Create the Action to an SMS
---

Add the following method to your controller file:

```csharp
[HttpPost]
public ActionResult Send(string to, string from, string message)
{
    var NEXMO_API_KEY = "NEXMO_API_KEY";
    var NEXMO_API_SECRET = "NEXMO_API_SECRET";
    var client = new Client(new Nexmo.Api.Request.Credentials() { ApiKey = NEXMO_API_KEY, ApiSecret = NEXMO_API_SECRET });

    var results = client.SMS.Send(new SMS.SMSRequest()
    {
        to = to,
        from = from,
        text = message
    });

    if (results.messages.Count >= 1)
    {
        if (results.messages[0].status == "0")
        {
            ViewBag.result = "Message sent successfully.";
        }
        else
        {
            ViewBag.result = $"Message failed with error: { results.messages[0].error_text}";
        }
    }

    return View("Index");
}
```
