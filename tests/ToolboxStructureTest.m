classdef ToolboxStructureTest < DreemTestCase
    % Catches declaration and documentation drift in drEEMtoolbox.m,
    % e.g. a method file that is no longer declared Static (doc, Oct 2026).

    properties (Constant)
        % Public methods that intentionally have no own HTML page / help header
        NoDocPage = ["doc","benchmark","displayhistory"]
    end

    methods (Test)
        function everyMethodFileIsStatic(tc)
            files = dir(fullfile(tc.RepoRoot,"toolbox","@drEEMtoolbox","*.m"));
            names = erase(string({files.name}),".m");
            names(names=="drEEMtoolbox") = [];
            ml = ?drEEMtoolbox;
            ml = ml.MethodList;
            for n = names
                m = ml(strcmp({ml.Name},n));
                tc.verifyNotEmpty(m, n + ".m is not a method of drEEMtoolbox")
                if ~isempty(m)
                    tc.verifyTrue(m(1).Static, n + ...
                        " is not declared in a Static methods block of drEEMtoolbox.m")
                end
            end
        end

        function publicMethodsAreDocumented(tc)
            root = fullfile(tc.RepoRoot,"toolbox");
            docList = fileread(fullfile(root,"@drEEMtoolbox","doc.m"));
            for n = publicMethods()
                if ismember(n,tc.NoDocPage), continue, end
                tc.verifyTrue(isfile(fullfile(root,"doc",n+".html")), ...
                    "missing toolbox/doc/" + n + ".html")
                tc.verifySubstring(docList, """" + n + """", ...
                    n + " is not in the allowed list of @drEEMtoolbox/doc.m")
                f = fullfile(root,"@drEEMtoolbox",n+".m");
                if isfile(f) % some methods are defined inside drEEMtoolbox.m
                    tc.verifySubstring(fileread(f), "drEEMtoolbox.doc('" + n + "')", ...
                        n + ".m has no help header linking to its documentation")
                end
            end
        end

        function versionIsConsistent(tc)
            v = string(drEEMtoolbox.version);

            toml = fileread(fullfile(tc.RepoRoot,"matlab.toml"));
            tv = regexp(toml,'(?m)^version = "([^"]+)"','tokens','once');
            tc.verifyEqual(string(tv{1}), v, "matlab.toml version differs from drEEMtoolbox.version")

            contents = fileread(fullfile(tc.RepoRoot,"toolbox","Contents.m"));
            cv = regexp(contents,'(?m)^% Version (\S+)','tokens','once');
            tc.verifyEqual(string(cv{1}), v, "toolbox/Contents.m version differs from drEEMtoolbox.version")

            id = regexp(toml,'(?m)^id = "([^"]+)"','tokens','once');
            tc.verifyEqual(string(id{1}), string(drEEMtoolbox.uuid), "matlab.toml id differs from drEEMtoolbox.uuid")
        end

        function declarationsMatchFiles(tc)
            src = fileread(fullfile(tc.RepoRoot,"toolbox","@drEEMtoolbox","drEEMtoolbox.m"));
            blk = extractBetween(src,"methods (Static = true , Access = public)",newline+"    end"+newline);
            tc.assertNotEmpty(blk,"public methods block not found in drEEMtoolbox.m")
            for line = splitlines(string(blk{1}))'
                decl = strtrim(extractBefore(line + "%","%"));
                if decl == "" || startsWith(decl,["function","end"]), continue, end
                name = regexp(decl,'^(?:[^=(]*=\s*)?(\w+)','tokens','once');
                if isempty(name), continue, end
                f = fullfile(tc.RepoRoot,"toolbox","@drEEMtoolbox",name{1}+".m");
                if ~isfile(f), continue, end    % inline methods such as validatedataset
                first = regexp(fileread(f),'(?m)^\s*function\s+(.*)$','tokens','once');
                tc.verifyEqual(erase(decl," "), erase(strtrim(first{1})," "), ...
                    name{1} + ": declaration in drEEMtoolbox.m differs from " + name{1} + ".m")
            end
        end
    end
end

function names = publicMethods()
ml = ?drEEMtoolbox;
ml = ml.MethodList;
keep = [ml.Static] & ~[ml.Hidden] & strcmp({ml.Access},"public") & ...
    arrayfun(@(m) m.DefiningClass.Name=="drEEMtoolbox", ml)';
names = unique(string({ml(keep).Name}));
names(names=="drEEMtoolbox") = [];
end
