%% Beta Version 0.5.6 of Huxlin Lab FBA Training Program
% Built and tested on 2020 MacBook Pro with Intel processor
% Running Mac OS 10.15.7
% Matlab version 2020b 
% Add to compiler:
% 1) Fine Fitting folder <- Removed as of 11/16/20
% 2) Sound Files <- Windows only
%% Update 11/16/20
% Removed auto-fitting/movement section at end of program
% Was not proceeding correctly when deployed and created errors
% Will fit by hand for now
%% Update 11/20/20
% Patched error in post-training reporting. No change to functionality
%% Update 12/3/20
% Removed 1 second wait per trial
% Changed reporting of unfit threshold
% Removed previously commented auto-movement commands
%% Update 2/5/21
% Added compatibility with external keyboards
%% Update 5/10/21
% Updated pre-cue to new version with individual lines instead of triangle
%% Update 7/6/21
% Updated to Huxlin Lab credentials
%% Update 7/7/21
% Updated pre-cue to be agnostic to fixation point adjustments

%% Start of program - Checks if this is first session and loads appropriate data if yes or preallocated variables if no
try
    tStart = tic;
    %% Amazon Web Service login information
    setenv('AWS_ACCESS_KEY_ID', 'AKIAWW7VB773XRNEPGUT');
    setenv('AWS_SECRET_ACCESS_KEY', 'cknlbqGcBN7k4izb/DpRVyBzaSqrABmbx794LOhc');
    setenv('AWS_REGION', 'us-east-2');
    AWSPath = 's3://huxlinlabclinicaltrialbucket/';

    close_message4 = 'Your data could not be uploaded'; % Default message if no internet connection detected

    %%% Check for internet connection by querying Google
    url = java.net.URL('http://www.google.com');
    try
        link = openStream(url);
        parse = java.io.InputStreamReader(link);
        snip = java.io.BufferedReader(parse);
        if ~isempty(snip)
            flag = 1; % Internet detected
        else
            flag = 0; % Internet not detected
        end
    catch
        flag = 0; % Internet not detected due to error
    end

    %% Compare Subject ID number to access appropriate AWS S3 bucket
    % Asks for subject to enter ID number
    % If a matching ID number exists, load set-up data
    % If not, ask subject to re-enter information
    ID_entered = 0;
    while ID_entered == 0
        if flag % If connected to the internet
            try % Asks for subject ID/passcode   
                prompt = {'Enter ID#: '};
                dlg_title = 'Input';
                num_lines = 1;
                Patient_ID = inputdlg(prompt,dlg_title,num_lines);
                Patient_ID = num2str(Patient_ID{1});
                fds = fileDatastore(strcat(AWSPath,Patient_ID),'ReadFcn',@load,'FileExtensions',{'.mat'}); % Loads appropriate start up file from AWS
                ID_entered = 1;
            catch % If matching AWS bucket not found, breaks and displays error message, then asks to re-enter or quit
                ID_entered = 0;
                fig_height = 1080/4;
                fig_width = 1920/4;
                figure('Position',[1920/2-fig_width/2 1080/2-fig_height/2 fig_width fig_height],...
                'DockControls','off','MenuBar','none','NumberTitle','off')
                close_message = 'Account not detected';
                close_message2 = 'Please try again';
                mTextBox = uicontrol('style','text','Position',[0 fig_height*.75 fig_width 40],'FontSize',20);
                set(mTextBox,'String',close_message)
                mTextBox2 = uicontrol('style','text','Position', [0 fig_height*.60 fig_width 40],'FontSize',20);
                set(mTextBox2,'String',close_message2)

                btn1 = uicontrol('Style', 'pushbutton', 'String', 'Try again','Position', [fig_width/4-50 fig_height*.25 100 40],...
                    'Callback','uiresume','Callback','close all','FontSize',15);

                btn2 = uicontrol('Style', 'pushbutton', 'String', 'Quit','Position', [fig_width*.75-50 fig_height*.25 100 40],...
                    'Callback','close all','Callback','quit','FontSize',15);
                uiwait
            end
        elseif ~flag && isfile('localFDS.mat') % If internet is not detected, ask to run offline or restart
            fig_height = 1080/4;
            fig_width = 1920/4;
            figure('Position',[1920/2-fig_width/2 1080/2-fig_height/2 fig_width fig_height],...
            'DockControls','off','MenuBar','none','NumberTitle','off')
            close_message = 'No internet connection';
            close_message2 = 'Run offline?';
            mTextBox = uicontrol('style','text','Position',[0 fig_height*.75 fig_width 40],'FontSize',20);
            set(mTextBox,'String',close_message)
            mTextBox2 = uicontrol('style','text','Position', [0 fig_height*.60 fig_width 40],'FontSize',20);
            set(mTextBox2,'String',close_message2)

            btn1 = uicontrol('Style', 'pushbutton', 'String', 'Offline','Position', [fig_width/4-50 fig_height*.25 100 40],...
                'Callback','uiresume','Callback','close all','FontSize',15);

            btn2 = uicontrol('Style', 'pushbutton', 'String', 'Quit','Position', [fig_width*.75-50 fig_height*.25 100 40],...
                'Callback','close all','Callback','quit','FontSize',15);

            uiwait
            ID_entered = 1;
            fds = fileDatastore('localFDS.mat','ReadFcn',@load,'FileExtensions',{'.mat'}); % Create fds from local file
        else 
            fig_height = 1080/4;
            fig_width = 1920/4;
            figure('Position',[1920/2-fig_width/2 1080/2-fig_height/2 fig_width fig_height],...
            'DockControls','off','MenuBar','none','NumberTitle','off')
            close_message = 'No internet connection or local file detected';
            close_message2 = 'Please connect to the internet and try again';
            mTextBox = uicontrol('style','text','Position',[0 fig_height*.75 fig_width 40],'FontSize',20);
            set(mTextBox,'String',close_message)
            mTextBox2 = uicontrol('style','text','Position', [0 fig_height*.60 fig_width 40],'FontSize',20);
            set(mTextBox2,'String',close_message2)

            btn1 = uicontrol('Style', 'pushbutton', 'String', 'Quit','Position', [fig_width*.4 fig_height*.25 100 40],...
                'Callback','close all','Callback','quit','FontSize',15);

            uiwait
        end
    end
    errorPath = strcat('s3://orfanematlabtestupload/',Patient_ID,'/ErrorBin');
    %% Load training parameters from AWS
    data = read(fds);

    % Training location information
    H_ecc_fix               = data.H_ecc_fix;
    H_ecc_stim              = data.H_ecc_stim;
    H_ecc_stim2             = data.H_ecc_stim2; 
    V_ecc_fix               = data.V_ecc_fix;
    V_ecc_stim              = data.V_ecc_stim; 
    V_ecc_stim2             = data.V_ecc_stim2;
    
    %% Randomization Function
    
    
    %%
    
    % Initialize Staircases
    n_staircases            = data.n_staircases; 
    n_trials                = data.n_trials;
    angle_range             = data.angle_range;             % Possible angle range for stimulus (Difficulty levels)
    stair1                  = data.stair1;                  % Starting range for staircase 1
    stair2                  = data.stair2;                  % Starting range for staircase 2
    stair3                  = data.stair3;                  % Starting range for staircase 3
    staircount1             = 0;
    staircount2             = 0;
    staircount3             = 0;
    stair_array             = zeros(1,n_trials*n_staircases);    % Pre-allocates all trials

    % Monitor information
    frame_rate              = data.frame_rate; 
    resolution              = data.resolution; 
    screen_width            = data.screen_width;
    viewing_dist            = data.viewing_dist; 
    fig_width               = resolution(1)/4;
    fig_height              = resolution(2)/4;
    theta                   = atand((screen_width/2)/viewing_dist);
    scale_factor            = theta*60/(resolution(1)/2);               % Arcmin/pixel W = 2.8125 H = 3.125
    ISI                     = (1/frame_rate)*1000; 
    windowRect              = data.windowRect;
    % Beautification
    font                    = data.font;
    fontSize                = data.fontSize;
    fix_size                = data.fix_size;
    cue_color               = data.cue_color;
    cue_scale               = data.cue_scale;
    
    if IsWin
        osType = 1;
        [sound, rate] = audioread('chimes.wav');
        startSound = audioplayer(sound, rate);
        [sound, rate] = audioread('correct.wav');
        rightSound = audioplayer(sound, rate);
        [sound, rate] = audioread('LOWC.WAV'); 
        wrongSound = audioplayer(sound, rate);
    elseif ismac
        osType = 2;
        startSound = data.startSound;
        rightSound = data.rightSound;
        wrongSound = data.wrongSound;
    end

    % Automatic training movement and data storage
    required_STD            = data.required_STD;
    min_training_sessions   = data.min_training_sessions;
    screen_limit            = data.screen_limit;
    threshold_cutoff        = data.threshold_cutoff;
    
    X_movement_count        = data.X_movement_count;
    cumulativeResults       = data.cumulativeResults;
    training_count          = data.training_count;
    if isfile('trainingMonitoring.mat')
        load('trainingMonitoring.mat');
    end

    % Dot Stimulus Settings
    stimulus_duration       = data.stimulus_duration;      % ms
    aperture_radius         = data.aperture_radius;        % Degrees
    dot_density             = data.dot_density;            % Dots per square degree, 1.7 (Newsome&Pare '88)
    initial_dot_size        = data.initial_dot_size;       % diamteter, arcmin
    dot_color               = data.dot_color;              % Grayscale units
    dot_speed               = data.dot_speed;              % deg/s
    dot_lifetime            = data.dot_lifetime;           % in ms, for direction range only

    % Experiment Settings
    angle_set               = data.angle_set;              % Remember to set this 0 will be horizontal, 1 will be vertical
    background              = data.background;             % Grayscale Units
    cue_duration            = data.cue_duration;           % sec

    % Shift fixation if necessary
    fix_shift               = (H_ecc_fix*60)/scale_factor;
    fix_shift_y             = (V_ecc_fix*60)/scale_factor;

    % Pre-allocate other variables
    correct_trials          = 0;                                        % Preallocates variable to keep track of correct trials
    V_ecc_stim              = -V_ecc_stim;                              % Reverses the Y value to make it work with psychtoolbox
    results                 = zeros(n_trials*n_staircases,9);

    %% Suppresses warnings native to Psychtoolbox, shuffle trials, other housekeeping
    oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
    oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);
    Screen('Preference', 'SkipSyncTests', 1);
    KbName('UnifyKeyNames');
    rng('shuffle')                          % Shuffles trials to make each session unique

    if H_ecc_stim <= 0
        counterSide = 1;     % -1 for left // 1 for right
        H_ecc_stim                      = H_ecc_stim - X_movement_count;
    else
        counterSide = -1;    % -1 for left // 1 for right
        H_ecc_stim                      = H_ecc_stim + X_movement_count;
    end

    %-----Housekeeping----------------------
    % Scale things based on viewing distance, and convert other stuff to
    % the units PsychToolbox wants...
    h_ecc_orig                      = H_ecc_stim;  % Record stimulus X location
    v_ecc_orig                      = -V_ecc_stim; % Record stimulus Y location
    ndots                           = round(aperture_radius^2*pi*dot_density);
    stimulus_radius                 = 60*aperture_radius/scale_factor;
    H_ecc_stim                      = H_ecc_stim*60/scale_factor;
    H_ecc_fix                       = H_ecc_fix*60/scale_factor;
    V_ecc_stim                      = V_ecc_stim*60/scale_factor;
    V_ecc_fix                       = V_ecc_fix*60/scale_factor;
    dot_step                        = dot_speed*60/scale_factor/(1000/ISI);
    dot_size                        = floor(initial_dot_size/scale_factor);
    mv_length                       = round(stimulus_duration/(1000/frame_rate));
    age{1,mv_length}                = [];
    age(1:mv_length)                = {zeros(1, ndots)};
    positions{1,mv_length}          = [];
    postions(1:mv_length)           = {zeros(1, ndots)};

    % Conversions for direction ranges
    Radius                          = stimulus_radius;
    Velocity                        = dot_step;
    lifetime                        = dot_lifetime/(1000/frame_rate);

    % Randomize Trial Order
    total_trials                    = n_trials*n_staircases;
    perm                            = randperm(total_trials);
    perm                            = mod(perm,n_staircases)+1;
    bps                             = (stimulus_radius)*2+1;
    
    %% Open Screens to be used in session
    screens                         = Screen('Screens');
    screenNumber                    = max(screens);
    [w, rect] = Screen('OpenWindow',screenNumber,0,windowRect,[],2);
    Screen(w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    screen_rect                     = Screen('Rect',w);
    Screen('FillRect',w, background);
    Screen('Flip', w);
    Screen('FillRect',w, background);
    Screen('TextSize',w, fontSize);
    Screen('TextFont',w, font);
catch ErrorMessage1
    clear link parse snip
    save('openCrash.mat')
    try
        errorDS = datastore('openCrash.mat','Type','file','ReadFcn',@load,'FileExtensions',{'.mat'});
        errorTT = tall(errorDS);
        write(strcat(errorPath,'/', date,'/',num2str(now)),errorTT);
        delete openCrash.mat
    catch
    end
    fig_height = 1080/4;
    fig_width = 1920/4;
    figure('Position',[1920/2-fig_width/2 1080/2-fig_height/2 fig_width fig_height],...
    'DockControls','off','MenuBar','none','NumberTitle','off')
    close_message = 'There has been an error and the program is unable to open';
    close_message2 = 'Please try again or talk to Envision Tech Support';
    mTextBox = uicontrol('style','text','Position',[0 fig_height*.75 fig_width 50],'FontSize',20);
    set(mTextBox,'String',close_message)
    mTextBox2 = uicontrol('style','text','Position', [0 fig_height*.50 fig_width 50],'FontSize',20);
    set(mTextBox2,'String',close_message2)

    btn2 = uicontrol('Style', 'pushbutton', 'String', 'Quit','Position', [fig_width*.5-50 fig_height*.25 100 40],...
        'Callback','close all','Callback','quit','FontSize',15);
    uiwait
end

try
    % Setups where the stimulus will appear on the screen
    movie_rect                      = [0,0,bps,bps];
    scr_left_middle                 = fix(screen_rect(3)/2)-round(bps/2);
    scr_top                         = fix(screen_rect(4)/2)-round(bps/2);
    screen_rect_middle              = movie_rect + [scr_left_middle, scr_top, scr_left_middle, scr_top];
    screen_patch                    = screen_rect_middle+[H_ecc_stim,V_ecc_stim,H_ecc_stim,V_ecc_stim];
    sr_hor                          = round(screen_rect(3)/2);
    sr_ver                          = round(screen_rect(4)/2);
    fix_hor                         = sr_hor+H_ecc_fix;
    fix_ver                         = sr_ver+V_ecc_fix;
    stim_hor                        = sr_hor+H_ecc_stim;
    stim_ver                        = sr_ver+V_ecc_stim;
    fix_rect                        = SetRect(0, 0, fix_size*scale_factor, fix_size*scale_factor);
    fix_rect                        = CenterRectOnPoint(fix_rect,fix_hor,fix_ver);

    % Shuffles the staircases together
    for x = 1:n_staircases
        for i = 1:n_trials
            stair_array(i+n_trials*(x-1)) = x;
        end
    end
    stair_array = Shuffle(stair_array);

    %% Initial screen - Provides instructions to subject and information about training position/type
    if angle_set == 1
       Screen('DrawText',w,'Use the LEFT/RIGHT arrows to respond',100,130,0);
    else
       Screen('DrawText',w,'Use the UP/DOWN arrows to respond',100,130,0);
    end
    
    fix_rect2 = SetRect(0, 0, fix_size/2*scale_factor, fix_size/2*scale_factor);
    fix_rect2 = CenterRectOnPoint(fix_rect2,fix_hor,fix_ver);
    test_rect=SetRect(0,0, 2*scale_factor,  2*scale_factor);
    test_rect=CenterRectOnPoint(test_rect,stim_hor,stim_ver);
    test_rect2=SetRect(0, 0, 2.*stimulus_radius, 2.*stimulus_radius);
    test_rect2=CenterRectOnPoint(test_rect2,stim_hor,stim_ver);
    test_size = round((((stimulus_radius*2)/(resolution(1)/screen_width))*.394)*100)/100;
    test_size2 = round((((sqrt((fix_hor-stim_hor)^2 + (fix_ver-stim_ver)^2))/(resolution(1)/screen_width))*.394)*100)/100;
    Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2);
    Screen('FillRect',w,255,test_rect2); 
    Screen('FillRect',w,0,test_rect); 
    Screen('DrawLine',w,0,fix_hor,fix_ver,stim_hor,stim_ver);
    Screen('DrawText',w,strcat('Box width: ', num2str(test_size),' inches'),100,160,0);
    Screen('DrawText',w,strcat('Line length: ', num2str(test_size2), ' inches'),100,190,0);
    Screen('DrawText',w,strcat('Location: ', num2str(h_ecc_orig),', ', num2str(v_ecc_orig)),100,220,0);

    if flag == 1
        Screen('DrawText',w,strcat('Internet connection detected'),100,250,0);
    else
        Screen('DrawText',w,strcat('No internet connection detected'),100,250,0);
    end

    Screen('Flip',w);
    
    KbWait(-1); % Pauses program at initial screen until any key is pressed
    validKey = 0;

    %% Start of Training
    trial = 1;
    TSTART = tic;
    yy = [resolution(2)/2; resolution(2)/2 + 50; resolution(2)/2 - 50];
    while trial < total_trials + 1
        % Create counter of trials complete/total trials
        Screen('DrawText',w,[num2str(trial) '/' num2str(total_trials)], resolution(1)/2+resolution(1)/10.*counterSide, resolution(2)/2, 0);
        Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2); % Draws fixation point
        Screen('Flip',w); % Flips screen to present fixation point and counter
        direction = ceil(2*rand);
        orientation = round(rand);
        if orientation == 0
           orientation = -1;
        end

        %%% Selects the direction of the upcoming trial
        if direction == 2
            if angle_set == 0
                %orientation = 1 positive angle = up
                if orientation == 1
                    correct = 'UpArrow';
                    incorrect = 'DownArrow';
                    sig_move = [-1;0]; %x,y
                else
                    correct = 'DownArrow';
                    incorrect = 'UpArrow';
                    sig_move = [-1;0]; %x,y
                end
            else
                %negative angle = left, pos right
                if orientation == -1
                    correct = 'LeftArrow';
                    incorrect = 'RightArrow';
                    sig_move = [0;1]; %x,y
                else
                    correct = 'RightArrow';
                    incorrect = 'LeftArrow';
                    sig_move = [0;1]; %x,y
                end
            end
        elseif direction == 1
            if angle_set == 0
                %orientation = 1 positive angle = up
                if orientation == 1
                    incorrect = 'UpArrow';
                    correct = 'DownArrow';
                    sig_move = [-1;0]; %x,y
                else
                    incorrect = 'DownArrow';
                    correct = 'UpArrow';
                    sig_move = [-1;0]; %x,y
                end
            else
                %negative angle = left, pos right
                if orientation == -1
                    incorrect = 'LeftArrow';
                    correct = 'RightArrow';
                    sig_move = [0;1]; %x,y
                else
                    incorrect = 'RightArrow';
                    correct = 'LeftArrow';
                    sig_move = [0;1]; %x,y
                end
            end
        end

        %%% Adjusts staircase difficulty based on performance
        if staircount1 == 3
            stair1 = stair1 + 1;
            if stair1 > length(angle_range)
                stair1 = length(angle_range);
            end
            staircount1 = 0;
        end
        if staircount2 == 3
            stair2 = stair2 + 1;
            if stair2 > length(angle_range)
                stair2 = length(angle_range);
            end
            staircount2 = 0;
        end
        if staircount3 == 3
            stair3 = stair3 + 1;
            if stair3 > length(angle_range)
                stair3 = length(angle_range);
            end
            staircount3 = 0;
        end

        %%% Sets the difficulty of the current trial based on which staircase
        %%% is currently being used
        which_stair = stair_array(trial);
        if which_stair == 1
            angle_deviationP = angle_range(stair1);
        elseif which_stair == 2
            angle_deviationP = angle_range(stair2);
        elseif which_stair == 3
            angle_deviationP = angle_range(stair3);
        end

        if    angle_set==0 && direction==1
            angle=0+angle_deviationP*orientation;
        end
        if    angle_set==0 && direction==2
            angle=180+angle_deviationP*orientation;
        end
        if   angle_set==1 && direction==1
            angle=270+angle_deviationP*orientation;
        end
        if   angle_set==1 && direction==2
            angle=90+angle_deviationP*orientation;
        end

        yy(2) = resolution(2)/2+abs(angle_deviationP/scale_factor);
        yy(3) = resolution(2)/2-abs(angle_deviationP/scale_factor);
        if angle_deviationP < 5
            yy(2) = resolution(2)/2+abs(5/scale_factor);
            yy(3) = resolution(2)/2-abs(5/scale_factor);
        end

        %%% Draws the FBA pre-cue
        if direction == 2 %%% Left
            Screen('DrawLine', w, cue_color, fix_rect(1)+((fix_size/2)*scale_factor), fix_rect(2)+((fix_size/2)*scale_factor), fix_rect(1)-(cosd(angle_deviationP)*resolution(1)/cue_scale),...
                fix_rect(2)-(sind(angle_deviationP)*resolution(1)/cue_scale), 3);
            Screen('DrawLine', w, cue_color, fix_rect(1)+((fix_size/2)*scale_factor), fix_rect(2)+((fix_size/2)*scale_factor), fix_rect(1)-(cosd(angle_deviationP)*resolution(1)/cue_scale),...
                fix_rect(4)+(sind(angle_deviationP)*resolution(1)/cue_scale), 3);
        else %%% Right
            Screen('DrawLine', w, cue_color, fix_rect(1)+((fix_size/2)*scale_factor), fix_rect(2)+((fix_size/2)*scale_factor), fix_rect(3)+(cosd(angle_deviationP)*resolution(1)/cue_scale),...
                fix_rect(2)-(sind(angle_deviationP)*resolution(1)/cue_scale), 3);
            Screen('DrawLine', w, cue_color, fix_rect(1)+((fix_size/2)*scale_factor), fix_rect(2)+((fix_size/2)*scale_factor), fix_rect(3)+(cosd(angle_deviationP)*resolution(1)/cue_scale),...
                fix_rect(4)+(sind(angle_deviationP)*resolution(1)/cue_scale), 3);
        end
        
        Screen('DrawText',w,[num2str(trial) '/' num2str(total_trials)], resolution(1)/2+resolution(1)/10.*counterSide, resolution(2)/2, 0);
        Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2);
        Screen('Flip',w);

        WaitSecs(cue_duration);

        %%% Removes the cue
        Screen('DrawText',w,[num2str(trial) '/' num2str(total_trials)], resolution(1)/2+resolution(1)/10.*counterSide, resolution(2)/2, 0);
        Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2);
        Screen('Flip',w);           
        bb = GetSecs;

        %-----Position
        positions{1}(:,1) = (rand(ndots,1)-.5)*bps;
        positions{1}(:,2) = (rand(ndots,1)-.5)*bps;

        for i=1:ndots
            while sqrt(positions{1}(i,1)^2+positions{1}(i,2)^2)>stimulus_radius
                positions{1}(i,:) = [ceil((rand-0.5)*bps),ceil((rand-0.5)*bps)];
            end
        end
        vectors = pi*(angle+(normrnd(0,0,ndots,1)))/180;

        %-----Lifetime
        age{1} = ceil(lifetime*rand(ndots,1))';

        for j=2:mv_length
            %----------Update Dots----------
            for i=1:ndots
                %-----Move to new positions, wrap if necessary
                positions{j}(i,1) = positions{j-1}(i,1)+Velocity*cos(vectors(i));
                positions{j}(i,2) = positions{j-1}(i,2)+Velocity*sin(vectors(i));

                %-----Age dots
                age{j}(i) = age{j-1}(i)+1;
                %-----Kill and respawn dead dots
                if age{j}(i)>lifetime
                    positions{j}(i,1) = (rand-.5)*bps;
                    positions{j}(i,2) = (rand-.5)*bps;
                    age{j}(i) = 1;
                end

                if positions{j}(i,1)>Radius
                    positions{j}(i,1) = positions{j}(i,1)-bps;
                elseif positions{j}(i,1)<-Radius
                    positions{j}(i,1) = positions{j}(i,1)+bps;
                elseif positions{j}(i,2)>Radius
                    positions{j}(i,2) = positions{j}(i,2)-bps;
                elseif positions{j}(i,2)<-Radius
                    positions{j}(i,2) = positions{j}(i,2)+bps;
                end
                while sqrt(positions{j}(i,1)^2+positions{j}(i,2)^2)>stimulus_radius
                    positions{j}(i,:) = [ceil((rand-0.5)*bps),ceil((rand-0.5)*bps)];
                end
            end
        end
        %Finish the ITI
        WaitSecs(.5-(GetSecs-bb));
        priorityLevel=MaxPriority(w);
        Priority(priorityLevel);
        if osType == 1
            play(startSound);
        elseif osType == 2
            Beeper(1000)
        end
        WaitSecs(0.05);

        % Play the movie
        i=1;
        while i <= mv_length
            Screen('FillRect',w, background);
            Screen(w,'DrawDots',transpose(positions{i}),dot_size,dot_color,[stim_hor stim_ver],2);
            Screen('DrawText',w,[num2str(trial) '/' num2str(total_trials)], resolution(1)/2+resolution(1)/10.*counterSide, resolution(2)/2, 0);
            Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2);
            Screen('Flip',w);
            i=i+1;
            if i>mv_length
                break
            end
        end

        Screen('DrawText',w,[num2str(trial) '/' num2str(total_trials)], resolution(1)/2+resolution(1)/10.*counterSide, resolution(2)/2, 0);
        Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2);
        Screen('Flip', w);
        tic;
        Priority(0);
        %%% Get the response
        validKey = 0;
        while ~validKey
            [secs, keyCode, deltaSecs] = KbWait(-1);
            if keyCode(KbName(incorrect))
                rs=0;
                validKey = 1;
                if osType == 1
                    playblocking(wrongSound);
                elseif osType == 2
                    Beeper(800)
                end
                if which_stair == 1
                    results(trial,2) = angle_range(stair1);
                    stair1 = stair1 - 1;
                    staircount1 = 0;
                    if stair1 == 0
                        stair1 = 1;
                    end
                elseif which_stair == 2
                    results(trial,2) = angle_range(stair2);
                    stair2 = stair2 - 1;
                    staircount2 = 0;
                    if stair2 == 0
                        stair2 = 1;
                    end
                elseif which_stair == 3
                    results(trial,2) = angle_range(stair3);
                    stair3 = stair3 - 1;
                    staircount3 = 0;
                    if stair3 == 0
                        stair3 = 1;
                    end
                end
            elseif keyCode(KbName(correct))
                correct_trials = correct_trials+1;
                rs=1;
                validKey = 1;
                if osType == 1
                    playblocking(rightSound)
                elseif osType == 2
                    Beeper(1200)
                end
                results(trial,7) = 1;
                if which_stair == 1
                    staircount1 = staircount1 + 1;
                    results(trial,2) = angle_range(stair1);
                elseif which_stair == 2
                    staircount2 = staircount2 + 1;
                    results(trial,2) = angle_range(stair2);
                elseif which_stair == 3
                    staircount3 = staircount3 + 1;
                    results(trial,2) = angle_range(stair3);
                end
            elseif keyCode(KbName('ESCAPE'))
                %FlushEvents
                Screen('Flip',w);
                pause(.2)
                DrawFormattedText(w,strcat('Program Paused'),'center','center',0)
                DrawFormattedText(w,strcat(['Current trial: ', num2str(trial), '/', num2str(total_trials)]),'center',resolution(2)/2+30,0)
                DrawFormattedText(w,strcat('Press any key to continue, or ESC again to close'),'center',resolution(2)/2+90,0)
                Screen('Flip',w);
                [secs, keyCode, deltaSecs] = KbWait(-1);
                
                if keyCode(KbName('ESCAPE'))
                    clear link parse snip
                    save('patientQuit.mat')
                    quitDS = datastore('patientQuit.mat','Type','file','ReadFcn',@load,'FileExtensions',{'.mat'});
                    quitTT = tall(quitDS);
                    write(strcat(errorPath,'/', date,'/',num2str(now)),quitTT);
                    quit
                end
                Screen('Flip',w)
                validKey = 0;
            end
        end
        reaction_time = toc;
        results(trial,1) = trial;
        results(trial,3) = which_stair;
        results(trial,4) = direction;
        results(trial,5) = orientation;
        results(trial,6) = reaction_time;
        Screen('DrawText',w,[num2str(trial) '/' num2str(total_trials)], resolution(1)/2+resolution(1)/10.*counterSide, resolution(2)/2, 0);
        trial = trial+1;
        Screen('FillOval',w,0,fix_rect); Screen('FillOval',w,255,fix_rect2);
        Screen('Flip',w);
    end
catch ErrorMessage2
    Screen('CloseAll');
    clear link parse snip
    save('trainingCrash.mat')
    try
        errorDS = datastore('trainingCrash.mat','Type','file','ReadFcn',@load,'FileExtensions',{'.mat'});
        errorTT = tall(errorDS);
        write(strcat(errorPath,'/', date,'/',num2str(now)),errorTT);
        delete trainingCrash.mat
    catch
    end
    
    figure('Position',[resolution(1)/2-fig_width/2 resolution(2)/2-fig_height/2 fig_width fig_height],...
        'DockControls','off','MenuBar','none','NumberTitle','off')
    close_message = 'Error detected, program forced to close';
    close_message2 = 'Please contact your support team';
    mTextBox = uicontrol('style','text','Position',[0 fig_height*.75 fig_width 20],'FontSize',10);
    set(mTextBox,'String',close_message)
    mTextBox2 = uicontrol('style','text','Position', [0 fig_height*.60 fig_width 20],'FontSize',10);
    set(mTextBox2,'String',close_message2)

    btn1 = uicontrol('Style', 'pushbutton', 'String', 'Close','Position', [fig_width/2-25 fig_height*.25 50 20],...
        'Callback','close all','Callback','quit');
    uiwait
end
try
    %% End of program
    totalTime = toc(tStart); % Determine the length of the training session
    Screen('Flip',w);
    DrawFormattedText(w,strcat('Training Complete!'),'center','center',0);
    DrawFormattedText(w,strcat('Wrapping up...'),'center',resolution(2)/2 + 40,0);
    Screen('Flip',w);

    %%% Determine the date training was performed
    timer           = clock;
    time            = sprintf('%d%d%d%d%d',timer(2), timer(3), timer(1)-2000);
    time            = str2double(time);

    %%% Record end of session data and append as header to trial by trial data
    results2        = zeros(1,9);
    results2(1)     = time;
    results2(2)     = totalTime;
    results2(3)     = h_ecc_orig;
    results2(4)     = v_ecc_orig;
    results2(5)     = n_trials*n_staircases;
    results2(6)     = ((correct_trials)/total_trials)*100;
    results2(7)     = (angle_range(stair1)+angle_range(stair2)+angle_range(stair3))/3;
    results2(8)     = dot_speed;
    results2(9)     = stimulus_radius;
    results         = [results;results2];
    
    % reset Stair Values
    stair1 = 1;
    stair2 = 4;
    stair3 = 8;

    %%% Fit training data
    cumulativeResults = [cumulativeResults;results];
    training_count  = training_count + 1;

    clear link parse snip
    save trainingMonitoring.mat cumulativeResults X_movement_count training_count
    save('localFDS.mat')

    %% Email training results
    %%% Check for internet connection
    url = java.net.URL('http://www.google.com');
    % read the URL
    try
        link = openStream(url);
        parse = java.io.InputStreamReader(link);
        snip = java.io.BufferedReader(parse);
        if ~isempty(snip)
            flag = 1;
        else
            flag = 0;
        end
    catch
        flag = 0;
    end

    %% Send email with data file
    if flag
        ds = datastore('localFDS.mat','Type','file','ReadFcn',@load,'FileExtensions',{'.mat'});
        tt = tall(ds);
        write(strcat(AWSPath, Patient_ID,'/', date,'/',num2str(now)),tt);
        close_message4 = 'Your data has been successfully recorded';
    end

catch ErrorMessage3
    Screen('CloseAll');
    clear link parse snip
    save('saveCrash.mat')
    try
        errorDS = datastore('saveCrash.mat','Type','file','ReadFcn',@load,'FileExtensions',{'.mat'});
        errorTT = tall(errorDS);
        write(strcat(errorPath,'/', date,'/',num2str(now)),errorTT);
        delete saveCrash.mat
    catch
    end
    figure('Position',[resolution(1)/2-fig_width/2 resolution(2)/2-fig_height/2 fig_width fig_height],...
        'DockControls','off','MenuBar','none','NumberTitle','off')
    close_message = 'Error during saving';
    close_message2 = 'Please contact your support team';
    mTextBox = uicontrol('style','text','Position',[0 fig_height*.75 fig_width 20],'FontSize',10);
    set(mTextBox,'String',close_message)
    mTextBox2 = uicontrol('style','text','Position', [0 fig_height*.60 fig_width 20],'FontSize',10);
    set(mTextBox2,'String',close_message2)

    btn1 = uicontrol('Style', 'pushbutton', 'String', 'Close','Position', [fig_width/2-25 fig_height*.25 50 20],...
        'Callback','close all','Callback','quit');
    uiwait
end

%% End of program figure - Informs subject of performance
Screen('Flip',w);
DrawFormattedText(w,strcat('Training Complete!'),'center','center',0);
DrawFormattedText(w,strcat(['Final Score: ',num2str((correct_trials/total_trials)*100),...
    ' Percent Correct/Threshold: ',num2str(results2(7)),' degrees']),'center',resolution(2)/2+40,0);
DrawFormattedText(w,close_message4,'center',resolution(2)/2+80,0);
DrawFormattedText(w,strcat('Press any key to close'),'center',resolution(2)/2+120,0);
Screen('Flip',w);
KbWait(-1);

Screen('CloseAll');