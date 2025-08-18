classdef drEEMhistory
% Copyright (C) 2025 Urban J. Wuensch - wuensch@chalmers.se
% Chalmers University of Technology
% Department of Architecture and Civil Engineering
% Sven Hultins Gata 6
% 41296 Gothenburg (Sweden)
    properties
        timestamp (1,1) datetime
        fname (1,:) {mustBeText} = ""
        fmessage (1,:) {mustBeText} = ""
        usercomment(1,:) {mustBeText} = ""

    end
    % Hidden properties for toolbox-internal use only (not visible to user)
    properties (Hidden=true)
        details % <- Option structure or a text giving details.
        backup (1,1)  % <- NOT IN USE!!! the dataout version at the end of call
        previous (1,1)  % <- for restoring the input variable of a call (currently only used for scaling)
    end
    methods (Static=true)
        function obj=addEntry(caller,message,details,backup,prev)
            arguments
                caller {mustBeText}
                message {mustBeText}
                details = ""
                backup drEEMdataset = drEEMdataset.create
                prev drEEMdataset = drEEMdataset.create
            end
            obj=drEEMhistory;
            obj.timestamp=datetime("now");
            obj.fname=caller;
            obj.fmessage=message;
            obj.details=details;
            
            if backup.nSample~=0
                backup=drEEMbackup.convert2backup(backup);
            end
            %obj.backup=backup;

            if prev.nSample~=0
                prev=drEEMbackup.convert2backup(prev);
            end
            obj.previous=prev;
        end

        function idx = searchhistory(history,fname,firstLast)
            arguments
                history {mustBeA(history,"drEEMhistory")}
                fname {mustBeText}
                firstLast {mustBeMember(firstLast,["first","last","all"])}
            end

            idx=arrayfun(@(x) matches(x.fname,fname),history);
            if isempty(firstLast)
                firstLast="first";
            end
            if matches(firstLast,"all")
                idx=find(idx);
            else
                idx=find(idx,1,firstLast);
            end
        end

        function tableout=convert2table(history)
            mustBeA(history,"drEEMhistory")
            flds={'timestamp','fname','fmessage','details','backup','previous','usercomment'};

            conv=struct;
            for j=1:numel(flds)
                for k=1:height(history)
                    conv(k).(flds{j})=history(k).(flds{j});
                end
            end
            if isscalar(conv)
                tableout=struct2table(conv,AsArray=true);
            else
                tableout=struct2table(conv);
            end

        end
    end

    methods (Static=true,Hidden=true)
        function [dataout] = restore(data,whichone)
            arguments
                data {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
                whichone (1,1) {mustBeNumeric}
            end
            try
                mustBeLessThanOrEqual(whichone,numel(data.history))
            catch
                error(['2nd input must be less than or equal to ',num2str(numel(data.history)),'.'])
            end

            temp=data.history(whichone).backup;
            temp=drEEMbackup.convert2dataset(temp);
            temp.history=data.history(1:whichone);
            temp.toolboxdata=data.toolboxdata;

            if nargout==0
                assignin("base",inputname(1),temp);
                disp(['<strong> State ',num2str(whichone),' in "',inputname(1), '" restored. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
                return
            else
                dataout=temp;
            end

        end

        function [dataout] = undo(data)
            arguments
                data {mustBeA(data,"drEEMdataset"),drEEMdataset.validate(data)}
            end
            n=numel(data.history);
            if n==1
                error('Nothing to undo')
            end

            temp=data.history(n-1).backup;
            temp=drEEMbackup.convert2dataset(temp);
            temp.history=data.history(1:n-1);
            temp.toolboxdata=data.toolboxdata;

            if nargout==0
                assignin("base",inputname(1),temp);
                disp(['<strong> Last step (',num2str(n-1),') in dataset "',inputname(1), '" undone. </strong> Since no output argument was provided, the workspace variable was overwritten.'])
                return
            else
                dataout=temp;
            end

        end

    end

end