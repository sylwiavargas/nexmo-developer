---
title: Add Nexmo Inbound Sms Route
description: Add a route into your website to receive inbound SMS messages
---

In your Sms Controller add the following method:

```csharp
[HttpGet("webhooks/inbound-sms")]
public ActionResult Receive([FromQuery]SMS.SMSInbound response)
{

    if (null != response.to && null != response.msisdn)
    {
        Console.WriteLine("------------------------------------");
        Console.WriteLine("INCOMING TEXT");
        Console.WriteLine("To: " + response.to);
        Console.WriteLine("From: " + response.msisdn);
        Console.WriteLine("Message: " + response.text);
        Console.WriteLine("Message: " + response.timestamp);
        Console.WriteLine("------------------------------------");
        return StatusCode(Microsoft.AspNetCore.Http.StatusCodes.Status200OK);
    }
    return NoContent();
}
```
