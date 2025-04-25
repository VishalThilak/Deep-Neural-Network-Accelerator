// volatile unsigned *vga2 = (volatile unsigned *) 0x00004000; /* VGA adapter base address */


static inline void vga_plot(unsigned x, unsigned y, unsigned colour)
{
    extern volatile unsigned *vga;
    if(x < 0 || x > 159 || y < 0 || y > 119){
        return;
    } else{
        *vga = y << 24 | x << 16 | colour;
        return; 
    }


}
