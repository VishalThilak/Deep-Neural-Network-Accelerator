volatile unsigned *vga = (volatile unsigned *) 0x00004000; /* VGA adapter base address */

#include "vga_plot.c"
unsigned char pixel_list[] = {
#include "../misc/pixels.txt"
};
unsigned num_pixels = sizeof(pixel_list)/2;

unsigned char filled[160][120] = {0};

void fillscreen(void){
	/*Fill image pixels with white*/
	for(int x = 0; x < (num_pixels) * 2; x += 2){
        vga_plot(pixel_list[x], pixel_list[x + 1], 255);
		filled[pixel_list[x]][pixel_list[x + 1]] = 255; 
	}

	/*Fill non-image pixels with black*/
	for(unsigned y = 0; y <= 119; y++){
		for(unsigned x = 0; x <= 159; x++){
			if(filled[x][y] == 0){ 
				// vga_plot(pixel_list[x], pixel_list[y], 0); 
				// vga_plot((unsigned) pixel_list[x], (unsigned) pixel_list[x + 1], (unsigned) 0);
				vga_plot((unsigned) x, (unsigned) y, 0); 
				// filled[x][y] = 0; 
			}
		}
	}
}


void makeGray() {
    fillscreen();
    unsigned char weights[5][5] = {
        {1, 2, 4, 2, 1},  // Row -2
        {2, 4, 8, 4, 2},  // Row -1
        {4, 8, 16, 8, 4}, // Row  0
        {2, 4, 8, 4, 2},  // Row +1
        {1, 2, 4, 2, 1}   // Row +2
    };

    unsigned int weighted_sum = 0;
    unsigned char finalColour = 0;

    for (unsigned char y = 0; y < 120; y++) {
        for (unsigned char x = 0; x < 160; x++) {
            int x_start = (x - 2 < 0) ? 0 : x - 2;
            int x_end = (x + 2 >= 160) ? 159 : x + 2;
            int y_start = (y - 2 < 0) ? 0 : y - 2;
            int y_end = (y + 2 >= 120) ? 119 : y + 2;

            for (int dy = y_start; dy <= y_end; dy++) {
                for (int dx = x_start; dx <= x_end; dx++) {
                    weighted_sum += weights[dy - y + 2][dx - x + 2] * filled[dx][dy];
                }
            }

            finalColour = (weighted_sum) / 100;
            vga_plot(x, y, finalColour);

            weighted_sum = 0; // Reset for next pixel
        }
    }
}


int main()
{
	makeGray(); 
	return 0; 
}




// void makeGray(){
// 	fillscreen(); 
// 	unsigned char weights[5][5] = {
//         {1, 2, 4, 2, 1},  // Row -2
//         {2, 4, 8, 4, 2},  // Row -1
//         {4, 8, 16, 8, 4}, // Row  0
//         {2, 4, 8, 4, 2},  // Row +1
//         {1, 2, 4, 2, 1}   // Row +2
//     };

// 	unsigned char weighted_sum = 0; 
// 	unsigned char finalColour = 0; 
// 	for(unsigned char y = 0; y < 119; y++){
// 		for(unsigned char x = 0; x < 159; x++){

// 			for(unsigned char dy = -2; dy <= 2; dy++){
// 				for(unsigned char dx = -2; dx <= 2; dx++){
// 					// if(isValid(x + dx, y + dy)){
// 					if((x + dx) >= 0 && (x + dx) < 159 && (y + dy) >= 0 && (y + dy) < 119){
// 						weighted_sum += weights[dx + 2][dy + 2] * filled[x + dx][y + dy]; 
// 					}
// 				}
// 			}
// 			finalColour = weighted_sum / 100; 
// 			// vga_plot(x, y, finalColour); 
// 			vga_plot(x, y, finalColour);

// 			weighted_sum = 0; 
// 		}
// 	}
// }

