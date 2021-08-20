%% Huxlin Lab FBA Training Setup
clear all
% CB002 - 7/31/21

H_ecc_fix               = 0;    % Negative is left, Positive is right
H_ecc_stim              = -8;  % Negative is left, Positive is right
V_ecc_fix               = 0;   % Negative is up, Positive is down
V_ecc_stim              = -5;   % Negative is down, Positive is up

H_ecc_stim2             = 5;
V_ecc_stim2             = 5; 

n_staircases            = 3; 
n_trials                = 100;

cue_type                = 2; % 0 = none, 1 = neutral, 2 = cued

viewing_dist            = 42;
frame_rate              = 60; 
resolution              = [1920 1080]; 
screen_width            = 61;

%%% Do not edit below %%%
startSound              = 1000;
wrongSound              = 800;
rightSound              = 1200;

windowRect              = [];
font                    = 'Arial';
fontSize                = 20;
fix_size                = 8;
cue_color               = [255 255 255];

required_STD            = 20;
min_training_sessions   = 20;
screen_limit            = 20;
threshold_cutoff        = 20;

X_movement_count        = 0;
cumulativeResults       = [];
training_count          = 0;

stimulus_duration       = 500;                                          % ms
aperture_radius         = 2.5;                                          % Degrees
dot_density             = 3.5;                                          % Dots per square degree, 1.7 (Newsome&Pare '88)
initial_dot_size        = 14;                                           % diamteter, arcmin
dot_color               = 0;                                            % Grayscale units
dot_speed               = 10;                                            % deg/s
dot_lifetime            = 200;                                          % in ms, for direction range only

angle_set               = 0;                                            % Remember to set this 0 will be horizontal, 1 will be vertical
background              = 128;                                          % Grayscale Units
cue_duration            = .2;                                           % sec
cue_scale               = 110;                                          % 110 seems good, but still testing

angle_range             = [85 53.1 33.2 20.75 12.97 8.1 5.1 3.2 2.0 1.2 0.8 0.5];         % Possible angle range for stimulus (Difficulty levels)
stair1                  = 1;                                            % Starting range for staircase 1
stair2                  = 4;                                            % Starting range for staircase 2
stair3                  = 8;                                            % Starting range for staircase 3

save('TrainingSetup');