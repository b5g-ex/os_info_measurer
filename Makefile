all: build

build: src/test_caller.cpp
	g++ src/worker.cpp src/main.cpp -lpthread
	g++ src/test_caller.cpp -o src/test_caller

test: build
	./src/test_caller
	python3 ./src/test_caller.py

clean:
	rm -rf ./a.out
	rm -rf ./src/test_caller
