# VM for Deploying and Configuring Servers and Tools to Enable Semantic Architecting 

A Vagrant-based virtual machine (VM) for enabling a systems architecting capability that utilizes technologies used by the [Semantic Web][Semantic Web].

This VM deploys

* [Open Model Based Engineering Environment (OpenMBEE) v3.4.2][openmbee] 
* [Model Management System (MMS) v3.4.2][mms] 
* [View Editor (VE) v3.6.1][view-editor] 

stack that is part of [OpenMBEE Docker stack][docker-image].

Also, fully-configures the following servers and tools 

* [Apache Jena v3.5.0][jena] a framework for building Semantic web and Linked Data applications
* [Apache Jena Fuseki v3.5.0][fuseki], a SPARQL server end-point accessible over HTTP and REST API
* [WebProtégé v4.0.2][webprotege] a webserver to develop ontologies

from the [Semantic Web stack][Semantic Web stack] to help the development and usage of ontologies in architecting activities.

In addition, this stack also sets up

* [pgAdmin v4.20][pgadmin], a Postgres database browser 
* [Dejavu v3.2.3][dejavu], an ElasticSearch browser

to help view and access the raw data in the stack.

> This virtual machine was developed to facilitate the installation of the OpenMBEE MMS server.
It is intended as a stop-gap solution until a scalable containerized version of the OpenMBEE MMS server can be developed, e.g., using [Kubernetes][kubernetes].

As of Jul 24, 2020, this VM works with [OpenMBEE MMS Docker Image][docker-image] v3.4.2 (latest) and [View Editor (VE)][view-editor] v3.6.1 (latest).  This VM has been successfully deployed and tested in a local Ubuntu 18.04 server and on Windows 10; other MMS and VE versions or OSes have not been tested.  Additionally, the [Model Development Kit (MDK)][mdk] v4.1.3 (latest) plugin for [MagicDraw][magicdraw] successfully works with the MMS server this repo provisions.

**WARNING: this server is configured to use http, generic passwords, and allows connections from nearly every IP, as it was intended as local sandbox. This server is not configured for a safe and secure public-facing server!**

## Prerequisites
0. Have at least 75GB of free space.

1. Install [Vagrant][vagrant].

2. Install a plug-in for Vagrant:

    `$ vagrant plugin install vagrant-disksize`

3. Install [VirtualBox][virtualbox].


## Installation
1. Clone this repository:

    `$ git clone https://github.com/MJDiaz89/openmbee-vm.git`
    

2. Provision the virtual machine:
    
    `$ cd openmbee-vm`

    `$ vagrant up`

> The first time you run this, it will take some time to start all the services, so please be patient.


## Usage

### Login to Apache Tomcat
You can login and browse the main Tomcat webserver at http://127.0.0.1:8080 using `admin` and `tomcatadmin`.  After, click `List Applications` and you should see all applications running.  On initialization, you may need to manually start the Fuseki server.

### Login to Alfresco
You can visit the main Alfresco dashboard at http://127.0.0.1:8080/share/page/ using `admin` as both the username and the password.

### Login to View Editor
You can login to the OpenMBEE [View Editor][view-editor] by going to http://127.0.0.1:8080/ve/mms.html#/login and using `admin` as both the username and the password.

### Login to PG Admin
You can browse the Postgres database by going to http://127.0.0.1:5433. Authenticate with `pgadmin4@pgadmin.org` as the user and `admin` as the password.

### Login to Dejavu
You can browse the ElasticSearch database through Dejavu by going to http://127.0.0.1:1358.  Enter `http://127.0.0.1:9200` in the page's cluster URL; the app name is the ElasticSearch index you want to browse, i.e. use `<project id>` (in lower case) to view a specific project or `*` to browse all.


### Using Apache Jena 
Jena is not configured as a server, but a Docker container that runs your commands and then exits.  To use it, SSH into the Vagrant VM

`$ vagrant ssh`

and type the desired commands using the jena prefix, e.g. use the riot command

`$ jena riot --version`

or

`$ jena -h`

to see all available commands.  For documentation of these commands, see https://jena.apache.org/documentation/index.html


### Using Apache Jena Fuseki
This repo only sets up the [Fuseki][fuseki] server on http://127.0.0.1:8080/fuseki.

> Note: the server may not be started by default at the VM's initialization; it may need to be manually started. To do that, visit Tomcat (http://localhost:8080/manager/).  After authenticating, locate `/fuseki`, and click `start.`

In order to use Fuseki and MMS, visit https://github.com/Open-MBEE/mms-rdf for instructions.  Those instructions should be ran on the host machine running the Vagrant VM (not the Vagrant VM itself) using all `local` commands. Do not run `./util/local-endpoint.sh`, as this repo already sets up the local endpoint.

### Finalize WebProtégé set-up
There are a few remaining steps that cannot be automated:

1. Enter the Vagrant virtual machine:

    `$ vagrant ssh`

2. Run the script that creates the admin account:
   
    `$ docker exec -it webprotege java -jar /webprotege-cli.jar create-admin-account`
   
   Enter the required information.  Ex:

    `Admin name: admin`

    `admin email:  admin@admin.com`

    `admin password: admin`

3. Exit the Vagrant virtual machine:

    `$ exit`

4. Visit http://localhost:8090/#application/settings.  Fill out the form using 
    * Application Name: `WebProtégé` 
    * Email Notification Address: `admin@admin.com`
    * Scheme: `http`
    * Host: `localhost` 
    * Persmissions: enable all

#### Other useful links
See everything Tomcat is running: http://127.0.0.1:8080/manager/html/


See MMS's full API and SDK documentation: http://127.0.0.1:8080/alfresco/mms/index.html


### Access MMS REST API documentation
You can access the Swagger UI at http://127.0.0.1:8080/alfresco/mms/swagger-ui/index.html


### Test MMS via REST 
Use the following curl commands to post an initial organization + project:
```
$ curl -w "\n%{http_code}\n" -H "Content-Type: application/json" -u admin:admin --data '{"orgs": [{"id": "vetestorg", "name": "vetestorg"}]}' -X POST "http://localhost:8080/alfresco/service/orgs"
$ curl -w "\n%{http_code}\n" -H "Content-Type: application/json" -u admin:admin --data '{"projects": [{"id": "vetestproj","name": "vetestproj","orgId": "vetestorg", "type": "Project"}]}' -X POST "http://localhost:8080/alfresco/service/orgs/vetestorg/projects"
```

Make sure the server accepted them:
````
$ curl -w "\n%{http_code}\n" -H "Content-Type: application/json" -u admin:admin -X GET "http://localhost:8080/alfresco/service/orgs"
$ curl -w "\n%{http_code}\n" -H "Content-Type: application/json" -u admin:admin -X GET "http://localhost:8080/alfresco/service/orgs/vetestorg/projects"
````


### Troubleshoot
If that URL is not responding, make sure [Alfresco][alfresco] is running, by going to: http://127.0.0.1:8080/alfresco

If that is not working, checkout the `docker-compose` logs by:

1. SSH'ing into the VM:

    `$ vagrant ssh`

2. And inspecting the logs:

    `$ dc logs` 
    
    or

    `$ dc logs --follow --tail 0`

    to inspect how the server is handeling requests and responses.

3. Make sure the docker containers are actually running:

    `$ dc ps -a`

    For more information on the custom commands, type:
    
    `commands` 

4. Make sure you can access Tomcat at http://127.0.0.1:8080 and that you see all services running at http://127.0.0.1:8080/manager/html/list.  Authenticate with 

    `user: admin`

    `password: tomcatadmin`
   

### Important Notice
To maximize the server's usefulness, you will need to have: [MagicDraw][magicdraw], the
[Model Development Kit (MDK)][mdk] plugin, and a SysML model.

As of Jan 24, 2020, the latest MDK plugin version for MagicDraw is 4.1.3 and can be found here: https://bintray.com/openmbee/maven/mdk/4.1.3

**Note:** do not let MDK create an organization for you!  Otherwise, you may end up with an unstable organization.  Instead, create it with the curl command above.


[alfresco]: https://www.alfresco.com/ "Alfresco"
[docker-image]: https://hub.docker.com/r/openmbeeguest/mms-repo/ "OpenMBEE Docker Image"
[kubernetes]: https://kubernetes.io/ "Kubernetes"
[magicdraw]: https://www.nomagic.com/products/magicdraw "MagicDraw"
[mdk]: https://github.com/Open-MBEE/mdk "Model Development Kit"
[mms]: https://github.com/Open-MBEE/mms "Model Management System"
[openmbee]: http://www.openmbee.org/ "OpenMBEE"
[vagrant]: https://www.vagrantup.com/downloads.html "Vagrant"
[view-editor]: https://github.com/Open-MBEE/ve "View Editor"
[virtualbox]: https://www.virtualbox.org/wiki/Downloads "VirtualBox"
[pgadmin]: https://www.pgadmin.org/ "pgAdmin"
[dejavu]: https://opensource.appbase.io/dejavu/ "Dejavu"
[jena]: https://jena.apache.org/documentation/index.html "jena"
[fuseki]: https://jena.apache.org/documentation/fuseki2/ "fuseki"
[webprotege]: https://github.com/protegeproject/webprotege "WebProtégé"
[riot]: https://jena.apache.org/documentation/io/ "riot"
[Semantic Web]: https://en.wikipedia.org/wiki/Semantic_Web
[Semantic Web stack]: https://en.wikipedia.org/wiki/Semantic_Web_Stack