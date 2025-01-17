PROJECT?=webapp1
PORT?=80
APPNAME=server
GONAME=microservice2
RELEASE?=0.0.3
COMMIT?=$(shell git rev-parse --short HEAD)
BUILD_TIME=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
GOOS=linux
GOARCH=amd64
APP=${PROJECT}
CONTAINER_IMAGE=docker.io/ianmaddocks/${APP}

RELEASE = $(file < VERSION)

.PHONY: clean test build build4mac container push run_native run_container

clean:
	@echo "clean..."
	rm -f ${APP}

test:
	@echo "test..."
	go test -v -race ./...

build: clean
	@echo "build..."
	@echo "settings: GOOS=" ${GOOS}", GOARCH="${GOARCH}", BuildTime="${BUILD_TIME}", Release="${RELEASE}", Commit=" ${COMMIT}
	CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build \
		-ldflags "-s -w \
		-X '${GONAME}/vn.Release=${RELEASE}' \
		-X '${GONAME}/vn.Commit=${COMMIT}' \
		-X '${GONAME}/vn.BuildTime=${BUILD_TIME}'" \
		-o ${APPNAME}

build4mac: clean
	@echo "build..."
	@echo "settings: BuildTime="${BUILD_TIME}", Release="${RELEASE}", Commit=" ${COMMIT}
	go build -ldflags "-s -w \
		-X '${GONAME}/vn.Release=${RELEASE}' \
		-X '${GONAME}/vn.Commit=${COMMIT}' \
		-X '${GONAME}/vn.BuildTime=${BUILD_TIME}'" \
		-o ${APPNAME}

container: build
	@echo "container.."
	docker image rm -f $(CONTAINER_IMAGE):$(RELEASE) || true
	docker build -f Dockerfile.scratch \
		-t $(CONTAINER_IMAGE):$(RELEASE) \
		-t $(CONTAINER_IMAGE):latest .

push: container
	@echo "push..."
	docker push -a $(CONTAINER_IMAGE)
	
run_native: build4mac
	@echo "run..."
	@echo "set PORT using 'export PORT=....'"
	./${APPNAME}

run_container: container
	@echo "run in a Docker container..."
	docker stop $(APP):$(RELEASE) || true && docker rm $(APP):$(RELEASE) || true
	docker run --name ${APP} -p ${PORT}:${PORT} --rm \
		-d -e "PORT=${PORT}" \
		${CONTAINER_IMAGE}:$(RELEASE)
