function fig=extractUIfigure(app)
props = properties(app);
for i = 1:length(props)
    try
        propValue = app.(props{i});
        % Check if it's a figure of type matlab.ui.Figure
        if isa(propValue, 'matlab.ui.Figure')
            fig = propValue;
            return;
        end
    catch
        % Skip properties that can't be accessed
    end
end
end