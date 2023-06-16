# OpenFoodFacts Infrastructure

Sysadmin repository for the various parts of the Open Food Facts infrastructure.
We have a [specific repository regarding monitoring](https://github.com/openfoodfacts/openfoodfacts-monitoring)

## Current priorities

As of 2023 our current priorities are:

* server migration with hardware upgrade and a clean containerized install - and zfs syncs
* better encrypted two-way communication between data centers  (stunnel + https)
* backups checks
  * testing backups through staging
    * with automated deployment of new clones
  * monitoring backups
* better monitoring
  * more/better dashboards
  * more active checks (monitoring - alerts)
  * less false positives in alerts
* GPU server for inference and possibly one for training (not hosted) - may

## Incident logs

We started logging incidents by server:

* [off1 incident logs](./docs/logs-off1.md)
* [off2 incident logs](./docs/logs-off2.md)
* [off3 incident logs](./docs/logs-off3.md)
* [ovh1 incident logs](./docs/logs-ovh1.md)
* [ovh2 incident logs](./docs/logs-ovh2.md)
* [ovh3 incident logs](./docs/logs-ovh3.md)

## Documentation

Link to [Github Page](https://openfoodfacts.github.io/openfoodfacts-infrastructure/)

The infrastructure documentation is as follows:

- [Free Datacenter](./docs/free-datacenter.md) - Data center with main production servers

- [Linux Server](./docs/linux-server.md) - servers general setup
- [Mail](./docs/mail.md) - servers mail setup
- [An introduction to ZFS](./docs/zfs-overview.md) - ZFS is much used in our infrastructure
- [Proxmox](./docs/promox.md) - about proxmox management
- [CICD](./docs/cicd.md) - continuous integration and deployment
- [Observability](./docs/observability.md) - doc on monitoring / logs / etc.
- [Docker Onboarding](./docs/docker_onboarding.md)
- [Docker Infrastructure](./docs/docker_architecture.md)
- [Virtual Machines](#virtual-machines)

The main services:
- [MongoDB](./docs/mongodb.md) the MongoDB database

Some services:

- [Discourse](./docs/discourse.md) for forum
- [NGINX reverse proxy](./docs/nginx-reverse-proxy.md) the reverse proxy for OVH services
- [Folksonomy](./docs/folksonomy.md) user editable labels and values
- [Matomo](./docs/matomo.md) for web analytics
- [Producers sftp](./docs/producers_sftp.md) to push product updates on producer platform
- [Zammad](./docs/zammad.md) for support
- [Odoo](./docs/odoo.md) the CRM

Also look at all install and post-mortem reports in [docs/reports](./docs/reports/)

<details><summary><h2>Monthly meetings</h2></summary>

* We e-meet monthly at [18:00 CET](https://dateful.com/convert/paris-france?t=6pm) the second Thuesday of the month
* ![Google Meet](https://img.shields.io/badge/Google%20Meet-00897B?logo=google-meet&logoColor=white) Video call link: meet.google.com/ybq-dwuk-pvi
* Join by phone: https://tel.meet/nnw-qswu-hza?pin=2111028061202
* Add the Event to your Calendar by [adding the Open Food Facts community calendar to your calendar](https://wiki.openfoodfacts.org/Events)
* [Monthly Agenda](https://docs.google.com/document/d/18BNNqxL6MSLAMrwsQ9F-CaVBUojnUEilQmQuC7XdVks/edit?usp=sharing): please add the Agenda items as early as you can. 
* Make sure to check the Agenda items in advance of the meeting, so that we have the most informed discussions possible. 
* The meeting will handle Agenda items first, and if time permits, collaborative bug triage.
</details>

## Requests

### Virtual Machines

<!-- VM table -->
|                                                                      Title                                                                      |State |              OS              |      CPU #      |                              RAM                              |                                                    SSD (Local)                                                    |    HDD (Remote)     |                                       Services                                        |
|-------------------------------------------------------------------------------------------------------------------------------------------------|------|------------------------------|-----------------|---------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|---------------------|---------------------------------------------------------------------------------------|
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/200>Wordpress test CT [#200]</a>                                    |open  |Debian last Stable.           |                3|[Explain if > 4 Gb.]                                           |6 GB.                                                                                                              |                    0|Apache, PHP, Wordpress.                                                                |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/159>Monitoring - VM (QEMU host for docker) [#159]</a>               |open  |Debian                        |* 4 CPUs         |* 12G for we have influxdb and elastic-search that needs memory|* 30 Go disk (it is currently around 14G, but this will grow because we want to harvest more logs and more metrics)|* 50Go for ES backups|Docker, docker-compose                                                                 |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/80>CT for new blog engine [#80]</a>                                 |open  |Debian stable.                |3 CPU.           |2 GB.                                                          |10 GB                                                                                                              |--                   |LAMP + wordpress.                                                                      |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/76>CT for Folksonomy Engine API dev [#76]</a>                       |open  |Default to Debian last Stable.|2                |1 GB                                                           |12 GB.                                                                                                             |-                    |PostgreSQL, Python3.                                                                   |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/37> Wild School Eco-Score project [#37]</a>                         |open  |Debian 10                     |4                |16 Gb                                                          |30 Gb                                                                                                              |0                    |MongoDB                                                                                |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/36> slack-org [#36]</a>                                             |open  |Debian 10                     |1                |1 Gb                                                           |10 Gb                                                                                                              |None                 |Node.js                                                                                |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/29> adminer-org [#29]</a>                                           |open  |Debian 10                     |2                |512 Mb.                                                        |4 Gb or even less.                                                                                                 |0                    |Nginx, PHP, Adminer.                                                                   |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/28>Containers (x2) to build a replica set for OFF database [#28]</a>|open  |Debian 10                     |4                |32 GB                                                          |50 GB (DB = 20 GB).                                                                                                |0                    |Mongodb.                                                                               |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/27> feedme-org [#27]</a>                                            |open  |Debian 10                     |3                |3 Gb.                                                          |15 Gb.                                                                                                             |0                    |PostgreSQL, Node.js, Nginx.                                                            |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/21> off-wiki-org [#21]</a>                                          |open  |Debian 10                     |2                |3 Gb                                                           |14 Gb.                                                                                                             |14 Gb                |Apache, PHP, MySQL, Mediawiki.                                                         |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/124>VM for the Community Portal [#124]</a>                          |closed|Debian last Stable.           |[Explain if > 4.]|[Explain if > 4 Gb.]                                           |[Explain if > 32 Gb.]                                                                                              |[Explain if > 1 Tb.] |Python/Django, probably PostgreSQL, probably Apache and all Dockerized                 |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/123>VM for the Taxonomy Editor [#123]</a>                           |closed|Debian last Stable.           |[Explain if > 4.]|[Explain if > 4 Gb.]                                           |[Explain if > 32 Gb.]                                                                                              |[Explain if > 1 Tb.] |Python, probably PostgreSQL, probably Apache for lightweight API serving from Docker   |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/71>New VM QEMU for prod docker containers [#71]</a>                 |closed|Debian 11 (stable)            |8                |24 GB                                                          |256 GB.                                                                                                            |-                    |Services deployed in production:                                                       |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/59> monitoring [#59]</a>                                            |closed|Debian 11                     |4                |32GB                                                           |64GB                                                                                                               |500GB (ovh3 mount)   |Docker: ElasticSearch (Kibana?, Logstash?), Grafana, InfluxDB, Prometheus, Alertmanager|
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/55> impactestimator-net [#55]</a>                                   |closed|Debian 11                     |1                |1GB                                                            |1Gb                                                                                                                |0                    |https://github.com/openfoodfacts/impactestimator                                       |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/53> robotoff-ml [#53]</a>                                           |closed|Debian 11                     |8                |96GB (Tensorflow, ANN)                                         |192GB [ML models]                                                                                                  |100GB                |Tensorflow + ElasticSearch                                                             |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/51> robotoff-net [#51]</a>                                          |closed|Debian 11                     |4                |16GB (DB 4GB, Services 8GB)                                    |92GB                                                                                                               |0GB                  |Robotoff API + Schedulers + Workers, PostgreSQL DB                                     |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/45> mongo-dev [#45]</a>                                             |closed|Debian 10                     |2                |16GB                                                           |40GB                                                                                                               |                     |MongoDB running in Docker                                                              |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/41> off-net [#41]</a>                                               |closed|Debian 10                     |4                |16GB (PO needs > 6GB)                                          |192GB                                                                                                              |0GB                  |ProductOpener frontend + backend, MongoDB, PostgreSQL, Memcached                       |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/40> robotoff-dev [#40]</a>                                          |closed|Debian 10                     |4                |8 Gb                                                           |32 Gb                                                                                                              |100 Gb               |robotoff, elastic search, tensorflow, postgresql                                       |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/24> Matomo [#24]</a>                                                |closed|Debian 10                     |No idea.         |No idea.                                                       |No idea.                                                                                                           |No idea.             |LAMP                                                                                   |
|<a href=https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/20> robotoff-org [#20]</a>                                          |closed|Debian 10                     |4                |8 Gb                                                           |32 Gb                                                                                                              |100 Gb               |robotoff, elastic search, tensorflow, postgresql                                       |
<!-- VM table -->

<a href="https://github.com/openfoodfacts/openfoodfacts-infrastructure/issues/new?assignees=cquest&labels=container&template=vm-template.md&title="><img src="./scripts/add.png" style="background: transparent; vertical-align: middle" width="30"/>&nbsp;&nbsp;Request a VM</img></a>
