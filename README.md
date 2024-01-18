# DDM-conf-analysis

This repository contains the code for performing the analysis, computational modelling, and plotting described in the manuscript [Bayesian confidence in optimal decisions](https://doi.org/10.31234/osf.io/j8sxz).

Author (excluding submodules): [Joshua Calder-Travis](https://scholar.google.com/citations?user=-9asgxcAAAAJ&hl=en)

## Dependencies and setup
Some parts of the code need the VBL toolbox to be installed in order to run (https://mbb-team.github.io/VBA-toolbox/). The VBL Toolbox code is not included as part of this repository.

To run the plotting functions it is necessary to download the data and model fit results from TODO.
The parent directory to which you download these data and model fits needs to be specified, so that the code can load the appropriate files as needed. To do this, a matfile named '''confDataAndFitDir.mat''' should be saved in the main folder of the code respository. This matfile should contain a single variable '''dataDir''', which contains the full file path of the parent folder on your system.

Each session before using the code all the subfolders in the respository should be added to the matlab path.

## Running the analyses
To make the plots, call the function ...
By default plots will be saved in a subfolder of the main folder of the 
respository '''PlotsAndResults''.

To run the fitting again, the following fuctions may be used...
It will be necessary to customise the function mT_runOneJob.sh to the specific cluster environment.

## History 
Reviewed all code Jan 2024.

The code has been carefully checked. Nevertheless, no guarantee or warranty is provided for any part of the code.