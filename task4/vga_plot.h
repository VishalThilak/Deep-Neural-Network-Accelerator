#ifndef VGA_PLOT_H
#define VGA_PLOT_H

extern volatile unsigned *vga; 

inline void vga_plot(unsigned x, unsigned y, unsigned colour);

#endif
