# docker-nginx-php-git
Minimal base image for hosting Nginx + PHP-FPM powered websites with Automatic Git Deployment functionalities including Webhooks

## Configuration

### Available Configuration Parameters

The following flags are a list of all the currently supported options that can be changed by passing in the variables to docker with the -e flag.

 - **GIT_REPO** : URL to the repository containing your source code
 - **GIT_BRANCH** : Select a specific branch (optional)
 - **GIT_EMAIL** : Set your email for code pushing (required for git to work)
 - **GIT_NAME** : Set your name for code pushing (required for git to work)
 - **SSH_KEY** : Private SSH deploy key for your repository base64 encoded (requires write permissions for pushing)
 - **WEBROOT** : Change the default webroot directory from `/var/www/html` to your own setting
 - **ERRORS** : Set to 1 to display PHP Errors in the browser
 - **SHORT_TAG** : Set to 1 to enable PHP SHORT_TAG
 - **TEMPLATE_NGINX_HTML** : Enable by setting to 1 search and replace templating to happen on your code
 - **HIDE_NGINX_HEADERS** : Disable by setting to 0, default behaviour is to hide nginx + php version in headers
 - **PHP_MEM_LIMIT** : Set higher PHP memory limit, default is 128 Mb
 - **PHP_POST_MAX_SIZE** : Set a larger post_max_size, default is 100 Mb
 - **PHP_UPLOAD_MAX_FILESIZE** : Set a larger upload_max_filesize, default is 100 Mb
 - **DOMAIN** : Set domain name for Lets Encrypt scripts
 - **GIT_HOOK_TOKEN** : Auth-Token used for the [docker-hook](https://github.com/schickling/docker-hook) listener
 - **DOCKER_HOOK_PROXY** : Set to 1 to enable `/docker-hook` as an endpoint on your nginx site
 - **HTTPS_REDIRECT** : Set to 0 to prevent nginx from forcing https
 
 - **PM_START_SERVERS** : Set number of servers
 - **PM_MIN_SPARE_SERVERS** : Set min spare servers
 - **PM_MAX_SPARE_SERVERS** : Set max spare servers
 - **PM_MAX_REQUESTS** : Set max requests
 - **PM_MAX_CHILDREN** : Set max children

  
### Dynamically Pulling code from git
One of the nice features of this container is its ability to pull code from a git repository with a couple of environmental variables passed at run time.

**Note:** You need to have your SSH key that you use with git to enable the deployment. I recommend using a special deploy key per project to minimise the risk.

### Preparing your SSH key
The container expects you pass it the __SSH_KEY__ variable with a **base64** encoded private key. First generate your key and then make sure to add it to github and give it write permissions if you want to be able to push code back out the container. Then run:
```
base64 /path_to_your_key
```
**Note:** Copy the output be careful not to copy your prompt

To run the container and pull code simply specify the GIT_REPO URL including *git@* and then make sure you have also supplied your base64 version of your ssh deploy key:
```
sudo docker run -d -e 'GIT_REPO=git@git.ngd.io:ngineered/ngineered-website.git' -e 'SSH_KEY=BIG_LONG_BASE64_STRING_GOES_IN_HERE' richarvey/nginx-php-fpm
```
To pull a repository and specify a branch add the GIT_BRANCH environment variable:
```
sudo docker run -d -e 'GIT_REPO=git@git.ngd.io:ngineered/ngineered-website.git' -e 'GIT_BRANCH=stage' -e 'SSH_KEY=BIG_LONG_BASE64_STRING_GOES_IN_HERE' richarvey/nginx-php-fpm
```
### Enabling SSL or Special Nginx Configs
You can either map a local folder containing your configs  to /etc/nginx or we recommend editing the files within __conf__ directory that are in the git repo, and then rebuilding the base image.

### Lets Encrypt support (Experimental)
#### Setup
You can use Lets Encrypt to secure your container. Make sure you start the container ```DOMAIN, GIT_EMAIL``` and ```WEBROOT``` variables to enable this to work. Then run:
```
sudo docker exec -t <CONTAINER_NAME> /usr/bin/letsencrypt-setup
```
Ensure your container is accessible on the ```DOMAIN``` you supply in order for this to work
#### Renewal
Lets Encrypt certs expire every 90 days, to renew simply run:
```
sudo docker exec -t <CONTAINER_NAME> /usr/bin/letsencrypt-renew
```
## Special Git Features
You'll need some extra ENV vars to enable this feature. These are ```GIT_EMAIL``` and ```GIT_NAME```. This allows git to be set up correctly and allow the following commands to work.

### docker-hook - Git Webhook

`docker-hook` is preconfigured to listen to incoming HTTP requests on port 8555

All you have to do is setup the **GIT_HOOK_TOKEN** env var, and any requests to `http://yourdomain:8555/<GIT_HOOK_TOKEN>` will trigger a Git pull

You can also enable docker-hook on your default nginx ports with **DOCKER_HOOK_PROXY**.  If enabled, you can POST your github webhook to `http(s)://yourdomain/docker-hook/<GIT_HOOK_TOKEN>` without using port 8555.

More info on how it works here: [schickling/docker-hook](https://github.com/schickling/docker-hook)

### Push code to Git
To push code changes made within the container back to git simply run:
```
sudo docker exec -t -i <CONTAINER_NAME> /usr/bin/push
```
### Pull code from Git (Refresh)
In order to refresh the code in a container and pull newer code form git simply run:
```
sudo docker exec -t -i <CONTAINER_NAME> /usr/bin/pull
```
### Templating
**NOTE: You now need to enable templates see below**
This container will automatically configure your web application if you template your code.
### Using environment variables
For example if you are using a MySQL server, and you have a config.php file where you need to set the MySQL details include $$_MYSQL_HOST_$$ style template tags.

Example config.php::
```
<?php
database_host = $$_MYSQL_HOST_$$;
database_user = $$_MYSQL_USER_$$;
database_pass = $$_MYSQL_PASS_$$
...
?>
```

To set the variables simply pass them in as environmental variables on the docker command line.

Example:
```
sudo docker run -d -e 'GIT_REPO=git@git.ngd.io:ngineered/ngineered-website.git' -e 'SSH_KEY=base64_key' -e 'TEMPLATE_NGINX_HTML=1' -e 'GIT_BRANCH=stage' -e 'MYSQL_HOST=host.x.y.z' -e 'MYSQL_USER=username' -e 'MYSQL_PASS=supper_secure_password' richarvey/nginx-php-fpm
```

This will expose the following variables that can be used to template your code.
```
MYSQL_HOST=host.x.y.z
MYSQL_USER=username
MYSQL_PASS=password
```
### Template anything
Yes ***ANYTHING***, any variable exposed by the **-e** flag lets you template your configuration files. This means you can add redis, mariaDB, memcache or anything you want to your application very easily.
## Logging and Errors
### Logging
All logs should now print out in stdout/stderr and are available via the docker logs command:
```
docker logs <CONTAINER_NAME>
```

## Thanks to
* [eduwass/docker-nginx-php-git](https://github.com/eduwass/docker-nginx-php-git) - Enhanced docker image with docker hook
* [ngineered/nginx-php-fpm](https://github.com/ngineered/nginx-php-fpm) - Base Docker image and Git push/pull functionalities
* [schickling/docker-hook](https://github.com/schickling/docker-hook) - Git Webhook listener

