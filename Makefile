.PHONY: build

build:
	CGO_ENABLED=0 GOOS=linux go build -o build/loand ./cmd/loand

install:
	go install ./cmd/loand

clean:
	rm -rf build/