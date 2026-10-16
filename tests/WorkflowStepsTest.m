classdef WorkflowStepsTest < DreemTestCase
    % alignsamples, associatemetadata and addcomment: the steps every import tutorial
    % runs. Small synthetic datasets; each sample's EEM is constant and equals the
    % number in its name (S03 -> 3), so rows can be traced through reordering.

    methods (Test)
        %% alignsamples
        function alignKeepsOnlyCommonSamplesInSameOrder(tc)
            a = named(["S01","S02","S03","S04"]);
            b = named(["S04","S02","S05"]);
            [a2,b2] = drEEMtoolbox.alignsamples(a,b);
            tc.verifyEqual(a2.filelist, b2.filelist)
            tc.verifyEqual(sort(a2.filelist), {'S02';'S04'})
            verifyRowsFollowNames(tc,a2)
            verifyRowsFollowNames(tc,b2)
            tc.verifyEqual(string(a2.history(end).fname), "alignsamples")
        end

        function alignThreeDatasets(tc)
            a = named(["S01","S02","S03"]);
            b = named(["S03","S02","S01"]);
            c = named(["S02","S03","S09"]);
            [a2,b2,c2] = drEEMtoolbox.alignsamples(a,b,c);
            tc.verifyEqual(a2.filelist, {'S02';'S03'})
            tc.verifyEqual(b2.filelist, a2.filelist)
            tc.verifyEqual(c2.filelist, a2.filelist)
            verifyRowsFollowNames(tc,b2)
        end

        function alignReordersWithoutRemoving(tc)
            a = named(["S01","S02","S03"]);
            b = named(["S03","S01","S02"]);
            [a2,b2] = drEEMtoolbox.alignsamples(a,b);
            tc.verifyEqual(b2.filelist, a2.filelist)
            tc.verifyEqual(b2.nSample, 3)
            verifyRowsFollowNames(tc,b2)
        end

        function alignWithoutCommonNamesErrors(tc)
            a = named(["S01","S02"]);
            b = named(["S03","S04"]);
            tc.verifyError(@() alignBoth(a,b), ?MException)
        end

        function alignResetsModelsWhenOrderChanges(tc)
            d = named(["S03","S01","S02"]);           % not in alphabetical order
            d = drEEMtoolbox.fitparafac(d,"fitoverall",f=1,starts=1, ...
                parallelization=false,consoleoutput="none");
            tc.assumeNotEmpty(drEEMdataset.modelsWithContent(d), "no model to reset")
            [d2,~] = drEEMtoolbox.alignsamples(d,d);
            tc.verifyEqual(d2.filelist, {'S01';'S02';'S03'})
            tc.verifyEmpty(drEEMdataset.modelsWithContent(d2), "scores no longer match the reordered samples")
        end

        function alignKeepsModelsWhenNothingChanges(tc)
            d = named(["S01","S02","S03"]);           % already in order
            d = drEEMtoolbox.fitparafac(d,"fitoverall",f=1,starts=1, ...
                parallelization=false,consoleoutput="none");
            [d2,~] = drEEMtoolbox.alignsamples(d,d);
            tc.verifyEqual(drEEMdataset.modelsWithContent(d2), drEEMdataset.modelsWithContent(d))
        end

        %% associatemetadata
        function metadataMatchesByNameIgnoringCase(tc)
            d = drEEMtoolbox.associatemetadata(named(["S01","S02","S03"]), metaTable(), "sampleId");
            tc.verifyEqual(d.metadata.depth, [10;20;30])
            tc.verifyEqual(string(d.metadata.site), ["A";"B";"C"])
            tc.verifyEqual(string(d.history(end).fname), "associatemetadata")
        end

        function unmatchedSamplesGetMissingMetadata(tc)
            md = metaTable();
            md = md(2:3,:);                                   % only S01 and S02
            d = drEEMtoolbox.associatemetadata(named(["S01","S02","S03"]), md, "sampleId");
            tc.verifyEqual(d.metadata.depth(1:2), [10;20])
            tc.verifyTrue(isnan(d.metadata.depth(3)))
        end

        function metadataFromSpreadsheet(tc)
            tc.useTempFolder();
            writetable(metaTable(), "meta.xlsx");
            d = drEEMtoolbox.associatemetadata(named(["S01","S02","S03"]), "meta.xlsx", "sampleId");
            tc.verifyEqual(d.metadata.depth, [10;20;30])
        end

        function duplicateMetadataKeysError(tc)
            md = metaTable();
            md = [md; md(2,:)];
            tc.verifyError(@() drEEMtoolbox.associatemetadata(named(["S01","S02","S03"]), md, "sampleId"), ?MException)
        end

        %% addcomment
        function commentIsAddedToLastStep(tc)
            d = named(["S01","S02"]);
            n = numel(d.history);
            d = drEEMtoolbox.addcomment(d,"checked by hand");
            tc.verifyNumElements(d.history, n)
            tc.verifyTrue(any(contains(string(d.history(end).usercomment),"checked by hand")))
        end

        function secondCommentIsAppended(tc)
            d = drEEMtoolbox.addcomment(named(["S01","S02"]),"first");
            d = drEEMtoolbox.addcomment(d,"second");
            c = string(d.history(end).usercomment);
            tc.verifyTrue(any(contains(c,"first")) && any(contains(c,"second")))
        end

        function newlineCommentIsOwnEntry(tc)
            d = named(["S01","S02"]);
            n = numel(d.history);
            d = drEEMtoolbox.addcomment(d,"own entry","newline");
            tc.verifyNumElements(d.history, n+1)
            tc.verifyEqual(string(d.history(end).fname), "addcomment: user comment")
        end

        function commentWithoutOutputErrors(tc)
            % nothing would be stored, so the call must not pass silently
            tc.verifyError(@() drEEMtoolbox.addcomment(named(["S01","S02"]),"lost"), ?MException)
        end
    end
end

function d = named(names)
% Constant EEMs whose value is the number in the sample name
values = str2double(extractAfter(names,1));
d = SyntheticData.constantDataset(values, 250:10:300, 300:10:350);
d.filelist = cellstr(names(:));
end

function verifyRowsFollowNames(tc,d)
expected = str2double(extractAfter(string(d.filelist),1));
tc.verifyEqual(d.X(:,1,1), expected, "EEM rows do not belong to their sample names")
end

function [a2,b2] = alignBoth(a,b)
[a2,b2] = drEEMtoolbox.alignsamples(a,b);
end

function md = metaTable()
md = table({'s03';'S01';'S02'}, [30;10;20], {'C';'A';'B'}, ...
    'VariableNames', {'sampleId','depth','site'});
end
