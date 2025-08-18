function [dataout] = rmemission(data,index)
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
    %warning('rmemission: input "index" was empty. No action taken.')
    dataout=data;
    return
end

drEEMdataset.validate(data)

dataout=data;

if islogical(index)|isnumeric(index)
    dataout.X(:,index,:)=[];
    dataout.Em(index)=[];
    dataout.nEm=size(dataout.X,2);
    if not(isempty(dataout.XBlank))
        dataout.XBlank(:,index,:)=[];
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
        'deleted models due to call to rmemission (likely through subdataset)',[],dataout);
    disp('A call to subdataset with pre-existing models results in their deletion.')
end

if islogical(index)
    index=find(index);
end

ident=data.Em(index);
if iscolumn(ident)
    ident=ident';
end

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,...
    ['deleted emission wavelengths ',num2str(ident)],[],dataout);

drEEMdataset.validate(dataout)
