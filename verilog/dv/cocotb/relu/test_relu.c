#include <firmware_apis.h>

void main() {
    ManagmentGpio_outputEnable();
    ManagmentGpio_write(0);
    enableHkSpi(0); // Disable housekeeping SPI

    // Configure GPIOs
    GPIOs_configureAll(GPIO_MODE_USER_STD_OUT_MONITORED);
    GPIOs_configure(0, GPIO_MODE_USER_STD_OUT_MONITORED);  // relu_en
    GPIOs_configure(1, GPIO_MODE_USER_STD_OUT_MONITORED);  // input_data[0]
    // Configure remaining input_data pins (2-32)
    GPIOs_configure(33, GPIO_MODE_USER_STD_OUT_MONITORED); // input_addr[0]
    // Configure remaining input_addr pins (34-37)
    GPIOs_configure(32, GPIO_MODE_USER_STD_IN_MONITORED);  // output_valid
    // Configure output_data pins (38-69)
    // Configure output_addr pins (70-74)
    GPIOs_loadConfigs();

    ManagmentGpio_write(1); // Configuration finished

    return;
}
