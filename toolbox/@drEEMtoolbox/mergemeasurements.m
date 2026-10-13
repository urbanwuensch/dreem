function dataout = mergemeasurements(a,b,measurement,mode)

arguments (Input)
    a
    b
    measurement (1,:) {mustBeMember(measurement,["absorbance","fluorescence","supplementarySpectra"])}
    mode (1,:) {mustBeMember(mode,["replace","noreplace"])} = "replace"
end

arguments (Output)
    dataout
end

% Digest inputs and validate feasibility
switch measurement
    case "absorbance"
        if not(b.hasAbsorbance)
            error('input to "b" must have data in b.abs')
        end
        if a.hasAbsorbance
            if matches(mode,"replace")
                warning('In mode="replace" (default), data in a.abs will be overwritten')
            else
                matches(mode,"noreplace")
                error('a.abs already contains data, since mode="noreplace", the function must stop now.')
            end
        end
        measurement=replace(measurement,"absorbance","abs");
    case "fluorescence"
        if not(b.hasFluorescence)
            error('input to "b" must have data in b.X')
        end
        if a.hasFluorescence
            if matches(mode,"replace")
                warning('In mode="replace" (default), data in a.X will be overwritten')
            else
                matches(mode,"noreplace")
                error('a.X already contains data, since mode="noreplace", the function must stop now.')
            end
        end
        measurement=replace(measurement,"fluorescence","X");
    case "supplementarySpectra"
        if not(b.hasSupplementarySpectra)
            error('input to "b" must have data in b.suppSpectra')
        end
        if a.hasSupplementarySpectra
            if matches(mode,"replace")
                warning('In mode="replace" (default), data in a.suppSpectra will be overwritten')
            else
                matches(mode,"noreplace")
                error('a.suppSpectra already contains data, since mode="noreplace", the function must stop now.')
            end
        end
        measurement=replace(measurement,"supplementarySpectra","suppSpectra");
end

[C,ia,ib] = intersect(a.filelist,b.filelist,"stable");

if not(numel(C)==a.nSample)
    message='';
    ah=drEEMhistory.searchhistory(a.history,'alignsamples','last');
    bh=drEEMhistory.searchhistory(b.history,'alignsamples','last');
    if isempty(ah)|isempty(bh)
        message=[message,'You have not used "alignsamples" to align the sequence of measurements in your datasets.',newline];
    end
    message=[message,'The number of overlapping samples is less than the number of samples in "a". Some entries in ',char(measurement),' will contain missing numbers'];

    warning(message)
end

if matches(measurement,'X')
    a.(measurement)=nan(a.nSample,b.nEm,b.nEx);
    a.(measurement)(ia,:,:)=b.(measurement)(ib,:,:);
    a.Em=b.Em;
    a.Ex=b.Ex;
    a.nEm=b.nEm;
    a.nEx=b.nEx;
    
    stats={'spectralCorrection',...
        'IFEcorrection',...
        'blankSubtraction',...
        'signalCalibration',...
        'scatterTreatment',...
        'signalScaling'};


elseif matches(measurement,'abs')
    a.(measurement)=nan(a.nSample,numel(b.absWave));
    a.(measurement)(ia,:)=b.(measurement)(ib,:);

    a.absWave=b.absWave;

    stats={'absorbanceUnit'};

elseif matches(measurement,'suppSpectra')
    a.(measurement)=nan(a.nSample,numel(b.suppSpectraAxis));
    a.(measurement)(ia,:)=b.(measurement)(ib,:);

    a.suppSpectraAxis=b.suppSpectraAxis;
    stats={'suppSpectraInfo'};
end

for j=1:numel(stats)
    a.status=drEEMstatus.change(a.status,stats{j},b.status.(stats{j}));
end

dataout=a;
% Make drEEMhistory entry with message information

message=['Transfered measurements, axis information, and status of "',char(measurement),'" from "',char(inputname(2)),'" to "',char(inputname(1)),'"'];

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,message,[],dataout);

end