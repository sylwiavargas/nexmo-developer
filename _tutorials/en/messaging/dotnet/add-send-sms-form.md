---
title: Add Send Sms Form
description: Steps to add a basic form for send-sms in a asp.net core mvc view
---

Open Views->Sms->Index.cshtml

Add the following code:

```csharp
<header>
    <h1>Learn how to use the Nexmo Send Sms Api</h1>
</header>

<div style="width:50%; padding-top:10px">
    <div class="content">
        <div class="title" style="height:20px; background-color:cornflowerblue; text-align:center">
            <span style="vertical-align:central; text-align:center">Send SMS</span>
        </div>
        <div style="padding-top:20px">
            @using (Html.BeginForm("Send", "SMS", FormMethod.Post))
            {
                <input type="text" name="to" id="to" placeholder="To" style="height:30px" />
                <br />
                <input type="text" name="from" id="from" placeholder="from" style="height:30px" />
                <br />
                <input type="text" name="message" id="message" placeholder="message" style="height:30px" />
                <input type="submit" value="Send" style="height:30px;" />
            }
        </div>
        <h2> @ViewBag.result</h2>
    </div>
</div>
```
