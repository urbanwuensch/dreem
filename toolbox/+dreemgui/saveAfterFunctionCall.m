function saveAfterFunctionCall(fig,name)
            arguments
                fig (1,1) {mustBeA(fig,'matlab.ui.Figure')}
                name (1,:) {mustBeText}
            end

            name=char(name);
            temp=strsplit(name,'.');
            if isscalar(temp)
                name=[name,'.png'];
            elseif numel(temp)==2
                ext=temp{end};
                try
                    mustBeMember(ext,["jpg","jpeg","png","tiff","tif","gif","svg","pdf","eps"])
                catch ME
                    message=replace(ME.message,'Value ','Extension input to "figurefile" ');
                    ME = MException('MATLAB:validators:mustBeMember',message);
                    throwAsCaller(ME)
                end
            elseif numel(temp)>2
                warning('Export figure names should only contain one "." Replaced with "drEEM_figure.png"')
                name='drEEM_figure.png';
            end
            warning off

            % This is not clean, but works in current conditions.
            % Exportgraphics fails if multiple "containers" exist in app.
            % In this case, exportapp works.
            try
                exportgraphics(fig,name, ...
                    "BackgroundColor","white", ...
                    "ContentType","auto", ...
                    "Resolution",600, ...
                    "PreserveAspectRatio","on",...
                    "Padding","tight")
            catch
                exportapp(fig,name)
            end
            warning on
end