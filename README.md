# FPGAImageFiltering

# 1 Description
This project aims to enable the user to select a filter to be applied to a pre-loaded image and watch it be displayed using the VGA port. These requirements could also be expanded to allow input of the image, adding new filters, and sending the image back to the user’s computer. The built-in ports and buttons are intended to be used to make this possible, and an FSM will control the behaviour of the system. Ideally, this will leverage the FPGA board's powerful concurrent capabilities to implement filters such as black-and-white conversion, blurring, edge detection, and sharpening. The system will be mainly divided into a filtering module and a VGA controller. 
# 2 Top-level Diagram (inputs/outputs)
     The diagram represents the highest-level system inputs and outputs that the FPGA Image Filter will require. 

# 3 Preliminary Design of Datapath 
The following Datapath design and ASM chart describe the behaviour of the main project. Separately, a VGA controller, with its own signals, should be defined as the one in the Brightspace shell. 



# 4 Major Test Cases
Different Kernels can be selected, so running all the combinations through the image and displaying them correctly through VGA is essential. Apart from that, our state diagram has transitions that depend on START, and the control signals ROW, COL, and KERNEL that indicate that a row or column of the image or the kernel grid have been traversed; therefore, checking that the image is being processed correctly with the number that is being checked in both of those control signals would make tests were that value is modified to be more easily observed. 
Additionally, if memory is used, in the case of ROM or RAM, correct addressing that stays within bounds, for both reading, writing, and the convolution operations, would have to be verified. Finally, connecting it to a monitor via VGA should display an image that can also be generated with another tool to verify its correctness. 

# 5 Description of completion characteristics
     The completed FPGA image filter should be able to demonstrate four different types of image filtering: black-and-white, edge detection, blurring, and sharpening. Black-and-white filtering should convert the coloured image to a greyscale version, removing colour while maintaining brightness. The edge detection filter should detect edges and boundaries between objects in the image. The blurring filter should smooth the image, reducing the contrast between colours and light intensities, and the sharpening filter should do the opposite, emphasizing the image’s contrast edges and fine details by making them more distinct. 

# 6 Milestones
Milestone #1: Datapath implementation completed.
The VHDL code managing filter selection and all intermediate signals is completed. All states are defined, and all system inputs/outputs are managed. 
Milestone #2: Filters implementation completed.
The code that filters the images for all four filters is complete and connected to the datapath code.
Milestone #3: Image uploaded.
The image used to run the filters is uploaded and stored in the FPGA ROM/RAM.
Milestone #4: Completed testing.
All testing for the filters is run on the uploaded image and provides expected outputs. 
7 List of success criteria for the project 
Core filtering functionality is working on the uploaded image for all four filters:
Black and white
Edge detection
Blurring
Sharpening
The displayed filtered image on the VGA monitor is accurate and visually consistent with the original uploaded image.
The board’s switches apply the correct filtering to the uploaded image. 
The board’s keys apply the start and reset signals, triggering their corresponding system states. 
Reading and writing from the board’s memory does not result in errors. 
All edge cases handled properly without error. 
