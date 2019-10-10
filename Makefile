all: install build test lint

# Install dependencies
install:
	# Frontend
	yarn install --pure-lockfile
	# Backend
	go mod vendor
	GO111MODULE=off go get -u golang.org/x/lint/golint

build: build-frontend build-backend
build-frontend:
	npm run dev-build
build-backend:
	env GOOS=linux go build -o -mod=vendor ./dist/zabbix-plugin_linux_amd64 ./pkg

dist: dist-frontend dist-backend
dist-frontend:
	npm run build
dist-backend: dist-backend-linux dist-backend-darwin dist-backend-windows
dist-backend-windows: extension = .exe
dist-backend-%:
	$(eval filename = zabbix-plugin_$*_amd64$(extension))
	env GOOS=$* GOARCH=amd64 go build -ldflags="-s -w" -mod=vendor -o ./dist/$(filename) ./pkg

.PHONY: test
test: test-frontend test-backend
test-frontend:
	npm run test
test-backend:
	go test -v -mod=vendor ./...
test-ci:
	npm run ci-test
	go test -race -coverprofile=tmp/coverage/golang/coverage.txt -covermode=atomic -mod=vendor

.PHONY: clean
clean:
	-rm -r ./dist/

.PHONY: lint
lint:
	npm run lint
	golint pkg/...
