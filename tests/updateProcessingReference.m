function updateProcessingReference(names)
% Regenerate tests/reference/processing_fingerprints.mat after an INTENDED change
% to a processing method. Run from the tests folder with the project open:
%   cd tests; updateProcessingReference; cd ..                       % all cases
%   cd tests; updateProcessingReference("handlescatter_wide"); cd .. % selected cases
arguments
    names string = string.empty
end
root = fileparts(fileparts(mfilename("fullpath")));
f = ProcessingCases.referenceFile(root);

fingerprints = struct();
if isfile(f) && ~isempty(names)
    fingerprints = load(f).fingerprints;
end

cases = ProcessingCases.all();
if ~isempty(names)
    unknown = setdiff(names,[cases.name]);
    assert(isempty(unknown), "Unknown case(s): " + strjoin(unknown,", "))
    cases = cases(ismember([cases.name],names));
end

st = ProcessingCases.stages(root);
for c = cases
    fprintf("  %s\n", c.name);
    fingerprints.(c.name) = ProcessingCases.fingerprint(c.run(st));
end
delete(findall(groot,"Type","figure"))

if ~isfolder(fileparts(f))
    mkdir(fileparts(f))
end
save(f,"fingerprints");
fprintf("Saved %d case(s); reference now holds %d.\n", numel(cases), numel(fieldnames(fingerprints)));
end
