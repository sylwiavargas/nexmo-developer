---
title: Send Sms
description: Steps to send an SMS message from our mvc controller.
---

In the SmsController - switch out `NEXMO_API_KEY` and `NEXMO_API_SECRET` for your Nexmo API Key and Secret.

In Visual Studio, click 'IIS Express' or hit 'f5'.

This will start up the site and bring you to the home view.

Navigate to the SMS view by going to the sitebase/sms - e.g. `https://localhost:44389/sms`

In the form, set `To` as the number you want to send to, `from` as the Nexmo Number of your account, and `message` as the text you want to send. Then Click 'Send'
