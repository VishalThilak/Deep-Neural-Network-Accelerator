volatile unsigned *dotprod_acc = (volatile unsigned *) 0x00001100;
volatile int *weights = (volatile int *) 0x08800000;
volatile int *ifmap = (volatile int *) 0x08900000;
volatile int *result = (volatile int *) 0x08A00000;

/* use hardware to compute dot product */
int dotprod_hw(int n_in, volatile int *w, volatile int *ifmap)
{
    *(dotprod_acc + 2) = (unsigned) w;
    *(dotprod_acc + 3) = (unsigned) ifmap;
    *(dotprod_acc + 5) = (unsigned) n_in;
    *dotprod_acc = 0; /* start */
    return *dotprod_acc; /* make sure the accelerator is finished */
}

void main() {
    *(weights) = 0x00090000;
    // *(weights + 1) = 0x0008000;
    // *(weights + 2) = 0x0007000;
    // *(weights + 3) = 0x0006000;
    // *(weights + 4) = 0x0005000;

    *(ifmap) = 0x00010000;
    // *(ifmap + 1) = 0x00020000;
    // *(ifmap + 2) = 0x00030000;
    // *(ifmap + 3) = 0x00040000;
    // *(ifmap + 4) = 0x00050000;


    //*result = 10;
    *result = dotprod_hw(1, weights, ifmap);

    return;
}