classdef viewhistory_gui < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        drEEMviewhistoryUIFigure      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        SavelistasspreadsheetButton   matlab.ui.control.Button
        TransferoptionstoworkspaceButton  matlab.ui.control.Button
        ViewselecteddatasetButton     matlab.ui.control.Button
        ViewselectedoptionsButton     matlab.ui.control.Button
        RestoreselecteddatasetButton  matlab.ui.control.Button
        UITable                       matlab.ui.control.Table
    end

    
    properties (Access = private)
        data % Description
        history % Description
        selectedB % Description
        selectedD % Description
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, data)
            
            movegui(app.drEEMviewhistoryUIFigure,"center")
            app.data = data;
            app.history = app.data.history;
            
            t = drEEMhistory.convert2table(app.history);
            tno=table((1:height(t))',VariableNames={'#'});
            t=[tno,t];
            app.history=t;
            %app.history=struct2table(app.history);
            %{'timestamp','fname','fmessage','details','backup','previous','usercomment'}
            app.UITable.Data=app.history(:,[1:4 8]);

            % Work in progress for multiple entries
            tbl=app.UITable.Data;
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
            app.UITable.Data=tbl;

            fs=unique(app.UITable.Data.fname);
            col=flipud(brighten(bone(numel(fs)*4),.1));
            col=col(1:ceil(numel(fs)),:);
            for j = 1 : numel(fs)
                s  = uistyle(BackgroundColor=col(j,:));
                idx=matches(app.UITable.Data.fname,fs{j});
                if sum(idx)>1
                    addStyle(app.UITable,s,'row',find(idx));
                else
                    s  = uistyle(BackgroundColor=[0.9 0.9 0.9]);
                    addStyle(app.UITable,s,'row',find(idx));
                end
            end
            %% Unsuccessful multiple rows in one history
            % comments=app.UITable.Data.usercomment;
            % 
            % for j=1:numel(comments)
            %     if numel(comments{j})>1
            %         new=['<html>'];
            %         for k=1:numel(comments{j})
            %             new=[new,char([char(comments{j}(k)),'<br />'])];
            %         end
            %         new=[new(1:end-6),'</html>'];
            %         comments{j}=new;
            %         style(j)=categorical(cellstr('html'));
            %     else
            %         style(j)=categorical(cellstr('none'));
            %     end
            % 
            % end
            % sh = uistyle("Interpreter","html");
            % sn = uistyle("Interpreter","none");
            % idx=style=='html';
            % addStyle(app.UITable,sh,'cell',[find(idx),4])
            % app.UITable.Data.usercomment=comments;

        end

        % Selection changed function: UITable
        function UITableSelectionChanged(app, event)
            selection = app.UITable.Selection;
            selection = app.UITable.Data.("#")(selection);
            %dat=drEEMdataset.restore(app.data,selection);
            %app.selectedB=dat;
            % if iscell(app.selectedB)
            %     app.selectedB=app.selectedB{1};
            % end
            app.selectedD=app.history.details{selection};

            % if app.selectedB.nSample~=0;
            %     app.RestoreselecteddatasetButton.Enable="on";
            %     app.ViewselecteddatasetButton.Enable="on";
            % else
            %     app.RestoreselecteddatasetButton.Enable="off";
            %     app.ViewselecteddatasetButton.Enable="off";
            % end
            if matches(class(app.selectedD),{'struct','handlescatterOptions'})
                app.ViewselectedoptionsButton.Enable="on";
                app.TransferoptionstoworkspaceButton.Enable="on";
            else
                app.ViewselectedoptionsButton.Enable="off";
                app.TransferoptionstoworkspaceButton.Enable="off";
            end
        end

        % Button pushed function: RestoreselecteddatasetButton
        function RestoreselecteddatasetButtonPushed(app, event)
            assignin('base','restoredData',app.selectedB)
            disp('Backup restored (look for "restoredData"')
        end

        % Button pushed function: ViewselecteddatasetButton
        function ViewselecteddatasetButtonPushed(app, event)
            
            f=uifigure;
            f.Name='drEEM viewhistory -> viewing selected backup';
            ta=uitable(f);
            ta.Position=[0 0 f.Position(3) f.Position(4)];
            txt=formattedDisplayText(app.selectedB);
            txt=erase(txt,'  <a href="matlab:helpPopup drEEMdataset" style="font-weight:bold">drEEMdataset</a> with properties:↵↵');
            txt=splitlines(txt);
            txt=txt(3:end-1);
            txt=split(txt,':');
            t=table;
            t.field=txt(:,1);
            t.information=txt(:,2);
            ta.Data=t;
        end

        % Button pushed function: ViewselectedoptionsButton
        function ViewselectedoptionsButtonPushed(app, event)
            f=uifigure;
            f.Name='drEEM viewhistory -> viewing selected options of function call';
            ta=uitable(f);
            ta.Position=[0 0 f.Position(3) f.Position(4)];
            txt=formattedDisplayText(app.selectedD);
            txt=split(txt,'</a> with properties:');
            txt=splitlines(txt(end));
            txt(matches(txt,""))=[];
            %txt=txt(3:end-1);
            txt=split(txt,':');
            t=table;
            t.field=txt(:,1);
            t.information=txt(:,2);
            ta.Data=t;
        end

        % Button pushed function: TransferoptionstoworkspaceButton
        function TransferoptionstoworkspaceButtonPushed(app, event)
            assignin('base','restoredOptions',app.selectedD)
            disp('Options assigned to workspace variable (look for "restoredOptions"')
        end

        % Button pushed function: SavelistasspreadsheetButton
        function SavelistasspreadsheetButtonPushed(app, event)
            [file,path] = uiputfile('drEEM_dataset_history.ods','select location of file');
            figure(app.drEEMviewhistoryUIFigure)
            t=app.UITable.Data(:,[1 2 3 5 4]);
            t.Properties.VariableNames={'history #','timestamp','function','user comment','function message'};
            if exist([path,file],"file")
                delete([path,file])
            end
            writetable(t,[path,file],"FileType","spreadsheet");
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create drEEMviewhistoryUIFigure and hide until all components are created
            app.drEEMviewhistoryUIFigure = uifigure('Visible', 'off');
            colormap(app.drEEMviewhistoryUIFigure, 'turbo');
            app.drEEMviewhistoryUIFigure.Position = [100 100 864 519];
            app.drEEMviewhistoryUIFigure.Name = 'drEEM: viewhistory';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.drEEMviewhistoryUIFigure);
            app.GridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', 40, 40};

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {'#'; 'Date / Time'; 'drEEM function'; 'details'; 'Comments by user'};
            app.UITable.ColumnWidth = {30, 'auto', 'auto', 'auto', 'auto'};
            app.UITable.RowName = {};
            app.UITable.SelectionType = 'row';
            app.UITable.SelectionChangedFcn = createCallbackFcn(app, @UITableSelectionChanged, true);
            app.UITable.Multiselect = 'off';
            app.UITable.Layout.Row = [1 6];
            app.UITable.Layout.Column = [1 5];

            % Create RestoreselecteddatasetButton
            app.RestoreselecteddatasetButton = uibutton(app.GridLayout, 'push');
            app.RestoreselecteddatasetButton.ButtonPushedFcn = createCallbackFcn(app, @RestoreselecteddatasetButtonPushed, true);
            app.RestoreselecteddatasetButton.WordWrap = 'on';
            app.RestoreselecteddatasetButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.RestoreselecteddatasetButton.FontWeight = 'bold';
            app.RestoreselecteddatasetButton.Enable = 'off';
            app.RestoreselecteddatasetButton.Visible = 'off';
            app.RestoreselecteddatasetButton.Layout.Row = 8;
            app.RestoreselecteddatasetButton.Layout.Column = 1;
            app.RestoreselecteddatasetButton.Text = 'Restore selected dataset';

            % Create ViewselectedoptionsButton
            app.ViewselectedoptionsButton = uibutton(app.GridLayout, 'push');
            app.ViewselectedoptionsButton.ButtonPushedFcn = createCallbackFcn(app, @ViewselectedoptionsButtonPushed, true);
            app.ViewselectedoptionsButton.WordWrap = 'on';
            app.ViewselectedoptionsButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ViewselectedoptionsButton.FontWeight = 'bold';
            app.ViewselectedoptionsButton.Enable = 'off';
            app.ViewselectedoptionsButton.Layout.Row = 7;
            app.ViewselectedoptionsButton.Layout.Column = 5;
            app.ViewselectedoptionsButton.Text = 'View selected options';

            % Create ViewselecteddatasetButton
            app.ViewselecteddatasetButton = uibutton(app.GridLayout, 'push');
            app.ViewselecteddatasetButton.ButtonPushedFcn = createCallbackFcn(app, @ViewselecteddatasetButtonPushed, true);
            app.ViewselecteddatasetButton.WordWrap = 'on';
            app.ViewselecteddatasetButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ViewselecteddatasetButton.FontWeight = 'bold';
            app.ViewselecteddatasetButton.Enable = 'off';
            app.ViewselecteddatasetButton.Visible = 'off';
            app.ViewselecteddatasetButton.Layout.Row = 7;
            app.ViewselecteddatasetButton.Layout.Column = 1;
            app.ViewselecteddatasetButton.Text = 'View selected dataset';

            % Create TransferoptionstoworkspaceButton
            app.TransferoptionstoworkspaceButton = uibutton(app.GridLayout, 'push');
            app.TransferoptionstoworkspaceButton.ButtonPushedFcn = createCallbackFcn(app, @TransferoptionstoworkspaceButtonPushed, true);
            app.TransferoptionstoworkspaceButton.WordWrap = 'on';
            app.TransferoptionstoworkspaceButton.BackgroundColor = [0.9412 0.9412 0.9412];
            app.TransferoptionstoworkspaceButton.FontWeight = 'bold';
            app.TransferoptionstoworkspaceButton.Enable = 'off';
            app.TransferoptionstoworkspaceButton.Layout.Row = 8;
            app.TransferoptionstoworkspaceButton.Layout.Column = 5;
            app.TransferoptionstoworkspaceButton.Text = 'Transfer options to workspace';

            % Create SavelistasspreadsheetButton
            app.SavelistasspreadsheetButton = uibutton(app.GridLayout, 'push');
            app.SavelistasspreadsheetButton.ButtonPushedFcn = createCallbackFcn(app, @SavelistasspreadsheetButtonPushed, true);
            app.SavelistasspreadsheetButton.FontWeight = 'bold';
            app.SavelistasspreadsheetButton.Layout.Row = 8;
            app.SavelistasspreadsheetButton.Layout.Column = 3;
            app.SavelistasspreadsheetButton.Text = 'Save list as spreadsheet';

            % Show the figure after all components are created
            app.drEEMviewhistoryUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = viewhistory_gui(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.drEEMviewhistoryUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.drEEMviewhistoryUIFigure)
        end
    end
end