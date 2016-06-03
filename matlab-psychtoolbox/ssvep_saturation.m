clearvars
savefile = fullfile(pwd, 'Results', 'test_data.mat');
scripts = savescripts;
try
%% Setup
Screen('Preference', 'SkipSyncTests', 1); % JUST FOR TESTING
scr_no = 0; % JUST FOR TESTING
rng('shuffle');

% Target Frequency
t_frames = 12; % 29 frames yields frequency of 4.9655 at 144Hz

% Trial Duration
trialdur = 20;

% Break Duration
breakdur = 20;

% Contrasts
contrasts = [0 0.08, 0.16, 0.32, 0.64];

% Stimulus Size
stimsize = 12;

% Spatial Frequency
cycperdeg = 2;

% Repitions per Condition
nrep = 6;

% Background Luminance
scr_background = 127.5;


%% Set up Keyboard, Screen, Sound

% Variables related to Display
scr_diagonal = 13;
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
ListenChar(2);

% I/O driver
% config_io
address = hex2dec('D010');

% Sound
InitializePsychSound;
pa = PsychPortAudio('Open', [], [], [], [], [], 256);
bp400 = PsychPortAudio('CreateBuffer', pa, [MakeBeep(400, 0.2); MakeBeep(400, 0.2)]);
PsychPortAudio('FillBuffer', pa, bp400);

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
pxsize = pxsize + mod(pxsize, 2);

% Fixation Cue
fixWidth = 2; % make sure it doesn't exceed hardware max
fixLength = 8;
fixLines = [-fixLength, +fixLength, 0, 0; 0, 0, -fixLength, +fixLength];
fixColor = 0.2 * 255;

% Stimposition
offset = 0;
stimRect = [xcen-offset-pxsize/2, ycen-pxsize/2, xcen-offset+pxsize/2, ycen+pxsize/2];

% On-Off Flicker Wave
flicker_wave = (cos(linspace(pi, 3*pi, t_frames)) + 1)/2;

% Make Stimuli
% Maybe Stimuli should be made separately for each block
for iContrast = 1:numel(contrasts)
        contrast = contrasts(iContrast);
        grating_temp = make_grating(pxsize, cycperdeg*stimsize, contrast, 0, scr_background, 2*fixLength);
        grating{iContrast} = Screen('MakeTexture', scr, grating_temp); %#ok<SAGROW>
        clear grating_temp;
end


%% Trial Order
iTrial = 0;
for iContrast = 1:numel(contrasts)
    for iRep = 1:nrep
        iTrial = iTrial + 1;
        contrast_order(iTrial) = iContrast; %#ok<SAGROW>
        orientation_order(iTrial) = rand * 180; %#ok<SAGROW>
    end
end

trial_order = randperm(iTrial);
contrast_order = contrast_order(trial_order);


%% Instructions
instrucs = ['In the following few trials, we just want to measure your brain response to\n\n',...
            'gratings of different contrasts. You just need to look at the cross in the centre,\n\n',...
            'and keep looking at the screen for one minute. There will be 20 seconds of break in\n\n',...
            'between each trial, but you are free to extend this break as long as you want. Start\n\n',...
            'each trial by pressing the space bar when you''re asked if you''re ready.\n\n\n',...
            'Press the space bar to continue.'];
DrawFormattedText(scr, instrucs, 'center', 'center', 0);
Screen('Flip', scr);
KbStrokeWait;


%% Demonstration
% Pre-Trial
DrawFormattedText(scr, ['Practice Trial', '\nReady?'], 'center', ycen-pxsize/3, 0);
Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
Screen('Flip', scr);
KbStrokeWait;
Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
Screen('Flip', scr);
WaitSecs(3);

% Trial
trial_frames = ceil(0.5 * trialdur / frame_dur);
draw_angle = rand*180;
for i = 1:trial_frames;

    if mod(i, t_frames) == 0
        draw_angle = rand * 180; % update angle
    end

    Screen('DrawTexture', scr, grating{numel(contrasts)}, [], [], draw_angle, [], flicker_wave(mod(i-1, t_frames)+1));
    Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
    t_last = Screen('Flip', scr);
end

% Take a Break
KbQueueStart;
for lapsedTime = 0:breakdur
DrawFormattedText(scr, ['Break for ' num2str(breakdur-lapsedTime)], 'center', ycen-pxsize/3, 0);
Screen('Flip', scr);
[~, pressed] = KbQueueCheck;
if pressed(esc_key)
    error('Interrupted in the break!');
end
WaitSecs(1);
end
KbQueueStop;


%% Go through Trials
for iTrial = 1:numel(contrast_order)

    % Pre-Trial
    DrawFormattedText(scr, ['Trial ' num2str(iTrial) '\nReady?'], 'center', ycen-pxsize/3, 0);
    Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
    Screen('Flip', scr);
    KbStrokeWait;
    Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
    Screen('Flip', scr);
    WaitSecs(3);

    % Trial
    trial_frames = ceil(trialdur / frame_dur);
    frame_stamp = zeros(size(1, trial_frames));
    Priority(1);
    outp(address, contrast_order(iTrial));
    WaitSecs(0.002);
    outp(address, 0);
    draw_angle = rand * 180;
%     draw_rect = [xcen-pxsize/2, ycen-pxsize/2, xcen+pxsize/2, ycen+pxsize/2] + (rand-0.5)*pxsize*0.05*[1 0 1 0] + (rand-0.5)*pxsize*0.1*[0 1 0 1];
    draw_rect = [xcen-pxsize/2, ycen-pxsize/2, xcen+pxsize/2, ycen+pxsize/2];
    for i = 1:trial_frames;

        % Every time the matrix disappears, we change the angle and
        % position slightly
        if mod(i, t_frames) == 0
            draw_angle = rand * 180;
%             draw_rect = [xcen-pxsize/2, ycen-pxsize/2, xcen+pxsize/2, ycen+pxsize/2] +...
%                 (rand-0.5)*pxsize*0.05*[1 0 1 0] +... % horizontal shift
%                 (rand-0.5)*pxsize*0.05*[0 1 0 1]; % vertical shift
        end

        %  Screen('DrawTexture', scr, grating{contrast_order(iTrial)}(mod(i-1, t_frames)+1), [], [], orientation_order(iTrial));
        % the line below would change the orientation on each stimulus
        % cycle
        Screen('DrawTexture', scr, grating{contrast_order(iTrial)}, [], draw_rect, draw_angle, [], flicker_wave(mod(i-1, t_frames)+1));
%         Screen('DrawDots', scr, [0; 0], 3*fixLength, 127.5, [xcen, ycen], 2);
        Screen('DrawTexture', scr, fix_apert);
        Screen('DrawLines', scr, fixLines, fixWidth, fixColor, [xcen, ycen]);
        frame_stamp(i) = Screen('Flip', scr);
    end
    frames_dropped = mean((frame_stamp(2:end)-frame_stamp(1:end-1))>(frame_dur*1.5));

    % Clean Up
    outp(address, 255);
    WaitSecs(0.002);
    outp(address, 0);
    Priority(0);

    % Take a Break
    KbQueueStart;
    for lapsedTime = 0:breakdur
    DrawFormattedText(scr, ['Break for ' num2str(breakdur-lapsedTime)], 'center', ycen-pxsize/3, 0);
    DrawFormattedText(scr, sprintf('%2.1f %%', 100*frames_dropped), 0, 0, 0);
    Screen('Flip', scr);
    [~, pressed] = KbQueueCheck;
    if pressed(esc_key)
        error('Interrupted in the break!');
    end
    WaitSecs(1);
    end
    KbQueueStop;

end


%% Shut Down
KbQueueFlush;
KbQueueStop;
KbQueueRelease;
ListenChar(0);
sca;
PsychPortAudio('Close');
Priority(0);


catch err
%% Catch Errors
KbQueueFlush;
KbQueueStop;
KbQueueRelease;
ListenChar(0);
sca;
PsychPortAudio('Close');
Priority(0);
rethrow(err);


end
