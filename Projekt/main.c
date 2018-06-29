/**
 *
 * ASP Huffman Coding
 *
**/


extern int huffman_encode(char *, char *, unsigned int);
extern int huffman_decode(char *, char *, unsigned int);

#include <stdlib.h>
// a
#include <stdio.h>


int main(int argc, char **argv) {
		
printf("\nStart\n");

if (argc == 3 || argc == 4) {
			
		unsigned int fileLength;
		unsigned int resultSize;
		int outputSize;
		char *inputText;
		char *outputText;
			
		// open file containing input text from first parameter
		FILE *fInput = fopen(argv[1], "r");
		// exit if file wasn't properly loaded
		if (!fInput) {
			printf("Error opening file\n");
			return(-1);
		}
			
		// open/create file for output
		FILE *fOutput = fopen(argv[2], "w+");
		// exit if there is no file
		if (!fOutput) {
			fclose(fInput);
			printf("Error creating output file\n");
			return(-1);
		}

		printf("files loaded\n");
			
		// get number of chars in the inputFile
		fseek(fInput , 0L , SEEK_END);
		fileLength = ftell(fInput);
		rewind(fInput);

		// allocate memory for input
		inputText = calloc(1, fileLength + 1);
		// exit if memory wasn't allocated
		if(!inputText) {
			fclose(fInput);
			fclose(fOutput);
			printf("error allocationg memory\n");
			return(-1);
		}
		// allocate memory for output
		resultSize = fileLength;
		outputText = calloc(1, fileLength + 1);
		// exit if memory wasn't allocated
		if(!outputText) {
			fclose(fInput);
			fclose(fOutput);
			free(inputText);
			printf("error allocationg memory\n");
			return(-1);
		}

		// copy text to inputText, xit if it fails
		if(fread(inputText , fileLength, 1 , fInput) != 1) {
			fclose(fInput);
			free(inputText);
			free(outputText);
			printf("error reading file\n");
			return(-1);
		}
			
		fclose(fInput);
		printf("text from files copied\n");

		/*	encoding if third parameter = "-e" or ony two parameters
		 *	decoding if third parameter = "-d" 
		*/
		if(argc = 3 || argv[3] == "-e"){
			printf("start encoding\n");
			// encoding, returns length of result
			outputSize = huffman_encode(inputText, outputText, resultSize);
			// exit if result is too small
			if(outputSize == -1){
				printf("error encoding, result too small\n");
			}
			/* TESTING outputText[0] = inputText[0];
			outputText[1] = inputText[1];
			outputSize = 3;*/
			printf("create output file");
			// copy output to outputFile
			fwrite(outputText, outputSize, 1, fOutput);
		} else if(argv[3] == "-d"){
			printf("start decoding\n");
			// decoding, returns length of result
			outputSize = huffman_decode(inputText, outputText, resultSize);
			// exit if result is too small
			if(outputSize == -1){
				printf("error encoding, result too small\n");
			}
			/* TESTING outputText[0] = inputText[0];
			outputText[1] = inputText[1];
			outputSize = 3;*/
			printf("create output file\n");
			// copy output to outputFile
			fwrite(outputText, outputSize, 1, fOutput);
		} else {
			printf("error invalid parameter\n");
		}

		fclose(fOutput);
		free(inputText);
		free(outputText);
	} else {
		printf("Usage: %s MODE [args...]\n", argv[0]);
	}

	printf("\n");

	return 0;
}
