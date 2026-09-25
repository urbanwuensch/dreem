% Close project if open
cd(fileparts(matlab.desktop.editor.getActiveFilename))
initSession("vanilla",force=true)
cd ..
p=openProject("dreem-2.prj");
cd(fileparts(matlab.desktop.editor.getActiveFilename))

disp('<strong> starting to pack...</strong>')
% Never change this unless you want this to be treated as a seperate toolbox
uuid="8d87ad7f-ac6a-4500-af57-5e1bc1739a2b";
% Change these for the release!!!
version='2.26.9';
OutputFile=string(['/Users/wuensch/git repros/dreem-2/release/drEEM-',version,'.mltbx']);
if isfile(OutputFile),delete(OutputFile),disp('deleted existing mltbx file'),end
releaseMax="";

% Get old, make new opts
opts = matlab.addons.toolbox.ToolboxOptions(which("dreem-2.prj"));
optsNew=matlab.addons.toolbox.ToolboxOptions("/Users/wuensch/git repros/dreem-2/toolbox",uuid);
fnames=fieldnames(opts);
for j=1:numel(fnames)
    if matches(fnames{j},{'Identifier','ToolboxFolder'})
        continue
    else
        optsNew.(fnames{j})=opts.(fnames{j});
    end
end

% Overwrite some incorrect values that needed change compared to prj-file.
optsNew.OutputFile=OutputFile;
optsNew.ToolboxVersion=version;
optsNew.MaximumMatlabRelease=releaseMax;

matlab.addons.toolbox.packageToolbox(optsNew)
disp('<strong> done...</strong>')
initSession(force=true)
% Close project