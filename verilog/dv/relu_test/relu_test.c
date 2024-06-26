#include <stdio.h>
#include <stdlib.h>
#include "verilog/dv/caravel/defs.h"
#include "verilog/dv/caravel/stub.c"

#define REG_MPRJ_FSM_OPCODE (*(volatile uint32_t*)0x30000000)
#define REG_MPRJ_INPUT_DATA (*(volatile uint32_t*)0x30000004)
#define REG_MPRJ_OUTPUT_DATA (*(volatile uint32_t*)0x30000008)

void main()
{
    // Enable UART transmission
    reg_uart_enable = 1;

    // Configure I/O
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_28 = GPIO_MODE_MGMT_STD_OUTPUT;

    // Apply configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);

    // Signal start of the test
    reg_mprj_datal = 0xAB400000;

    // Test data
    int32_t test_data[] = {-5, -1, 0, 1, 5};
    int num_tests = sizeof(test_data) / sizeof(test_data[0]);

    for (int i = 0; i < num_tests; i++) {
        // Write input data
        REG_MPRJ_INPUT_DATA = test_data[i];

        // Trigger ReLU operation (opcode 0101)
        REG_MPRJ_FSM_OPCODE = 0x5;

        // Wait for processing to complete (you might need to adjust this)
        for (volatile int j = 0; j < 1000; j++);

        // Read output data
        int32_t output = REG_MPRJ_OUTPUT_DATA;

        // Print result
        printf("Input: %ld, Output: %ld\n", test_data[i], output);
    }

    // Signal end of test
    reg_mprj_datal = 0xAB510000;
}