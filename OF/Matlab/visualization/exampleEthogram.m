function [] = exampleEthogram(group,day,mouse,fig_path,out_path,MSortedLabels,M,fps)
% EXAMPLEETHOGRAM: plot example ethogram
%
% Input:
% - group: experimental group of interest
% - day: day of interest
% - mouse: id of mouse of interest
% - fig_path: path to save figure
% - out_path: path to processed data
% - MSortedLabels: labels for M behavioral classes
% - M: number of behavioral classes
% - fps: frames per second

if ~exist(fig_path,'dir')
    mkdir(fig_path)
end

%% get the data for the mouse and day of interest

mfile = matfile([out_path num2str(6) 'states/' group '.mat']);

wrAllBehaviors = mfile.('wr_by_day_loco');
wr = wrAllBehaviors{day}{mouse};

fstart = 88900;
fend = 90100; 

%%
f = figure;
f.Units = 'centimeters';
f.Position = [10,10,6.5,4];
pos = get(f,'Position');
set(f,'PaperPositionMode','Auto','PaperUnits','centimeters','PaperSize',[pos(3)+0.1, pos(4)+0.1])
set(gcf,'color','w')

% ethogram
mat = zeros(M,fend-fstart+1);
wr_sel = wr(fstart:fend);
for i = 1:M
    mat(i,wr_sel == i) = i;
end
% select range of interest
frame_min = 1;
frame_max = fend-fstart+1;

mymap = [1 1 1; repmat([0.4 0.4 0.4],8,1)];
imagesc([(frame_min-0.5)/fps (frame_max-0.5)/fps],[1 M],flip(mat(:,frame_min:frame_max),1))
colormap(gca,mymap)
caxis([-0.5,8.5])
yticks(1:M)
yticklabels(flip(MSortedLabels))
ytickangle(0)
global label_font_size
xlabel('Time (s)','FontSize',label_font_size)
xline(0);
box off
global axis_font_size
set(gca,'FontSize',axis_font_size)

prepfig()

%%
fig_name = [fig_path 'Main_Figure/example_ethogram'];
print(gcf,[fig_name '.pdf'],'-dpdf','-r0');
close(gcf)
end
