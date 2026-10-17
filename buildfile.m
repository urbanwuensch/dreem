function plan = buildfile
import matlab.buildtool.tasks.*
plan = buildplan(localfunctions);
plan("clean")  = CleanTask;
plan("check")  = CodeIssuesTask;
plan("test")   = TestTask("tests");

% Markdown pages (documentation/functions, documentation/tutorials) -> toolbox/doc
md = [dir("documentation/functions/*.md"); dir("documentation/tutorials/*.md")];
plan("docs").Inputs  = [string(fullfile({md.folder},{md.name})), ...
    "documentation/drEEM-new.css","buildUtilities/doc_template.html"];
plan("docs").Outputs = fullfile("toolbox","doc",erase(string({md.name}),".md") + ".html");

% Tutorial live scripts (toolbox/examples) -> toolbox/doc
plan("tutorials").Inputs  = fullfile("toolbox","examples",tutorialNames() + ".m");
plan("tutorials").Outputs = fullfile("toolbox","doc",tutorialNames() + ".html");

% All help pages -> one PDF with table of contents and bookmarks (not part of the package)
html = dir("toolbox/doc/*.html");
plan("pdf").Inputs  = [string(fullfile({html.folder},{html.name})), "buildUtilities/build_doc_pdf.py"];
plan("pdf").Outputs = "documentation/drEEM_toolbox_documentation.pdf";
plan("pdf").Dependencies = ["docs" "tutorials"];

plan("package") = PackageTask(Dependencies=["check" "test" "docs" "tutorials"]);
plan.DefaultTasks = "package";
end

function docsTask(~)
% Convert the Markdown documentation to the HTML help pages in toolbox/doc (requires pandoc)
pandoc = findPandoc();

% The stylesheet is embedded in every page, as in the MacDown exports
header = [tempname '.html'];
cleanup = onCleanup(@() delete(header));
writelines(["<style type=""text/css"">"; string(fileread("documentation/drEEM-new.css")); "</style>"], header);

sources = [dir("documentation/functions/*.md"); dir("documentation/tutorials/*.md")];
for k = 1:numel(sources)
    [~,name] = fileparts(sources(k).name);
    in  = fullfile(sources(k).folder, sources(k).name);
    out = fullfile("toolbox","doc", name + ".html");
    cmd = sprintf(['"%s" "%s" -f markdown-smart-implicit_figures -t html5 --standalone ' ...
        '--template="buildUtilities/doc_template.html" --include-in-header="%s" ' ...
        '--metadata pagetitle="%s" --wrap=none -o "%s"'], pandoc, in, header, name, out);

    fprintf("  %s\n", sources(k).name);
    [status,msg] = system(cmd);
    if status ~= 0
        error("drEEM:docsFailed","pandoc failed for %s:\n%s", sources(k).name, msg)
    end
end
fprintf("Converted %d documentation pages.\n", numel(sources))
end

function tutorialsTask(~)
% Export the tutorial live scripts, with the outputs saved in them, to toolbox/doc
for name = tutorialNames()
    in  = fullfile(pwd,"toolbox","examples",name + ".m");
    out = fullfile(pwd,"toolbox","doc",name + ".html");
    export(in, out);
end
fprintf("Exported %d tutorials.\n", numel(tutorialNames()))
end

function pdfTask(~)
% Combine all help pages into one PDF (requires Google Chrome and the Python package pypdf)
cmd = sprintf('"%s" "%s" "%s" "%s"', findPython(), ...
    fullfile(pwd,"buildUtilities","build_doc_pdf.py"), pwd, ...
    fullfile(pwd,"documentation","drEEM_toolbox_documentation.pdf"));
status = system(cmd);   % output (one line per page) goes straight to the command window
if status ~= 0
    error("drEEM:pdfFailed","Building the documentation PDF failed (see messages above).")
end
end

function exe = findPython()
% MATLAB started from the Dock does not see the shell PATH, so check the usual places too
candidates = ["/Library/Frameworks/Python.framework/Versions/Current/bin/python3", ...
    "/opt/homebrew/bin/python3","/usr/local/bin/python3"];
exe = candidates(find(isfile(candidates),1));
if isempty(exe)
    [status,where] = system("which python3");
    if status ~= 0
        error("drEEM:noPython","python3 not found. Install Python 3 and the package pypdf.")
    end
    exe = strtrim(string(where));
end
end

function names = tutorialNames()
names = ["dreem_workflow","import_tutorial_01","import_tutorial_02", ...
    "processing_tutorial_01","prepare4Parafac_tutorial","parafac_tutorial_01", ...
    "tutorial_export_01","tips_tricks"];
end

function exe = findPandoc()
% MATLAB started from the Dock does not see the shell PATH, so check the usual places too
candidates = ["/opt/homebrew/bin/pandoc","/usr/local/bin/pandoc"];
exe = candidates(find(isfile(candidates),1));
if isempty(exe)
    [status,where] = system("which pandoc");
    if status ~= 0
        error("drEEM:noPandoc","pandoc not found. Install it (macOS: brew install pandoc).")
    end
    exe = strtrim(string(where));
end
end