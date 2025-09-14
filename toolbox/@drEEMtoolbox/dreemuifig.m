function fig=dreemuifig
% <a href = "matlab:drEEMtoolbox.doc('dreemuifig')">f = dreemuifig (click to access documentation)</a>

% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
fig=uifigure(WindowStyle='normal');
s=dbstack;
origin=erase(s(end).file,'.m');
if isempty(origin)||matches(origin,'dreemuifig')
    origin='drEEM_results';
end
fig.Tag=origin;
clearvars origin

ctxMenu = uicontextmenu(fig);
uimenu(ctxMenu,Text='Save figure panel', ...
    MenuSelectedFcn= @(src, event) savepanel(fig));
fig.ContextMenu=ctxMenu;
movegui(fig,"center")
end




function savepanel(panel)

if isempty(panel)
    warning('Could not find a panel in the selected tab. Cannot save as image.')
    return
end
defname=[panel.Tag,'.png'];

[filename, pathname] = uiputfile({'*.png'; '*.jpg'},...
    'Save Figure As', ...
    defname);


if isequal(filename, 0) || isequal(pathname, 0)
    pathname=pwd;
    filename=defname;
    warning('Did not specify filename and path. Assumed default name in current directory.')
end


warning off
exportgraphics(panel,...
    fullfile(pathname,filename),...
    "BackgroundColor","white",...
    "Resolution",600)
warning on

figure(panel)

end