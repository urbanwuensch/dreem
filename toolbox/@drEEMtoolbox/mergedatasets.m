function dataout = mergedatasets(a,b)

arguments (Input)
    a {mustBeA(a,'drEEMdataset')}
    b {mustBeA(b,'drEEMdataset')}

end

messages='<strong>Merging not possible:\n</strong>';
pass=true;
if not(isequal(a.Ex,b.Ex))
    messages=[messages,' Exication wavelengths not identical. \n'];
    pass=false;
end
if not(isequal(a.Em,b.Em))
    messages=[messages,' Emission wavelengths not identical. \n'];
    pass=false;
end
if not(isequal(a.absWave,b.absWave))
    messages=[messages,' Absorbance wavelengths not identical. \n'];
    pass=false;
end

C=intersect(a.metadata.Properties.VariableNames,b.metadata.Properties.VariableNames);

if not(numel(C)==width(a.metadata)&&numel(C)==width(b.metadata))
    messages=[messages,' Metadata table columns identical. \n'];
    pass=false;
end

if not(pass)
    throwAsCaller(MException("drEEM:NotIdentical",messages))
else
    dataout=drEEMdataset;
    dataout.abs=[a.abs;b.abs];
    dataout.absWave=a.absWave;
    dataout.nSample=size(dataout.abs,1);
    dataout.i=(1:dataout.nSample);
    dataout.metadata=[a.metadata;b.metadata];
    dataout.filelist=[a.filelist;b.filelist];
    dataout.X=[a.X;b.X];
    % Todo: XBlank absBlank
end

end