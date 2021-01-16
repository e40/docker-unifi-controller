# To make a new container with an updated UniFi controller version:
#
# 1. Download new controller (see comments below near UNIFI_VERSION below).
# 2. Build:
#      $ make
# 3. Install:
#      $ make start
#    You can do
#      $ docker logs unifi-controller
#    to see what it's up to, in case it doesn't start up.
#
# After a new version has been in use and it seems OK, you shoudl probably
# do this to clean up space on the docker server:
#    $ docker system prune
# saying "y" to the question of continuing.  This can easily reclaim a GB
# space, or more.
#
###############################################################################
#
# HOW TO UPGRADE TO A NEW VERSION:
# 1. Visit this in a browser:
#      https://www.ui.com/download/unifi
#    and download to this directory the one for
#      Debian/Ubuntu Linux and UniFi Cloud Key
#    even though I'm running it in a container... it's the same version.
# 2. Change UNIFI_VERSION below
# 3. SAVE OLD .deb VERSIONS UNTIL YOU ARE SURE THE NEW ONE IS WORKING!
#
#### CURRENT:
UNIFI_VERSION = 6.0.43
#### LAST KNOWN GOOD:
#UNIFI_VERSION = 6.0.41
#
###############################################################################

CONFIG_ROOT  = /me/unifi
REPO         = e40
NAME         = unifi-controller
DOCKER_BUILD = --no-cache 

# Should be the first rule in this Makefile
build: FORCE
	docker build $(DOCKER_BUILD) \
	    --build-arg UNIFI_VERSION=$(UNIFI_VERSION) \
	    -t $(REPO)/$(NAME) .

#### WARNING WARNING WARNING WARNING WARNING WARNING WARNING ####
# ONLY DO THIS IF YOU ARE MIGRATING devices TO A CONTROLLER
# THAT HAS NONE.  IF YOU DO THIS AFTER ADOPTING DEVICES
# THEY WILL BECOME ORPHANS AND IT WILL TAKE WORK TO RECTIFY
# THIS.
#### WARNING WARNING WARNING WARNING WARNING WARNING WARNING ####
initialize: FORCE
	ls -l $(CONFIG_ROOT)
	@read -p 'Remove these files[yN]? ' -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
	    rm -fr $(CONFIG_ROOT)/*; \
	    make start; \
	else \
	    echo ABORT; \
	    exit 1; \
	fi
	@echo INITIALIZED 

stop: FORCE
	-docker stop $(NAME)
	-docker rm $(NAME)

start: stop
	@if [ $(shell id -u) -eq 0 ]; then \
	    echo '"make $@" must NOT be run as root'; \
	    exit 1; \
	fi
	docker run -d --restart unless-stopped \
	  --name=unifi-controller \
	  -e PUID=$(shell id -u $(USER)) \
	  -e PGID=$(shell id -g $(USER)) \
	  -p 3478:3478/udp \
	  -p 10001:10001/udp \
	  -p 8080:8080 \
	  -p 8443:8443 \
	  -p 1900:1900/udp \
	  -p 6789:6789 \
	  -p 5514:5514 \
	  -v $(CONFIG_ROOT):/config \
	  $(REPO)/$(NAME)
	@sleep 2
	@container=$$(docker inspect --format="{{.Id}}" unifi-controller); \
	echo IP in container: $$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' $$container); \
	echo docker logs -f $$container
	@echo GO HERE FOR THE CONTROLLER: https://$(shell hostname):8443

FORCE:
