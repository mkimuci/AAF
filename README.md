## Prerequisites

1. Install MATLAB and the following add-ons on Windows 10 or 11 (64-bit):
   - Image Processing Toolbox
   - Signal Processing Toolbox
  
2. Install Focusrite USB Driver
   - Legacy USB Driver 4.65.5 [here](https://downloads.focusrite.com/index.php/focusrite/scarlett-3rd-gen/scarlett-2i2-3rd-gen)
  
3. Download the Audapter MEX core
   - 64-bit Audapter MEX core Version blab-lab 2.3 from [here](https://github.com/blab-lab/audapter_mex/releases/download/release/Audapter.mexw64)
     
4. Git clone the following repos:
   - `audapter_matlab/` - BLAB fork of Audapter Matlab code from [here](https://github.com/blab-lab/audapter_matlab). Dependent on commoncode.
   - `commoncode/` - BLAB fork of Shanqing Cai's commoncode from [here](https://github.com/blab-lab/commonmcode). Note: Move this folder to the bottom your MATLAB path.
   - `free-speech/` - Speech Neuroimaging experiments codebase by Dr. Niziolek's lab from [here](https://github.com/carrien/free-speech).