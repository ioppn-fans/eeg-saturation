# This is an EEG Contrast Saturation script

# by Jan Freyberg (jan.freyberg@kcl.ac.uk)

# This script displays flickering gratings in order to measure the SSVEP
# response to gratings of different contrasts. You can set the number of
# contrasts to use, the number of trials, and the spatial and temporal
# frequency of the gratings at the top of the script.

# The rational behind this is that there should be a "saturation" of the
# contrast response at high contrasts, which is dependent on GABA.


from psychopy import visual, core, parallel, event, monitors, gui
import random
import numpy as np
import os
import os.path
# from tobiicontroller import TobiiController as tobiicontroller
from datetime import datetime

# Stimulus and Experiment Parameters
contrasts = [0.16, 0.32, 0.64, 1.0]  # the various contrasts to use
trialdur = 10.0  # the duration of each trial (secs)
breakdur = 5.0  # how long breaks should be (secs)
stimsize = 10.0  # how large the stimuli are (visual deg)
spatfreq = 2.0  # the spatial frequency of the gratings (cyc/deg)
tempfreq = 5.0  # the temporal frequency of the flicker (Hz)
repetitions = 6  # how many trials you want per condition (integer)
screenfreq = 60.0  # how fast the screen is (usually 60, 85, 120 or 144 Hz)
# tobiiid = 'TX300-010103441611'

debugging = False  # if you want a smaller window to still see code

# get info from gui
sessionInfo = {'subject': 'test',
               'time': datetime.now().strftime('%Y-%m-%d %H-%M')}
assert gui.DlgFromDict(dictionary=sessionInfo,
                       title='Pupil Dilation').OK

# Make a folder to store the data
datadir = os.path.join(os.getcwd(), 'eyedata',
                       sessionInfo['time'] + ' ' + sessionInfo['subject'],
                       '')
os.makedirs(datadir)

# Calculate the necessary parameters from user input
tempframes = screenfreq / tempfreq  # how many frames per cycle
trialframes = int(np.ceil(trialdur * screenfreq))  # how many frames per trial
ntrial = len(contrasts) * repetitions  # how many trials

# Set trial order randomization:
trialcontrasts = np.random.permutation(np.repeat(contrasts, repetitions))

# Set the screen parameters: (This is important!)
screen = monitors.Monitor('tobiix300')
screen.setSizePix([1920, 1080])  # screen resolution
screen.setWidth(51)  # screen width in cm
screen.setDistance(60)  # distance from screen in cm

# Open the display window:
win = visual.Window([500, 500], allowGUI=False, monitor=screen,
                    units='deg', fullscr=not debugging)
# Make a grating (to be changed later)
grating = visual.GratingStim(win, tex='sin', mask='raisedCos',
                             contrast=1, sf=spatfreq, size=stimsize)
# Make a fixation cross
fixation = visual.GratingStim(win, tex='sqr', mask='cross', sf=0, size=0.3,
                              pos=[0, 0], color='black', autoDraw=False)
# Make a dummy message
message = visual.TextStim(win, units='norm', pos=[0, 0.5], height=0.07,
                          alignVert='center', alignHoriz='center',
                          text='')

# Open a parallel port
outport = parallel.ParallelPort()
outport.setData(0)

# Open Tobii and activate
# tracker = None
# message.text = "Configuring..."
# message.draw()
# win.flip()
# print("Opening eye tracker connection...")
# tracker = tobiicontroller(win)
# tracker.waitForFindEyeTracker()  # this scans the network
# tracker.activate(tobiiid)  # this opens the tobii connection
# print("Confirming eyes are present...")
# tracker.findEyes()  # this mirrors the eyes on the screen
# print("Calibrating....")
# calibrated = False
# while not calibrated:
#     outcome = tracker.doCalibration()
#     if outcome is 'retry':
#         pass
#     elif outcome is 'abort':
#         raise KeyboardInterrupt("You interrupted the script.")
#     elif outcome is 'accept':
#         calibrated = True


# Define a trigger function (for calling later)
def trigger(value):
    outport.setData(value)  # set pins high
    # tracker.recordEvent('contrast %.2f trialstart' % float(value / 100))
    core.wait(0.002)  # wait so eeg picks it up
    outport.setData(0)  # set pins low again


# Define an instruction function
def instruct(displaystring):
    message.text = displaystring
    message.draw()
    win.flip()
    event.waitKeys(keyList=['space'])


# Define a break function (for calling later)
def trialBreak():
    # Choose a break image here:
    images = os.listdir('breakimages')
    breakimage = visual.ImageStim(win, units='norm',
                                  image=os.path.join(os.getcwd(), 'breakimages',
                                                     random.choice(images)))
    breaktext = visual.TextStim(win, alignVert='top', units='norm',
                                pos=[0, 1], text='')
    for breaktime in range(0, int(breakdur)):
        # Set message:
        breaktext.text = (
            "Break for " + str(breakdur - breaktime) + " seconds.")
        # draw, flip, then wait:
        breakimage.draw()
        breaktext.draw()
        win.flip()
        core.wait(1)
        # check for keys
        keys = event.getKeys(keyList=['escape', 'return'])
        if 'escape' in keys:
            # if escape, quit experiment
            win.flip()
            raise KeyboardInterrupt('You interrupted the script manually!')
        elif 'return' in keys:
            # if return, skip break
            win.flip()
            break
    # 'close' the graphics buffers used in the break
    breakimage = breaktext = None


# Define a trial function
def trial(contrast):
    # Set eyetracking directory
    # tracker.setDataFile(os.path.join(datadir,
    #                                  'trial %03d.csv' % trialnumber))

    # Update the grating contrast
    grating.contrast = contrast
    # display the fixation cross and wait for start:
    fixation.draw()
    instruct("Please focus your eyes on the cross, and begin "
             "the next trial by pressing [space].")

    # Also wait for fixation:
    # nb this auto-waits at least 500ms
    fixation.draw()
    win.flip()
    # tracker.waitForFixation(fixationPoint=fixation.pos)

    # delay trial start by another 500ms + some jitter
    # tracker.startTracking()
    core.wait(0.5 + 0.5 * np.random.rand())

    # Present stimuli:
    for iflip in range(1, trialframes):
        # Set opacity according to sinusoidal flicker:
        grating.opacity = np.cos(
            np.pi * (1 + 2 * (iflip % tempframes) / tempframes)
        ) / 2 + 0.5

        # set grating orientation new on each flip:
        if iflip % tempframes == 0:
            grating.ori = random.randrange(0, 180, 5)

        # Draw the stimulus, then flip:
        grating.draw()
        win.flip()
        # If this is the first flip then trigger
        if iflip == 1:
            trigger(int(100 * contrast))

        # check for keys, if pressed interrupt
        keys = event.getKeys(keyList=['escape', 'return'])
        if 'escape' in keys:
            # if escape, quit experiment
            win.flip()
            raise KeyboardInterrupt("You interrupted the script manually!")
        elif 'return' in keys:
            # if return, skip trial (for debug)
            win.flip()
            break
    # End eyetracking
    # tracker.stopTracking()


instruct("In this experiment we want to measure your brain's response to "
         "visual stimulation. You will see lines on the screen that flicker. "
         "Please keep your eyes focused on the center at the screen during "
         "each trial, and try not to blink. Each trial is 20 seconds long "
         "and there are breaks in between each trial. You start each trial "
         "by pressing the space bar. You can do so each time a cross "
         "appears on the screen. Please try and keep your eyes focused on "
         "the cross.\n\n"
         "Press [space] to continue.")
instruct("If you have any questions, please ask the experimenter now. If not, "
         "please check if the experimenter is ready, and then press [space] "
         "to start the experiment.")

# Step through trials
try:
    for trialnumber in range(ntrial):
        trial(trialcontrasts[trialnumber])
        # Call break function
        if trialnumber < (ntrial - 1):
            trialBreak()
finally:
    # Clean up:
    # tracker.destroy()
    core.quit()
