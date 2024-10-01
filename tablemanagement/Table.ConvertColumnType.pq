let 
    doc = [
        Documentation.Name = "Column Conversion", 
        Documentation.FunctionName = "Table.ConvertColumns",
        Documentation.Description = "This function loops through all rows and columns and tries to determine the best type for the column. Unlike the default function, no column names need to be hardcoded.", 
        Documentation.Examples = {
            [
                Description = "Convert based on 2000 records",
                Code = "Table.ConvertColumns(Source,2000)",
                Result = "Converts the columns in the Source table based on 2000 records"
            ],
            [
                Description = "Convert based on 1000 records (default)",
                Code = "Table.ConvertColumns(Source)",
                Result = "Converts the columns in the Source table based on 1000 records"
            ]
        }
    ],
    fn = (previousStep as table, optional sampleSize as nullable number) =>
let
    sampleSize = if sampleSize <> null then sampleSize else 1000,
    sampledTable = Table.FirstN(previousStep, sampleSize),
    typeOrder = {type datetimezone, type datetime, type date, type time, type duration, Int64.Type, type number, type logical, type text},  //standard order
    DetermineColumnType = (column as list) as type =>
    let
        nonNullValues = List.Buffer(List.RemoveNulls(column)),
        convertedValues = List.Buffer(List.Transform(nonNullValues, each if Value.Is(_, type datetimezone) then DateTimeZone.ToLocal(_) else _)),
        containsComplexType = List.AnyTrue(List.Transform(convertedValues, each Value.Is(_, type list) or Value.Is(_, type record) or Value.Is(_, type binary) or Value.Is(_, type function) or Value.Is(_, type table))),
        changeType = if List.Count(convertedValues) = 0 or containsComplexType then type any else
            let
                convertedValues = List.Buffer(List.Transform(convertedValues, each try if Value.Is(_, type text) then 
                     try Number.FromText(_) otherwise try DateTimeZone.FromText(_) otherwise try DateTime.FromText(_) otherwise _ 
                    else _ otherwise _)),
                determineType = List.First(
                    List.Select(
                        typeOrder,
                        each List.AllTrue(List.Transform(convertedValues, (value) => try Value.Is(value, _) otherwise false))
                    ),
                    type any
                )
            in determineType
    in changeType,
    columnTypes = List.Transform(Table.ColumnNames(sampledTable), each {_, DetermineColumnType(Table.Column(sampledTable, _))}),
    TransformColumnTypes = Table.TransformColumnTypes(sampledTable, columnTypes)
in
    TransformColumnTypes





in 
    Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
