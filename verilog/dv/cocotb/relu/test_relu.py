from caravel_cocotb.caravel_interfaces import test_configure
from caravel_cocotb.caravel_interfaces import report_test
import cocotb
import json

@cocotb.test()
@report_test
async def relu_test(dut):
    caravelEnv = await test_configure(dut, timeout_cycles=100000)

    cocotb.log.info(f"[TEST] Start ReLU test")
    await caravelEnv.release_csb()
    await caravelEnv.wait_mgmt_gpio(1)
    cocotb.log.info(f"[TEST] Finish configuration")

    # Read input data from JSON file
    with open("fromlinear.json", "r") as file:
        input_data = json.load(file)

    output_data = []

    # Iterate over input data and perform ReLU operation
    for i in range(1000):
        data = input_data[i % len(input_data)]  # Wrap around input data if needed
        caravelEnv.drive_gpio(0, 1)  # Set relu_en
        caravelEnv.drive_gpio(1, data)  # Set input_data
        caravelEnv.drive_gpio(33, i % 32)  # Set input_addr
        await cocotb.triggers.ClockCycles(caravelEnv.clk, 1)
        caravelEnv.drive_gpio(0, 0)  # Clear relu_en

        await caravelEnv.wait_gpio(32, 1)  # Wait for output_valid
        output_value = int(caravelEnv.monitor_gpio(63, 32).binstr, 2)  # Read output_data
        output_addr = int(caravelEnv.monitor_gpio(68, 64).binstr, 2)  # Read output_addr
        cocotb.log.info(f"Input: {data}, Output: {output_value}, Address: {output_addr}")
        output_data.append(output_value)

    # Write the output data to the output file
    with open("relu_output.json", "w") as output_file:
        json.dump(output_data, output_file)
