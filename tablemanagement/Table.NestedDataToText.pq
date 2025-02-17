let 
doc = [
    Documentation.Name =  "Change Nested Columns to either HTML, XML or JSON Strings", 
    Documentation.FunctionName = "Table.NestedDataToText",
    Documentation.Description = 
    "This function converts deep nested columns into strings, and at this stage it converts to either JSON, XML or (X)HTML - JSON is the default if no value for ExportType is provided and all columns are converted if no value for columns is provided. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace FunctionName with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Convert all columns to JSON",
            Code = "FunctionName(Source)",
            Result = "All nested tables, records and lists in the whole table are converted to strings with a JSON representation. All fields that are not lists, records or tables are ignored."
          ],
          [
            Description = "Converting selected columns to JSON",
            Code = "FunctionName(Source,null,{""col1"",""col2""})",
            Result = "All nested tables, records and lists for the specified columns (her col1 and col2) are converted to strings with a JSON representation. All fields that are not lists, records or tables are ignored. instead of the null value for the second parameter ""JSON"" can also be used"
          ],
          [
            Description = "Converting selected columns to HTML",
            Code = "FunctionName(Source,""HTML"",{""col1"",""col2""})",
            Result = "All nested tables, records and lists for the specified columns (her col1 and col2) are converted to strings with a (X)HTML representation. All fields that are not lists, records or tables are ignored. Either HTML or XHTL can be used to dormat it to HTML"
          ],
          [
            Description = "Converting all columns to XML",
            Code = "FunctionName(Source,""XML"")",
            Result = "All nested tables, records and lists in the whole table are converted to strings with a XML representation. All fields that are not lists, records or tables are ignored."
          ]  
        }
    
  ],

fn = (previousStep as table, optional ExportType as nullable text, optional columns as nullable list) as table =>
let
    // Set up the different elements to use depending on ExportType
    ListParent = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""list array""" else "list class=""array""",
    ListChild = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""item value""" else "item class=""value""",
    RecordParent = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""record object""" else "record class=""object""",
    RecordChild = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""field key value""" else "field class=""key value""",
    TableArray = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""table array""" else "table class=""array""",
    TableList = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""row object""" else "row class=""object""",
    TableKey = if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" then "div class=""cell key value""" else "cell class=""key value""",
    
    //AttributeNames
    TypeAttr = "data-type",
    KeyAttr = "data-key",
    NullValue = "null",
    
    // Get the list of columns to transform
    ColumnsToTransform = if columns = null or List.IsEmpty(columns) then Table.ColumnNames(previousStep) else columns,
    
    // Function to check if a value is a nested record, table or list
    IsNested = (value as any) as logical =>
        if value is record or value is list or value is table then true else false,
    
    // Helper function to convert types to strings for XML
    TypeToString = (t as type) as text =>
        if t = type number then "number"
        else if t = type text then "text"
        else if t = type logical then "logical"
        else if t = type date then "date"
        else if t = type datetime then "datetime"
        else if t = type datetimezone then "datetimezone"
        else if t = type duration then "duration"
        else if t = type time then "time"
        else if t = type table then "table"
        else if t = type record then "record"
        else if t = type list then "list"
        else if t = type null then "null"
        else "any",
    
    // Function to convert a single field to JSON string if it is nested
    ConvertFieldToJSON = (value as any) as any =>
        if IsNested(value) then Text.FromBinary(Json.FromValue(value), TextEncoding.Utf8) else value,
    
    // Function to convert a single field to XML-like format if it is nested
    ConvertFieldToXML = (value as any, ConvertField as function, ConvertRecord as function) as any =>
        if value is list then
            "<" & ListParent & ">" & Text.Combine(List.Transform(List.Zip({List.Positions(value), value}), each "<" & ListChild & " " &TypeAttr& "=""" & TypeToString(Value.Type(_{1})) & """>" & ConvertField(_{1}, ConvertField, ConvertRecord) & "</" & Text.BeforeDelimiter(ListChild, " ") & ">"), "") & "</" & Text.BeforeDelimiter(ListParent, " ") & ">"
        else if value is record then
            "<" & RecordParent & ">" & Text.Combine(List.Transform(Record.FieldNames(value), each "<" & RecordChild & " " & KeyAttr & "=""" & _ & """ " &TypeAttr& "=""" & TypeToString(Value.Type(Record.Field(value, _))) & """>" & (if Record.Field(value, _) <> null then ConvertField(Record.Field(value, _), ConvertField, ConvertRecord) else NullValue) & "</" & Text.BeforeDelimiter(RecordChild, " ") & ">"), "") & "</" & Text.BeforeDelimiter(RecordParent, " ") & ">"
        else if value is table then
            let
                TableRecords = Table.ToRecords(value),
                ConvertedRecords = List.Transform(TableRecords, each ConvertRecord(_, ConvertField, ConvertRecord))
            in
                "<" & TableArray & ">" & Text.Combine(List.Transform(List.Zip({List.Positions(ConvertedRecords), ConvertedRecords}), each _{1}), "") & "</" & Text.BeforeDelimiter(TableArray, " ") & ">"
        else
            Text.From(value),
    
    // Function to convert a single record to XML-like format
    ConvertRecordToXML = (rec as record, ConvertField as function, ConvertRecord as function) as text =>
        "<" & TableList & ">" & Text.Combine(List.Transform(Record.FieldNames(rec), each "<" & TableKey & " "&KeyAttr&"=""" & _ & """ " &TypeAttr& "=""" & TypeToString(Value.Type(Record.Field(rec, _))) & """>" & (if Record.Field(rec, _) <> null then ConvertField(Record.Field(rec, _), ConvertField, ConvertRecord) else NullValue) & "</" & Text.BeforeDelimiter(TableKey, " ") & ">"), "") & "</" & Text.BeforeDelimiter(TableList, " ") & ">",

    // Function to convert a single column based on ExportType
    ConvertColumn = (tbl as table, col as text, ExportType as text) =>
        if Text.Lower(ExportType) = "html" or Text.Lower(ExportType) = "xhtml" or Text.Lower(ExportType) = "xml" then
            Table.TransformColumns(tbl, {col, each ConvertFieldToXML(_, ConvertFieldToXML, ConvertRecordToXML), type text})
        else
            Table.TransformColumns(tbl, {col, each ConvertFieldToJSON(_), type text}),
    
    // Iterate over the list of columns and apply the conversion function
    Result = List.Accumulate(ColumnsToTransform, previousStep, (state, current) => ConvertColumn(state, current, if ExportType = null then "json" else ExportType))
in
    Result
 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
