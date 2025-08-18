function [dataout] = rmexcitation(data,index)
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
    %warning('rmexcitation: input "index" was empty. No action taken.')
    dataout=data;
    return
end

drEEMdataset.validate(data)

dataout=data;

if islogical(index)|isnumeric(index)
    dataout.X(:,:,index)=[];
    dataout.Ex(index)=[];
    dataout.nEx=size(dataout.X,3);
    if not(isempty(dataout.XBlank))
        dataout.XBlank(:,:,index)=[];
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
        'deleted models due to call to rmexcitation (likely through subdataset)',[],dataout);
    disp('A call to subdataset with pre-existing models results in their deletion.')
end


if islogical(index)
    index=find(index);
end

ident=data.Ex(index);
if iscolumn(ident)
    ident=ident';
end

idx=height(dataout.history)+1;
dataout.history(idx,1)=...
    drEEMhistory.addEntry(mfilename,...
    ['deleted excitation wavelengths ',num2str(ident)],[],dataout);

drEEMdataset.validate(dataout)
