
// https://github.com/Breush/odin-binding-generator/issues/7
const char issue_7_a[];
const char issue_7_b[][];
const char issue_7_c[42];
const char[] issue_7_d(void);
const char[42] issue_7_e() {}
const char *[42] issue_7_f() {}

#define BITWISE_NOT (~0U - 1)

// https://github.com/Breush/odin-binding-generator/pull/11
enum { // Left Shift A
    a1 = -12 << 1, // Expects -24
    b1 = -11 << 1, // Expects -22
    c1 = -10 << 1, // Expects -20
    d1 =  -9 << 1, // Expects -18
    e1 =  -8 << 1, // Expects -16
    f1 =  -7 << 1, // Expects -14
    g1 =  -6 << 1, // Expects -12
    h1 =  -5 << 1, // Expects -10
    i1 =  -4 << 1, // Expects -8
    j1 =  -3 << 1, // Expects -6
    k1 =  -2 << 1, // Expects -4
    l1 =  -1 << 1  // Expects -2
};

enum { // Left Shift B
    a2 = 1 << 0,  // Expects 1
    b2 = 1 << 1,  // Expects 2
    c2 = 1 << 2,  // Expects 4
    d2 = 1 << 3,  // Expects 8
    e2 = 1 << 4,  // Expects 16
    f2 = 1 << 5,  // Expects 32
    g2 = 1 << 6,  // Expects 64
    h2 = 1 << 7,  // Expects 128
    i2 = 1 << 8,  // Expects 256
    j2 = 1 << 9,  // Expects 512
    k2 = 1 << 10, // Expects 1024
    l2 = 1 << 11, // Expects 2048
    m2 = 1 << 12  // Expects 4096
};

enum { // Right Shift A
    a3 = -12 >> 1, // Expects -6
    b3 = -11 >> 1, // Expects -6
    c3 = -10 >> 1, // Expects -5
    d3 =  -9 >> 1, // Expects -5
    e3 =  -8 >> 1, // Expects -4
    f3 =  -7 >> 1, // Expects -4
    g3 =  -6 >> 1, // Expects -3
    h3 =  -5 >> 1, // Expects -3
    i3 =  -4 >> 1, // Expects -2
    j3 =  -3 >> 1, // Expects -2
    k3 =  -2 >> 1, // Expects -1
    l3 =  -1 >> 1  // Expects -1
};

enum { // Right Shift B
    a4 =  0 >> 1, // Expects 0
    b4 =  1 >> 1, // Expects 0
    c4 =  2 >> 1, // Expects 1
    d4 =  3 >> 1, // Expects 1
    e4 =  4 >> 1, // Expects 2
    f4 =  5 >> 1, // Expects 2
    g4 =  6 >> 1, // Expects 3
    h4 =  7 >> 1, // Expects 3
    i4 =  8 >> 1, // Expects 4
    j4 =  9 >> 1, // Expects 4
    k4 = 10 >> 1, // Expects 5
    l4 = 11 >> 1, // Expects 5
    m4 = 12 >> 1  // Expects 6
};

// https://github.com/Breush/odin-binding-generator/issues/13
float m0, m4, m8, m12;
float m1;

typedef struct matrix {
    float m0, m4, m8, m12;
    float m1;
} matrix;

// https://github.com/Breush/odin-binding-generator/issues/16
typedef int cookie_read_function_t(void *__cookie, char *__buf, int __nbytes);
typedef struct _IO_cookie_io_functions_t {
  cookie_read_function_t *read;
} cookie_io_functions_t;

// https://github.com/Breush/odin-binding-generator/issues/19
typedef unsigned __int64 uintptr_t;
typedef long int __ssize_t;
typedef __ssize_t ssize_t;
