function [] = visualizeJointTracking(group,day,mouse,fig_path,out_path,video_filename,mouse_info_filename)
% VISUALIZEJOINTTRACKING: plot image of mouse in open field arena and
% zoomed in version with body parts (from LEAP)
%
% Input:
% - group: experimental group of interest
% - day: day of interest
% - mouse: id of mouse of interest
% - fig_path: path to save figure
% - out_path: path to processed data
% - video_filename: path to h5 file with images of mouse in open field
% - mouse_info_filename: file with info about transformations from open
% field to box coordinates

%% get the data for the mouse and day of interest

fstart = 2827;
fsel = 0;

mfile = matfile([out_path 'k100/' group '.mat']);

joints = mfile.('dataLEAPout')(mouse,day);
joints = joints{1};

load(mouse_info_filename,'mouseInfo');
joints_OF = convertToRealCoordinates(joints, mouseInfo);

zoomed_box_xmin = round(min(joints_OF(:,1,fstart+fsel))-20);
zoomed_box_xmax = round(max(joints_OF(:,1,fstart+fsel))+20);
zoomed_box_ymin = round(min(joints_OF(:,2,fstart+fsel))-50);
zoomed_box_ymax = round(max(joints_OF(:,2,fstart+fsel))+50);

%% get the data from the raw mouse videos 
mouse_video_data = ...
    h5read(video_filename,'/pg0');

%% plot the mouse in the OF and a zoomed in version with the skeleton

f = figure;
f.Units = 'centimeters';
f.Position = [10,10,10,5];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3), pos(4)])
set(gcf,'color','w')

box_xmin = 80;
box_xmax = 80 + 886;
box_ymin = 180;
box_ymax = 180 + 886;

% raw mouse image in OF
subplot(1,6,1:2)
mouse_image_OF = mouse_video_data(box_ymin:box_ymax,box_xmin:box_xmax);
background = mouse_image_OF(mouse_image_OF < 13);
background = median(background,'all');
imagesc(mouse_image_OF-background)
hold on 
plot([0.5 box_xmax-box_xmin+0.5 box_xmax-box_xmin+0.5 0.5 0.5],...
    [0.5 0.5 box_ymax-box_ymin+0.5 box_ymax-box_ymin+0.5 0.5],'k','LineWidth',1.5)
hold on 
plot([zoomed_box_xmin-box_xmin zoomed_box_xmax-box_xmin zoomed_box_xmax-box_xmin zoomed_box_xmin-box_xmin zoomed_box_xmin-box_xmin],...
    [zoomed_box_ymin-box_ymin zoomed_box_ymin-box_ymin zoomed_box_ymax-box_ymin zoomed_box_ymax-box_ymin zoomed_box_ymin-box_ymin],'k')

cmap = flipud(gray(256));
colormap(gca,cmap);
axis equal off
set(gca,'YDir','normal')

% pose tracking result 
color = [221,28,119]./255;

subplot(1,6,4:6)
bps = [1 2 5 6 7 8 12 13 14 15 16];
mouse_image_zoomed = mouse_video_data(zoomed_box_ymin:zoomed_box_ymax,zoomed_box_xmin:zoomed_box_xmax,1+fsel);
background = mouse_image_zoomed(mouse_image_zoomed < 13);
background = median(background,'all');
imagesc(mouse_image_zoomed-background)
hold on 
scatter(joints_OF(bps,1,fstart+fsel)-zoomed_box_xmin+1,joints_OF(bps,2,fstart+fsel)-zoomed_box_ymin+1,5,'filled','MarkerEdgeColor',color,'MarkerFaceColor',color)
hold on 
% plot box around it
plot([0.5 zoomed_box_xmax-zoomed_box_xmin+1.5 zoomed_box_xmax-zoomed_box_xmin+1.5 0.5 0.5],...
    [0.5 0.5 zoomed_box_ymax-zoomed_box_ymin+1.5 zoomed_box_ymax-zoomed_box_ymin+1.5 0.5],'k')

cmap = flipud(gray(256));
colormap(gca,cmap);
axis equal off
set(gca,'YDir','normal')

%% save the figure
if ~exist([fig_path 'Main_Figure/'],'dir')
    mkdir([fig_path 'Main_Figure/'])
end

fig_name = [fig_path 'Main_Figure/joint_tracking.pdf'];
print(gcf,fig_name,'-dpdf','-r0');
close(gcf)

end
