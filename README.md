# TrainingCodes
This repository currently contains the Huxlin Lab home training code for Fine Direction Discrimination of an RDK stimulus with a Feature-Based attention pre-cue. This code is identical in stimulus and design to the FineDiscrimination_RDK code found in the TestingCodes respository. However, this code has been modified for home deployment to patient personal computers and is designed to be compiled with the Matlab Runtime Compiler for deployment. To function, the provided code will require modification to change the AWSPath to target your desired cloud bucket, as well as providing login credentials for that bucket (possibly in the form of a cognito access and/or secret key).

This program was used for the clinical trial NCT04798924.

This program was built in Matlab using Psychtoolbox and designed for use with Mac or Windows computers. Matlab and Psychtoolbox information are provided in the script. Modification may be required for use with other systems.
Parameters such as monitor information, testing location, stimulus size, dot density, contrast, and timing variables should be adjusted per patient and testing rig.

This training code may require a number of varying subfunctions to use properly. Most subfunctions are listed for the provided code, but may additionally require the supplied Eyelink Functions for eyetracking, as well as additional Matlab toolboxes.

This code is designed for use when deployed to a personal computer. Training parameters and rig setup parameters are provided by HuxlinLabFBASetup.m, which can be stored in AWS S3 or other cloud service to faciliate remote deployment.

Future training codes will be added to this repository as they are completed. All programs are works in progress and will potentially be updated in the future. Please check for updated programs to ensure use of the most reliable and robust scripts. Contact the Huxlin Lab for any additional inquiries or troubleshooting.
