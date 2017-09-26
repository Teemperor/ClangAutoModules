#include <HEADER>
#include <HEADER> // Include twice, if HEADER has no header guards it shouldn't be in the modulemap and this will error in this case to filter it out.

int main() {} // if HEADER or a included header from HEADER defines main, this creates an error as we dont wan't those header in our modulemap.
