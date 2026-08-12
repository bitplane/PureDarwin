#ifndef PUREDARWIN_PCI_BUS_INFO_H
#define PUREDARWIN_PCI_BUS_INFO_H

#include <architecture/i386/pio.h>

// The imported driver carries an obsolete private copy of these helpers.
#define I386_PIO_H

typedef struct {
    union {
        struct {
            unsigned char configMethod1 : 1;
            unsigned char configMethod2 : 1;
            unsigned char : 2;
            unsigned char specialCycle1 : 1;
            unsigned char specialCycle2 : 1;
        } s;
        unsigned char d;
    } u_bus;
    unsigned char maxBusNum;
    unsigned char majorVersion;
    unsigned char minorVersion;
    unsigned char BIOSPresent;
} PCI_bus_info_t;

#endif
