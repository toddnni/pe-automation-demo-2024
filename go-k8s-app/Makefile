# Go parameters
APP_NAME := go-k8s-app
BUILD_DIR := ./bin
GO_FILES := $(shell find . -name '*.go' -type f)

# Default target executed when no arguments are provided
all: build

# Install dependencies
.PHONY: deps
deps:
	@echo ">> Getting dependencies"
	go mod tidy

# Format Go code
.PHONY: fmt
fmt:
	@echo ">> Formatting code"
	go fmt ./...

# Vet Go code for potential issues
.PHONY: vet
vet:
	@echo ">> Running go vet"
	go vet ./...

# Test the Go code
.PHONY: test
test:
	@echo ">> Running tests"
	go test -v ./...

# Build the Go application
.PHONY: build
build: $(GO_FILES)
	@echo ">> Building the app"
	mkdir -p $(BUILD_DIR)
	go build -o $(BUILD_DIR)/$(APP_NAME) ./cmd/main.go

# Clean the build directory
.PHONY: clean
clean:
	@echo ">> Cleaning up"
	rm -rf $(BUILD_DIR)

# Update the dependencies to their latest versions
.PHONY: update-deps
update-deps:
	@echo ">> Updating dependencies"
	go get -u ./...
	go mod tidy

# Run the Go application locally
.PHONY: run
run:
	@echo "Running the Go application..."
	DB_TYPE=sqlite DB_PATH=./bin/db.sqlite3 go run ./cmd/main.go
