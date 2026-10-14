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
