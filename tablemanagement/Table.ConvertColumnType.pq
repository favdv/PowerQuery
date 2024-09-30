let 
    doc = [
        Documentation.Name = "Column Conversion", 
        Documentation.FunctionName = "Table.ConvertColumns",
        Documentation.Description = "This function loops through all rows and columns and tries to determine the best type for the column. Unlike the default function, no column names need to be hardcoded. It is possible to specify the  order of type processing (which can help to determin if a column with 0 and 1 only is a logical or numeric column. The function also attempts to convert numbers and dates entered as string values to actual numbers and dates. By default the sampleSize (number of rows the type is based on) is set 1000. COlumns with complex types (nested lists, etc) will be set to any by default.", 
        Documentation.Examples = {
            [
                Description = "Convert with the default type ordering",
                Code = "Table.ConvertColumns(Source,null,2000)",
                Result = "Converts the columns in the Source table based on 2000 records in the order 'type datetimezone, type datetime, type date, type time, type logical, Int64.Type, type number, type text', so 0 and 1 are interpreted as logical"
            ],
            [
                Description = "Convert with the specific type ordering",
                Code = "Table.ConvertColumns(Source, {type datetimezone, type datetime, type date, type time, Int64.Type, type logical, type number, type text})",
                Result = "Converts the columns in the Source table in the order 'type datetimezone, type datetime, type date, type time, Int64.Type, type logical, type number, type text', so 0 and 1 are interpreted as integers"
            ]
        }
    ],
    fn = (previousStep as table, optional typeOrder as nullable list, optional sampleSize as nullable number) =>
let
    // Set default sample size to 1000 if not provided
    sampleSize = if sampleSize <> null then sampleSize else 1000,
    
    // Sample the first sampleSize rows
    sampledTable = Table.FirstN(previousStep, sampleSize),
    
    typeOrder = if typeOrder <> null then typeOrder else {type datetimezone, type datetime, type date, type time, type logical, Int64.Type, type number, type text},
    
    // Function to determine the best type for a column
    DetermineColumnType = (column as list) as type =>
    let
        // Remove null values for type detection
        nonNullValues = List.RemoveNulls(column),
        // Check if the column contains complex types
        containsComplexType = List.AnyTrue(List.Transform(nonNullValues, each Value.Is(_, type list) or Value.Is(_, type record) or Value.Is(_, type binary) or Value.Is(_, type function) or Value.Is(_, type table))),
        // Check if the column is empty after removing nulls
        changeType = if List.Count(nonNullValues) = 0 or containsComplexType then type any else
            let
                // Attempt to convert text values to other types
                convertedValues = List.Transform(nonNullValues, each try if Value.Is(_, type text) then 
                     try Number.FromText(_) otherwise try DateTime.FromText(_) otherwise _ 
                    else _ otherwise _),
                
                // Check if the column contains only logical values
                isLogical = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type logical))),
                // Check if the column contains only Int64 values
                isInt = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, Int64.Type))),
                // Check if the column contains only numbers
                isNumber = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type number))),
                // Check if the column contains only datetimezone values
                isDateTimeZone = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type datetimezone))),
                // Check if the column contains only datetime values
                isDateTime = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type datetime))),
                // Check if the column contains only date values
                isDate = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type date))),
                // Check if the column contains only time values
                isTime = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type time))),
                // Check if the column contains only text values
                isText = List.AllTrue(List.Transform(convertedValues, each Value.Is(_, type text))),
                // Determine the type based on the order
                changeType = if isLogical then type logical
                             else if isInt then Int64.Type
                             else if isDateTimeZone then type datetimezone
                             else if isDateTime then type datetime
                             else if isDate then type date
                             else if isTime then type time
                             else if isNumber then type number
                             else if isText then type text
                             else type any
            in changeType
    in changeType,
    
    // Function to transform the column types using List.Accumulate
    TransformColumnTypes = List.Accumulate(
        Table.ColumnNames(sampledTable),
        sampledTable,
        (state, currentColumn) => Table.TransformColumnTypes(state, {{currentColumn, DetermineColumnType(Table.Column(state, currentColumn))}})
    )
in
    TransformColumnTypes


in 
    Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
