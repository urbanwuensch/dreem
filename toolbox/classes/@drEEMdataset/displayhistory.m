function displayhistory(data)
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
arguments
    data {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data),drEEMdataset.mustContainSamples(data)}
end


if height(data.history)==0
    error('No entries to display.')
end

t=drEEMhistory.convert2table(data.history);

tno=table((1:height(t))',VariableNames={'#'});
t=[tno,t];
history=t;
%history=struct2table(history);
%{'timestamp','fname','fmessage','details','backup','previous','usercomment'}
history=history(:,[1:4 8]);

% Work in progress for multiple entries
tbl=history;
count=1;
while count<=height(tbl)
    % store the comments separately
    cmts=string(tbl.usercomment{count});
    nCmts=numel(cmts);
    cnt=1;
    if nCmts==1
        %tbl.usercomment(count)=cmts;
    elseif nCmts>1
        % If multiple comments split the table
        t1=tbl(1:count,:);
        t2=tbl(count+1:end,:);
        % First table get's first comment
        t1.usercomment{count}=cmts(1);
        % First comment get's deleted
        cmts(1)=[];
        % interjected table gets created
        ti=t1; % Make it based on the 1st half
        ti=ti(count,:); % delete all but one row
        ti.usercomment={""};
        ti.timestamp=missing;
        ti.fname=""; % Just keeping the fname here for the moment.
        ti.fmessage="";
        hno=ti.("#");
        warning off
        while numel(cmts)>0
            ti.usercomment(cnt)={cmts(1)};
            % These things need to be repeated if more than one
            % additional comment is there
            ti.timestamp(cnt)=missing;
            ti.fname(cnt)=""; % Just keeping the fname here for the moment.
            ti.fmessage(cnt)="";
            ti.("#")(cnt)=hno;
            % delete the comment and increase the count
            cmts(1)=[];
            cnt = cnt + 1;
        end
        warning on
        tbl=[t1;ti;t2];
    end
    count=count+cnt;
end
tbl.timestamp=[];
tbl.Properties.VariableNames={'#','Function','Function message','User comment'};
tbl=tbl(:,[1 2 4 3]);
tbl.Function=categorical(tbl.Function);
tbl.("Function message")=categorical(tbl.("Function message"));
disp(tbl);
% Old (no multiple entry support)
% t.details=[];
% t.backup=[];
% t.previous=[];
% t.Properties.VariableNames={'Date/time','Function','Function message','User comment'};
% t.Function=categorical(t.Function);
% t.('Function message')=categorical(t.('Function message'));
% t.('#')=(1:height(t))';
% t=t(:,[end 1 2 4 3]);
% disp(t)


end