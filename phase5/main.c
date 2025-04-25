/*
 *
 *
 *
 *
 *
 *
 * WARNING
 *
 *
 * Much of this code has been modified from it's prior version.
 *
 * The prior version (visible in git history) was tested. This version has not been tested.
 *
 *
 *
 *
 *
 *
 */

// note: only **one** of the options below should be 1
// if multiples are set to 1, the topmost takes priority
// if all are set to 0, no acceleration is used (pure software)
#define DONE_TASK8 0  // add bias and optionally apply activation function
#define DONE_TASK7 0  // add on-chip SRAM
#define DONE_TASK6 0  // create dot product accelerator
#define DONE_TASK5 1  // create wordcopy accelerator

volatile unsigned *hex = (volatile unsigned *) 0x00001010; /* hex display PIO */
volatile unsigned *wordcopy_acc = (volatile unsigned *) 0x00001040; /* memory copy accelerator */
volatile unsigned *dotprod_acc  = (volatile unsigned *) 0x00001100; /* DOT product accelerator */
volatile unsigned *act_acc      = (volatile unsigned *) 0x00001200; /* DOT product + activation function accelerator */
volatile      int *vga          = (volatile      int *) 0x00004000; /* VGA adapter base address */
volatile      int *bank0        = (volatile      int *) 0x00006000; /* SRAM bank0 */
volatile      int *bank1        = (volatile      int *) 0x00007000; /* SRAM bank1 */

/* normally these would be contiguous but it's nice to know where they are for debugging */
volatile int *nn      = (volatile int *) 0x08000000; /* neural network biases and weights */
volatile int *input   = (volatile int *) 0x08800000; /* input image */
volatile int *l1_acts = (volatile int *) 0x08801000; /* activations of layer 1 */
volatile int *l2_acts = (volatile int *) 0x08802000; /* activations of layer 2 */
volatile int *l3_acts = (volatile int *) 0x08803000; /* activations of layer 3 (outputs) */

volatile int *src = (volatile int *) 0x08000000; 
volatile int *dst = (volatile int *) 0x09000000;

int len = 6;

void wordcopy_hw(volatile int *dst, volatile int *src, int n_words)
{
    *(wordcopy_acc + 1) = (unsigned) dst;
    *(wordcopy_acc + 2) = (unsigned) src;
    *(wordcopy_acc + 3) = (unsigned) n_words;
    *wordcopy_acc = 0; /* start */
    *wordcopy_acc; /* make sure the accelerator is finished */
}

void wordcopy_sw( volatile int *dst, volatile int *src, int n_words )
{
    // software version of wordcopy()
    for( int i = 0; i < n_words; i++ ) {
        dst[i] = src[i];
    }
}


void main() {
    *(src) = 1;
    *(src + 1) = 2;
    *(src + 2) = 3;
    *(src + 3) = 4;
    *(src + 4) = 5;
    *(src + 5) = 6;

    wordcopy_hw(dst, src, len);

    return;
}