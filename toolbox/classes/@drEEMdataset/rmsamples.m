function [dataout] = rmsamples(data,index)
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data  (1,1) {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
    index {mustBeNumericOrLogical}
end

if isempty(index)|sum(index)==0
    %warning('rmsamples: input "index" was empty. No action taken.')
    dataout=data;
    return
end

drEEMdataset.validate(data)

dataout=data;

if islogical(index)|isnumeric(index)
    if not(isempty(dataout.X))
        dataout.X(index,:,:)=[];
        dataout.nSample=size(dataout.X,1);
    end
    dataout.i(index)=[];
    dataout.filelist(index)=[];
    dataout.metadata(index,:)=[];
    if not(isempty(dataout.opticalMetadata))
        dataout.opticalMetadata(index,:)=[];
    end
    if not(isempty(dataout.XBlank))
        dataout.XBlank(index,:,:)=[];
    end
    if not(isempty(dataout.abs))
        dataout.abs(index,:)=[];
        dataout.nSample=size(dataout.abs,1);
    end
    
else
    error("input to index must be numeric or logical")
end

f=drEEMdataset.modelsWithContent(dataout);
if not(isempty(f))
    dataout.models=drEEMmodel;
    idx=height(dataout.history)+1;
    dataout.history(idx,1)=...
        drEEMhistory.addEntry(mfilename,...
        'deleted models due to call to rmsamples (likely through subdataset)',[],dataout);
    disp('A call to subdataset with pre-existing models results in their deletion.')
end



if islogical(index)
    index=find(index);
end

ident=data.filelist(index);
if iscolumn(ident)
    ident=ident';
end
if isscalar(ident)
    ident=ident{1};
else
    newident=[];
    for j=1:numel(ident)
        newident=[newident,' ; ',ident{j}];
    end
    ident=newident;clearvars newident;
end


idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,['deleted samples ',ident],[],dataout);
drEEMdataset.validate(dataout)
