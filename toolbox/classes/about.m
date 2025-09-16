classdef about
    % about structure

    properties
            % CF convention
    title  (1,:) {mustBeText} = ""
    institution  (1,:) {mustBeText} = ""
    references  (1,:) {mustBeText} =  ""
    comment  (1,:) {mustBeText} = ""

    % ACDD convention
    summary  (1,:) {mustBeText} = ""
    keywords  (1,:) {mustBeText} = ""
    id  (1,:) {mustBeText} = ""
    naming_authority  (1,:) {mustBeText} = ""
    creator_name  (1,:) {mustBeText} = ""
    creator_url  (1,:) {mustBeText} = ""
    creator_email  (1,:) {mustBeText} = ""
    contributor_name  (1,:) {mustBeText} = ""
    contributor_role  (1,:) {mustBeText} = ""
    date_created  (1,:) {mustBeA( date_created,'datetime')} = datetime.empty
    date_modified  (1,:) {mustBeA(date_modified,'datetime')} =  datetime.empty
    project  (1,:) {mustBeText} = ""
    publisher_name  (1,:) {mustBeText} = ""
    publisher_url  (1,:) {mustBeText} = ""
    publisher_email  (1,:) {mustBeText} = ""
    license  (1,:) {mustBeText} = ""
    citation  (1,:) {mustBeText} = ""
    acknowledgement  (1,:) {mustBeText} = ""
    instrument (1,:) {mustBeText} = ""
    time_coverage_start  (1,:) {mustBeA(time_coverage_start,'datetime')} = datetime.empty
    time_coverage_end  (1,:) {mustBeA(time_coverage_end,'datetime')} = datetime.empty
    geospatial_lat_min (1,1) {mustBeNumeric} = NaN;
    geospatial_lat_max (1,1) {mustBeNumeric} = NaN;
    geospatial_lon_min (1,1) {mustBeNumeric} = NaN;
    geospatial_lon_max (1,1) {mustBeNumeric} = NaN;
    geospatial_lat_units (1,:) {mustBeText,mustBeMember(geospatial_lat_units,"degree_north")} = "degree_north"
    geospatial_lon_units (1,:) {mustBeText,mustBeMember(geospatial_lon_units,"degree_east")} = "degree_east"
    geospatial_vertical_min (1,1) {mustBeNumeric} = NaN;
    geospatial_vertical_max (1,1) {mustBeNumeric} = NaN;
    geospatial_vertical_units (1,:) {mustBeText,mustBeMember(geospatial_vertical_units,["meter","kilometer"])} = 'meter';
    geospatial_vertical_positive (1,:) {mustBeText,mustBeMember(geospatial_vertical_positive,["down","up"])} = "down";
    
    % openUV 
    sample_filtration (1,:) {mustBeText} = ""
    sample_storage_duration (1,:) {mustBeText} = ""
    sample_storage_temperature (1,:) {mustBeText} = ""
    metadata_link (1,:) {mustBeText} = ""
    processing_level (1,:) {mustBeText} = ""
    product_version (1,:) {mustBeText} = ""

    end
end