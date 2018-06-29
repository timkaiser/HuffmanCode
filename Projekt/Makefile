# gepasp makefile
CC=gcc
# todo: Optimisierung und Name anpassen
TARGET= huffman
OPTIMIZATION=0
COPTS=-g -mcpu=cortex-a8 -mfpu=neon -mfloat-abi=hard -marm -o $(TARGET) -O$(OPTIMIZATION)

all: bin

bin: main.c huffman.S counter.S tree.S tree_to_code.S decode.S code.S
	$(CC) $(COPTS) $+ 

clean:
	rm $(TARGET)
