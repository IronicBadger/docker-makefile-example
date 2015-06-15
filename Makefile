# Running a command like this will push tags like base_123, development_123, and
# production_123 to the private repo:
#
# DOCKER_IMAGE_TAG=123 DOCKER_PUBLISH_PREFIX=repo.name.here/username make

.PHONY: base_container production_container docker

# The name of the image created by this project
DOCKER_IMAGE = makeexample

ifndef DOCKER_PUBLISH_PREFIX
	# Default tag is oskarpearson/${DOCKER_IMAGE}/${DOCKER_IMAGE}:tagvalue
	DOCKER_PUBLISH_PREFIX = 10.240.64.76:5000
endif

ifndef DOCKER_IMAGE_TAG
	DOCKER_IMAGE_TAG = localbuild
endif

# Default: tag and push containers
all:  build_all_containers tag push
	@echo Build Complete

# Build all docker containers
build_all_containers: base_container

base_container: base_container
	# cat docker/Dockerfile-base | sed -e "s/FROM ${DOCKER_IMAGE}:base_localbuild/FROM ${DOCKER_IMAGE}:base_${DOCKER_IMAGE_TAG}/g" > Dockerfile
	# Store the repo offset into the Dockerfile. We do this as the very last
	# step of each container (not the Base container) to avoid invalidating caching.

	cp docker/Dockerfile-example ./Dockerfile
	printf "\nRUN echo version_number: ${DOCKER_IMAGE_TAG} >> /.version.yml\n\n" >> Dockerfile
	printf "\nRUN echo build_date: `date -u '+%Y-%m-%dT%k:%M:%S%z'` >> /.version.yml\n\n" >> Dockerfile
	printf "\nRUN echo commit_id: `git rev-parse HEAD` >> /.version.yml\n\n" >> Dockerfile
	printf "\nRUN echo build_tag: ${JOB_NAME} ${BUILD_ID} >> /.version.yml\n\n" >> Dockerfile

	docker build -t "${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}" .
	rm -f Dockerfile

# Tag repos
tag:
ifeq (${DOCKER_IMAGE_TAG}, localbuild)
	@echo Not tagging localbuild containers
else
	docker tag -f "${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}" "${DOCKER_PUBLISH_PREFIX}/${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}"
	@echo Tagged successfully
endif

#Â Push tagged repos to the registry
push:
ifeq (${DOCKER_IMAGE_TAG}, localbuild)
	@echo Not pushing localbuild containers
else
	docker push "${DOCKER_PUBLISH_PREFIX}/${DOCKER_IMAGE}:${DOCKER_IMAGE_TAG}"

	@echo Pushed successfully
endif
