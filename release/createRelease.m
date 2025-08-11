cd(fileparts(matlab.desktop.editor.getActiveFilename))
opts = matlab.addons.toolbox.ToolboxOptions(which("dreem-2.prj"));

uuid="186c884d-4f97-4318-9f12-cbf90a332379";
version='2.25.08';

OutputFile=string(['/Users/wuensch/Documents/git/dreem-2/release/drEEM-',version,'.mltbx']);

opts.OutputFile=OutputFile;
opts.ToolboxVersion=version;
opts.Identifier=uuid;

matlab.addons.toolbox.packageToolbox(opts)