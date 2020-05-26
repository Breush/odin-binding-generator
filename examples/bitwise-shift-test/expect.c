#include <stdio.h>

int
main(int argc, char **argv)
{
    // Left shifts
    for (int i = -12; i <= 12; i++) {
        int value;

        if (i < 0) {
            value = i << 1;
            printf("%d << %d = %d\n", i, 1, value);
        } else {
            value = 1 << i;
            printf("%d << %d = %d\n", 1, i, value);
        }
    }

    // Right shifts
    for (int i = -12; i <= 12; i++) {
        int value;

        value = i >> 1;
        printf("%d >> %d = %d\n", i, 1, value);
    }
}
