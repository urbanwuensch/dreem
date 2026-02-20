function saveAfterFunctionCall(fig,name)
arguments
    fig (1,1) {mustBeA(fig,'matlab.ui.Figure')}
    name (1,:) {mustBeText}
end


% Name digestion
name=char(name);
[filepath,fname,ext] = fileparts(name);

% First the filepath. Specify if it hasn't. Leave it if it was.
if isempty(filepath)
    filepath=pwd;
end

% Next, the filename. Include the calling function's name.
st = dbstack;
fname=[fname,'-',char(st(end).name)];

% Last the extension. Specify if it wasn't, police the extensions
if isempty(ext)
    ext='.png';
end
try
    mustBeMember(ext,[".jpg",".jpeg",".png",".tiff",".tif",".gif",".svg",".pdf",".eps"])
catch ME
    message=replace(ME.message,'Value ','Extension input to "figurefile" ');
    ME = MException('MATLAB:validators:mustBeMember',message);
    throwAsCaller(ME)
end

% reassemble the bits.
name=fullfile(filepath,[fname,ext]);

% Now check if that file exists and then add a counter to it.
if isfile(name)
    cnt=1;
    fnameorg=fname;
    while isfile(name)
        fname=[fnameorg,'-',num2str(cnt)];
        cnt=cnt+1;
        name=fullfile(filepath,[fname,ext]);
    end
end
    

% This is not clean, but works in current conditions.
% Exportgraphics fails if multiple "containers" exist in app.
% In this case, exportapp works.
try
    exportgraphics(fig,name, ...
        "BackgroundColor","white", ...
        "ContentType","auto", ...
        "Resolution",600, ...
        "PreserveAspectRatio","on",...
        "Padding","tight")
catch
    exportapp(fig,name)
end
warning on
end