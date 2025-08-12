cd(fileparts(matlab.desktop.editor.getActiveFilename))

disp('<strong> starting to pack...</strong>')
% Change these for the release!!!
uuid="186c884d-4f97-4318-9f12-cbf90a332379";
version='2.25.09';
OutputFile=string(['/Users/wuensch/Documents/git/dreem-2/release/drEEM-test',version,'.mltbx']);


% Get old, make new opts
opts = matlab.addons.toolbox.ToolboxOptions(which("dreem-2.prj"));
optsNew=matlab.addons.toolbox.ToolboxOptions("/Users/wuensch/Documents/git/dreem-2/toolbox",uuid);
fnames=fieldnames(opts);
for j=1:numel(fnames)
    if matches(fnames{j},{'Identifier','ToolboxFolder'})
        continue
    else
        optsNew.(fnames{j})=opts.(fnames{j});
    end
end

optsNew.OutputFile=OutputFile;
optsNew.ToolboxVersion=version;

matlab.addons.toolbox.packageToolbox(optsNew)
disp('<strong> done...</strong>')