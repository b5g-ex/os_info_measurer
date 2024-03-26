all: build

build:
	g++ src/main.cpp

run:
	./a.out

clean:
	rm -rf ./a.out
