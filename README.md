# RAIS - ECS Utility API


#### Table of Contents
1. [About](#about)

## About

When building the platform for our PI Dashboard product (hosted in Elastic Container Services), RAIS developed this api to allow object-oriented interaction with the ECS infrastructure as well as local and remote Docker registries.  This library is used by a set of cli tools that we use to build, push and deploy images to specific services in ECS -- this CLI will also being posted to the CU-CloudCollab repository.

Currently, the library focuses on services that already exist in AWS (that is, they have been set up using the GUI, or through other scripts) -- it allows monitoring those services, as well as updating them with new parameters (new task configurations, new images, and scaling).

Future enhancements will add the ability to setup new services (create the service, assign role, assign ELB).

