function prepfig()
% PREPFIG: set figure and axis parameters as desired

global axis_font_size

% set some graphical attributes of the current axis
set(gcf,'renderer','Painters') % rendering for eps-files
set(gca,'TickDir','out') % draw the tick marks on the outside
%set(gca,'PlotBoxAspectRatio',[1 1 1]) % Aspect Ratio
set(gca,'Color','w')
set(gcf,'Color','w') % match figure background
%set(gcf, 'Units', 'Inches', 'Position', [0, 0, 5, 5],...
%    'PaperUnits', 'Inches', 'PaperSize', [5, 5]) % size and location in inches
box off
set(gca,'FontSize',axis_font_size) % Creates an axes and sets its FontSize
set(gca, 'ycolor', 'k') % black axis
set(gca, 'xcolor', 'k')

end