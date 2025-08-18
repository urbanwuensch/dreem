function [fighandleout] = dreemfig(fighandlein)
% <a href = "matlab:drEEMtoolbox.doc('dreemfig')">[fighandleout] = dreemfig(fighandlein) (click to access documentation)</a>
%
% <strong>Inputs - Required</strong>
% fighandlein (1,:)                 {mustBeA('matlab.ui.Figure')}

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
        % Inputs - Required
        fighandlein (1,1)                   {mustBeA(fighandlein,'matlab.ui.Figure')} = figure
end
FontSize=8;
FontName='Arial';
if ~exist('fighandlein','var')
    fighandlein=[];
end

if isempty(fighandlein) % Case: Make new figure
    fighandleout=figure('InvertHardcopy','off','Color',[1 1 1]);
%     fighandleout.Renderer='Painters';
    try
        set(fighandleout,...
            'defaultUicontrolFontName',FontName,...
            'defaultUitableFontName',FontName,...
            'defaultAxesFontName',FontName,...
            'defaultTextFontName',FontName,...
            'defaultUipanelFontName',FontName,...
            'defaultUicontrolFontSize',FontSize,...
            'defaultUitableFontSize',FontSize,...
            'defaultAxesFontSize',FontSize,...
            'defaultTextFontSize',FontSize,...
            'defaultUipanelFontSize',FontSize);
    catch
    end
elseif isgraphics(fighandlein) % Case: Make sure formatting is how we want it to be.
    ax = (findobj(fighandlein, 'type', 'axes'));
    for n=numel(ax):-1:1
        set(ax(n),'TickDir','out');
        set(ax(n),'FontSize',FontSize,'FontName',FontName);
        set(ax(n),'LineWidth',1.5);
    end
    fighandleout=fighandlein;
%     fighandleout.Renderer='Painters';
end
movegui(fighandleout,"center")

end
