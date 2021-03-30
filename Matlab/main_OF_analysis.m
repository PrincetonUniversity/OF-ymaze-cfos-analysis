%% ---------------------------------------- %%
% Main script to analyze open field behavior %
% ------------------------------------------ %

%% set paths and load data 

% add matlab scripts to path
addpath(genpath(pwd))

% define paths
data_path = '../Data/';
metadata_path = './metadata/';
out_path = '../Output/';
fig_path = '../Figures/';

% load info about M classes
load([metadata_path 'manualSort.mat'],'sixSortedLabels','eightSortedLabels','sH4')

% frames per second
fps = 80;

% mm pro pixel
pixel_size = 1/1.97;

% turn unproblematic warnings off
% warning('off','MATLAB:xlswrite:AddSheet')
% warning('off','MATLAB:table:ModifiedVarnames')
% warning('off','MATLAB:handle_graphics:Layout:NoPositionSetInTiledChartLayout')

%% Fonts

set(groot,'defaultUicontrolFontName','Arial')
set(groot,'defaultUitableFontName','Arial')
set(groot,'defaultAxesFontName','Arial')
set(groot,'defaultTextFontName','Arial')
set(groot,'defaultUipanelFontName','Arial')

global legend_font_size
legend_font_size = 7;
global label_font_size
label_font_size = 9;
global title_font_size;
title_font_size = 9;
global axis_font_size;
axis_font_size = 8;
global text_font_size;
text_font_size = 8;
global point_size
point_size = 7;

%% Make M-state-info-files (used for further analysis of the data)
% before calculating the quantities saved in the M-state mat file, the data
% is processed as follows: 1) only the data from the first 2 days is
% considered, 2) all experiments are set to the same length (using the
% minimal frame length of all), 3) the data for Crus I mice is splitted
% into those with and without clearing

makeInfoFiles([data_path 'datasets/'], out_path, sH4); % 6 states (one locomotion behavior)

% add predicted behaviors to 6 states files with locomotion split into slow
% / medium / fast based on centroid velocity
splitLocomotionBehavior(out_path,fps,pixel_size)

%% ----------------------- %%
%        Visualization      %
%  ------------------------ %

% 8 behaviors (with locomotion splitted into slow / medium / fast)
M = 8; 
MSortedLabels = eightSortedLabels;
sH = sH4; % 6 behaviors (one group for locomotion)

colors = {[0 0 0],[0 0 0],[0 0 0],[0 0 0],[0 0 0]};
groups = {'AcuteCNOonly2D','AcuteCNOnLobVI1D','AcuteCNOnCrusI2D','AcuteCNOnCrusILT2D','AcuteCNOnCrusIRT2D'};
labels = {'Control','Lobule VI','Bilateral Crus I','Crus I Left','Crus I Right'};

colors_behaviors = [102,194,165;252,141,98;141,160,203;231,138,195;166,216,84;179,179,179;120,120,120;80,80,80]./255;

%% Main Figure A: Total distance travelled
compareSpatialMetrics(groups,labels,colors,fig_path,out_path,pixel_size,fps,6)

%% SI Figure 1A: Time in inner / outer region of OF
compareSpatialMetricsSI(groups,labels,colors,fig_path,out_path,pixel_size,fps,6)

%% SI Figure 1B: Limb coordination 
colors_paws = [205,32,41;61,80,157;166,75,156;142,205,212]./255; % RF,LF,RH,LH

groups_2 = {'AcuteCNOonly2D','AcuteCNOnLobVI1D','AcuteCNOnCrusI2D','AcuteCNOnCrusILT2D',...
    'AcuteCNOnCrusIRT2D','L7-Cre-Tsc1'};
labels_2 = {'Control','Lobule VI','Bilateral Crus I','Crus I Left','Crus I Right','L7-Tsc1 mutant'};
getLocomotionData(groups_2,out_path)
getDataLimbCoordination(out_path,pixel_size,fps)
plotLimbCoordination(out_path,labels_2,0.4,colors_paws,fig_path) 

% Example plot of mouse with paws labelled in colors used in
% polar plot
group = 'C57Bl';
day = 1;
mouse = 3;
frame = 985;
video_box_filename = [data_path 'OFT-0066-00_box_aligned.h5'];
exampleImageMousePaws(group,day,mouse,frame,colors_paws,[fig_path 'Figure_SI_1/'],out_path,video_box_filename)

%% Main Figure B: Mouse in OF with body parts labelled, ethogram
% Part 1: visualize pose tracking
group = 'C57Bl';
day = 1;
mouse = 3;
video_filename = [data_path 'OFT-0066-00_frame2827.h5']; 
mouse_info_filename = [data_path 'OFT-0066-00_box_aligned_info.mat'];
visualizeJointTracking(group,day,mouse,fig_path,out_path,video_filename,mouse_info_filename)

% Part 2: example ethogram
group = 'AcuteCNOonly2D'; 
day = 1;
mouse = 3;
exampleEthogram(group,day,mouse,fig_path,out_path,MSortedLabels,M,fps)

%% SI Figure 1C: centroid velocities of mice during different behaviors
plotVelocitiesBehaviors(groups,fig_path,out_path,eightSortedLabels,8,fps,pixel_size)

%% SI Figure 1D: Log-ratio differences of fractions of behaviors compared to control for day 1 and day 2

% Write data into table (used for statistical CoDa analysis in R)
days = [1,2];
saveDataInTable(groups,days,M,out_path,[out_path 'Mouse_behavior_data_set.csv'])

CoDAanalysis(groups,labels,[fig_path 'Figure_SI_1/'],out_path,MSortedLabels,M)

%% Main Figure D & SI Figure 1D: Comparison of fractions in behaviors on day 1, day 2 and day 1 vs day 2
compareBehaviorsStackedBoxPlot(groups,labels,fig_path,out_path,MSortedLabels,M,colors_behaviors)

%% SI Figure 1E: Change in fractions of behaviors from day 1 to day 2
compareChangeInFractions(groups,labels,[fig_path 'Figure_SI_1/'],out_path,MSortedLabels,M,colors)

%% Main Figure E & SI Figure 1F: transition matrices
plotTMs(groups, labels, fig_path, out_path, sixSortedLabels, 6)

%% Main Figure C: Temporal change of fraction in behavior
colors2 = {[0 0 0],[228,26,28]/255,[247 148 29]/255,[77,175,74]/255,[55,126,184]/255};
plotHabituation(groups,labels,colors2,[fig_path 'Main_Figure/'],out_path,MSortedLabels,fps,M)

%% SI Figure 2: comparison of controls
control_groups = {'AcuteCNOonly2D','AcuteVehicleonly2D','AcuteCNOnmcherry2D'};
control_labels = {'CNO only','Vehicle only','mCherry'};
colors = {[0 0 0],[0 0 0],[0 0 0]};

compareBehaviorsStackedBoxPlotSI(control_groups,control_labels,[fig_path 'Figure_SI_2/'],out_path,MSortedLabels,M,colors_behaviors)

% Write data into table (used for statistical CoDa analysis in R)
days = [1,2];
saveDataInTable(control_groups,days,M,out_path,[out_path 'Mouse_behavior_data_set_controls.csv'])

CoDAanalysisSI(control_groups,control_labels,[fig_path 'Figure_SI_2/'],out_path,MSortedLabels,M)

compareChangeInFractionsSI(control_groups,control_labels,[fig_path 'Figure_SI_2/'],out_path,MSortedLabels,M,colors)

%% Movie: behavioral classification of open field experiments
% video of mouse in OF, skeleton in OF and ethograms
group = 'C57Bl';
day = 1;
mouse = 3;
video_filename = [data_path 'OFT-0066-00_frames60000to60500.h5']; % raw OF images
video_box_filename = [data_path 'OFT-0066-00_box_aligned.h5'];
makeMovieCombinedOF(group,day,mouse,fig_path,out_path,video_filename,video_box_filename,MSortedLabels,M,fps,colors_behaviors)
