clearvars
savefile = fullfile(pwd, 'Results', 'test_data.mat');
scripts = savescripts;

global fixLines fixWidth fixColor xcen ycen pxsize scr address
global t_frames contrast_order trialdur frame_dur esc_key
global grating flicker_wave contrasts bggrating bgpatches
global scr_diagonal scr_distance scr_no fixLength breakdur

subject_info = inputdlg({'Subject ID', 'Today''s date'}, 'Subject Info', 1, {'test', date});


try
%% Setup
Screen('Preference', 'SkipSyncTests', 0); % JUST FOR TESTING
scr_no = 0; % JUST FOR TESTING
% rng('shuffle');

t_frames = 6; % 29 frames yields frequency of 4.9655 at 144Hz
trialdur = 2.9;
breakdur = 5;
iti = 0.5;
contrasts = [0, 0.3, 0.99];
stimsize = 4;
cycperdeg = 1;
nrep = 10;

% Background Luminance
scr_background = 127.5;


%% Set up Keyboard, Screen, Sound

% Variables related to Display
scr_diagonal = 17;
scr_distance = 60;
frame_dur = 1/60;

% Keyboard
KbName('UnifyKeyNames');
u_key = KbName('UpArrow');
d_key = KbName('DownArrow');
l_key = KbName('LeftArrow');
r_key = KbName('RightArrow');
esc_key = KbName('Escape');
ent_key = KbName('Return'); ent_key = ent_key(1);
keyList = zeros(1, 256);
keyList([u_key, d_key, esc_key, ent_key]) = 1;
KbQueueCreate([], keyList); clear keyList

% I/O driver
config_io;
address = hex2dec('DFB8');

% Sound
% InitializePsychSound;
% pa = PsychPortAudio('Open', [], [], [], [], [], 256);
% bp400 = PsychPortAudio('CreateBuffer', pa, [MakeBeep(400, 0.2); MakeBeep(400, 0.2)]);
% PsychPortAudio('FillBuffer', pa, bp400);

% Open Window
scr = Screen('OpenWindow', scr_no, scr_background);
HideCursor;
Screen('BlendFunction', scr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% Screen('TextFont', scr, 'Segoe UI Light');
Screen('TextSize', scr, 20);
scr_dimensions = Screen('Rect', scr_no);
xcen = scr_dimensions(3)/2;
ycen = scr_dimensions(4)/2;

% Display Configuring Screen
DrawFormattedText(scr, 'Configuring...', 'center', 'center', 0);
Screen('Flip', scr);


%% Prepare stimuli
% Stimsize
pxsize = visual_angle2pixel(stimsize, scr_diagonal, scr_distance, scr_no);
pxsize = pxsize + mod(pxsize, 2); % equalize

% Fixation Cue
fixWidth = 2; % make sure it doesn't exceed hardware max
fixLength = 8;
fixLines = [-fixLength, +fixLength, 0, 0; 0, 0, -fixLength, +fixLength];
fixColor = 0.2 * 255;

% Stimposition
offset = 0;
draw_rect = [xcen-pxsize/2, ycen-pxsize/2, xcen+pxsize/2, ycen+pxsize/2];
draw_rects = OffsetRect(draw_rect,...
                visual_angle2pixel(cosd([20, 160, 225, 315]')*5, scr_diagonal, scr_distance, scr_no),...
                visual_angle2pixel(sind([20, 160, 225, 315]')*5, scr_diagonal, scr_distance, scr_no));

% On-Off Flicker Wave
flicker_wave = (cos(linspace(pi, 3*pi, t_frames)) + 1)/2;

% Make Stimuli
% foreground stimulus
for iContrast = 1:numel(contrasts)
        contrast = contrasts(iContrast);
        grating_temp = make_grating(pxsize, cycperdeg*stimsize, contrast, 0, scr_background, 2*fixLength);
        grating{iContrast} = Screen('MakeTexture', scr, grating_temp);
        clear grating_temp;
end

% background stimulus
bgsize_pix = sqrt(2)*scr_dimensions(3);
bgsize_deg = pixel2visual_angle(bgsize_pix, scr_diagonal, scr_distance, scr_no);
bggrating = make_grating(2, cycperdeg*bgsize_deg, 0.8, 0, scr_background, 2*fixLength);
bggrating = Screen('MakeTexture', scr, bggrating);
bgpatches = Screen('MakeTexture', scr, cat(3, scr_background*repmat(ones(ceil(1.1*pxsize)), 1, 1, 3), 255*Circle(ceil(1.1*pxsize)/2)));


%% Trial Order
iTrial = 0;
for iContrast = 1:numel(contrasts)
    for iBackground = 0:1
        for iRep = 1:nrep
            iTrial = iTrial + 1;
            contrast_order(iTrial) = iContrast; 
            background_order(iTrial) = iBackground;
        end
    end
end

trial_order = randperm(iTrial);
contrast_order = contrast_order(trial_order);
background_order = background_order(trial_order);


%% Instructions
instrucs = ['In the following few trials, we just want to measure your brain response to\n\n',...
            'gratings of different contrasts. You just need to look at the cross in the centre,\n\n',...
            'and keep looking at the screen for one minute. There will be 20 seconds of break in\n\n',...
            'between each trial, but you are free to extend this break as long as you want. Start\n\n',...
            'each trial by pressing the space bar when you''re asked if you''re ready.\n\n\n',...
            'Press the space bar to continue.'];
DrawFormattedText(scr, instrucs, 'center', 'center', 0);
Screen('Flip', scr);
waitkey;


%% Demonstration

DrawFormattedText(scr, ['Practice Trial', '\n\nReady?'], 'center', ycen-pxsize/3, 0);
Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
Screen('Flip', scr);
waitkey;
Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
Screen('Flip', scr);
WaitSecs(1);

trial(max(contrasts), 1);
trialbreak;


%% Go through Trials
instrucs = ['We will now do about 3 minutes worth of these trials.\n\n',...
            'Press space whenever you''re ready.'];
DrawFormattedText(scr, instrucs, 'center', 'center', 0);
Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
Screen('Flip', scr);
waitkey;
Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
Screen('Flip', scr);
WaitSecs(1);

KbQueueStart;
for iTrial = 1:numel(contrast_order)
    trial(contrasts(contrast_order(iTrial)), background_order(iTrial));
    checkkey;
    WaitSecs(iti);
    if mod(iTrial, 10) == 0
        trialbreak;
    end
end
KbQueueStop;


%% Shut Down
KbQueueFlush;
KbQueueStop;
KbQueueRelease;
ListenChar(0);
sca;
save(fullfile(pwd, 'data', [date '-' subject_info{1} '.mat']));
PsychPortAudio('Close');
Priority(0);


catch err
    % Catch any errors
    KbQueueFlush;
    KbQueueStop;
    KbQueueRelease;
    ListenChar(0);
    sca;
    Priority(0);
    rethrow(err);
end


%% FUNCTIONS

function pressed = checkkey()
    global esc_key
    [~, pressed] = KbQueueCheck;
    if pressed(esc_key)
        error('Interrupted in the break!');
    end
end

function pressed = waitkey()
    global esc_key
    [~, pressed] = KbStrokeWait;
    if pressed(esc_key)
        error('Interrupted in the break!');
    end
end

function trigger(value)
    global address
    outp(address, 0);
    outp(address, round(value));
    WaitSecs(0.002);
    outp(address, 0);
    disp(value);
end

function trial(contrast, background)
    
    global fixLines fixWidth fixColor xcen ycen pxsize scr
    global t_frames trialdur frame_dur contrasts
    global grating flicker_wave bggrating bgpatches
    global scr_diagonal scr_distance scr_no fixLength
        
    trial_frames = ceil(trialdur / frame_dur);
    frame_stamp = zeros(size(1, trial_frames));
    
    % Trial
    Priority(1);
    trigger(background * 100 + contrast * 100);
    
    draw_rect = [xcen-pxsize/2, ycen-pxsize/2, xcen+pxsize/2, ycen+pxsize/2];
    draw_rects = OffsetRect(draw_rect,...
                    visual_angle2pixel(cosd([20, 160, 225, 315]')*5, scr_diagonal, scr_distance, scr_no),...
                    visual_angle2pixel(sind([20, 160, 225, 315]')*5, scr_diagonal, scr_distance, scr_no));
    for i = 1:trial_frames
        % draw background
        if background
            Screen('DrawTexture', scr, bggrating);
            Screen('DrawTextures', scr, bgpatches, [], draw_rects');
        end
        % draw foreground
        Screen('DrawTextures', scr, grating{contrasts==contrast}, [],...
            draw_rects', 0, [], flicker_wave(mod([i, i, i-t_frames/2, i-t_frames/2]-1, t_frames)+1));
        % draw fixation
        Screen('DrawTexture', scr, bgpatches, [], CenterRectOnPoint(fixLength*[-1, -1, 1, 1], xcen, ycen))
        Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
        frame_stamp(i) = Screen('Flip', scr);
        
        % waitkey;
    end
    disp(mean((frame_stamp(2:end)-frame_stamp(1:end-1))>(frame_dur*1.5)));

    % Clean Up
    Priority(0);
    Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
    Screen('Flip', scr);
end



function trialbreak()
    % Take a Break
    global scr breakdur ycen pxsize
    KbQueueStart;
    for lapsedTime = 0:breakdur
        DrawFormattedText(scr, ['Break for ' num2str(breakdur-lapsedTime)], 'center', ycen-pxsize/3, 0);
        Screen('Flip', scr);
        checkkey();
        WaitSecs(1);
    end
    KbQueueStop;
end