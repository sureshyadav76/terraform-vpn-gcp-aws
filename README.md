### This will create highly available VPN connections between Google Cloud and Amazon Web Services (AWS) for direct communication between VPC networks across the two cloud platforms.
---

###### Default region has been changed to eu-central-1 on AWS & europe-west3 on GCP (frankfurt).

![overview](https://user-images.githubusercontent.com/96201125/206707945-25bb4014-150e-4364-a61f-115a0fb234ed.svg)

Objectives
---
* Create a VPC network on Google Cloud.
* Create an HA VPN gateway on Google Cloud.
* Create customer gateways on AWS.
* Create a VPN connection with dynamic routing on AWS.
* Create an external VPN gateway and VPN tunnels on Google Cloud.
* Verify and test the VPN connection between VPC networks on Google Cloud and AWS.

**Costs**
---
This infrastructure uses billable components of Google Cloud, including the following:

[Cloud VPN](https://cloud.google.com/vpc/network-pricing)

[Compute Engine](https://cloud.google.com/compute/all-pricing)

For an estimate of the costs for the Google Cloud components, use the [Google Cloud pricing calculator.](https://cloud.google.com/products/calculator#id=b881814f-1a95-4c8e-a152-8237149589f7)

This tutorial uses billable components of Amazon Web Services, including the following:

AWS Transit Gateway
AWS Site-to-Site VPN
For an estimate of the costs for the AWS components, use the [AWS pricing calculator.](https://calculator.aws/#/estimate?id=4809b31b0f76c86737c07f63d5651d93a15e7894)
