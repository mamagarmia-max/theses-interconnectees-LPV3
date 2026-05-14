# Makefile pour la validation CodeQL du S-Kernel V3
CC = g++
CFLAGS = -O3 -Wall

all: skernel_v3

skernel_v3: skernel_v3_cpp.cpp
	$(CC) $(CFLAGS) skernel_v3_cpp.cpp -o skernel_v3

clean:
	rm -f skernel_v3
