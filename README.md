# DDM-conf-analysis

This repository contains the code for performing the analysis, computational modelling, and plotting described in the manuscript [Bayesian confidence in optimal decisions](https://doi.org/10.31234/osf.io/j8sxz).

Author (excluding submodules): [Joshua Calder-Travis](https://scholar.google.com/citations?user=-9asgxcAAAAJ&hl=en)

## Dependencies and setup
Some parts of the code need the [VBL toolbox](https://mbb-team.github.io/VBA-toolbox/) to be installed in order to run. Each session before using the code all the folders and subfolders in the respository should be added to the matlab path.

To run the plotting functions it is necessary to download the data and model fit results from the [associated OSF project](https://doi.org/10.17605/OSF.IO/QPSEM). All data and fits are contained in subfolders of the folder "DataAndFits". The path of the "DataAndFits" folder on your local system needs to be specified, so that the code can load the appropriate files. To do this, a matfile named '''confDataAndFitDir.mat''' should be saved in the main folder of the code respository. This matfile should contain a single variable `dataDir`, which contains the full file path of the "DataAndFits" folder on your system.

## Running the analyses
To make a wide range of plots of data and fits, including the plots in the paper, call `makePlotsForEmpiricalPaper()`. 

To perform in the fitting instead of using the fitting results supplied in the [associated OSF project](https://doi.org/10.17605/OSF.IO/QPSEM) the functions `runCrossValFits` and `fitModels` can be used with appropriate inputs to either run cross-validated model fitting, or fitting to all data without train-test splitting, respectively. See comments on those functions for more detail. The function `produceDefaultModelLists` provides a way of conveniently producing a list of the name-codes for the key models. Users wishing to run the fitting on a computer cluster will need to adapt the script `mT_runOneJob.sh` and `mT_submitAllJobs.sh` to their specific environment and cluster scheduling system. Results from a cluster can be collected and analysed using the `mT_analyseClusterResults` function.

## History 
Reviewed all code Jan 2024. The code has been carefully checked. Nevertheless, no guarantee or warranty is provided for any part of the code.
