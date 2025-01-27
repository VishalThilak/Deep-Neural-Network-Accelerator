# Deep-Neural-Network-Accelerator

## Overview
This project focuses on creating a deep neural network (DNN) accelerator for an embedded Nios II system. It classifies the MNIST hand-written digit dataset using a multi-layer perceptron (MLP) neural network. The system incorporates off-chip SDRAM for data storage, a VGA display for visual output, and hardware accelerators for performance optimization. All components are integrated using the Avalon on-chip interconnect protocol.

The project covers designing key modules such as PLLs, SDRAM controllers, and accelerators for tasks like memory copy and dot product calculations. The final system is deployed on an FPGA and is capable of efficient neural network inference.

---

## Features
- **MNIST Digit Classification:** Implements a pre-trained MLP neural network for inference.
- **Hardware Acceleration:** Includes DMA-based memory copy and dot product accelerators.
- **Fixed-Point Arithmetic:** Performs computations using Q16.16 fixed-point representation.
- **SDRAM Integration:** Interfaces with off-chip SDRAM to store weights and input data.
- **VGA Display:** Displays grayscale images processed by the system.
- **FPGA Deployment:** Designed to run on the DE1-SoC FPGA platform.

---

## Getting Started

### Prerequisites
- Intel Quartus Prime (version 18.1)
- Intel FPGA Monitor Program
- ModelSim for simulation
- DE1-SoC board

### Installation
1. **Install Intel Quartus Prime:** Download and install Quartus Prime from the Intel website.
2. **Install Intel FPGA Monitor Program:** Download and install from Intel's University Program site.
3. **Set Up ModelSim:** Ensure ModelSim is installed and configured for simulation with Quartus.


### How to Run
1. **Set Up Environment:**
   - Install Intel Quartus Prime (v18.1) and the FPGA Monitor Program.
   - Set up ModelSim for simulation tasks.
   - Use the DE1-SoC board for hardware debugging.

2. **Build the System:**
   - Use the Intel Platform Designer to configure the Nios II system, including SDRAM and PLL modules.
   - Add hardware components, including the VGA core and accelerators for memory and dot product operations.

3. **Simulate and Verify:**
   - Test the system in ModelSim using the SDRAM simulation model.
   - Debug functionality by inspecting registers, memory contents, and simulation waveforms.

4. **Deploy to FPGA:**
   - Generate the FPGA bitstream and program the DE1-SoC board.
   - Use the provided C programs to test VGA display, memory copy, and neural network inference.

5. **Run Neural Network Inference:**
   - Load pre-trained neural network weights and test images into SDRAM.
   - Execute the inference program to classify images and display results on the VGA screen.

---

## Key Components
- **PLL and SDRAM Controller:** Generates clock signals and manages off-chip SDRAM.
- **VGA Core:** Displays grayscale images processed by the system.
- **DMA-Based Accelerators:** Optimizes memory copy and dot product operations for performance.
- **Fixed-Point Arithmetic:** Ensures efficient hardware computation using Q16.16 arithmetic.

---
