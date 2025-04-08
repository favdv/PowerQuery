let 
    doc = [
        Documentation.Name = "Extract fieldnames from nested records", 
        Documentation.FunctionName = "Table.ExtractFieldNames",
        Documentation.Description = "Extract a unique list of fieldnames from all nested records in a specified column of a specified table. Will remove the need to hardcode column names.", 
        Documentation.Examples = {
            [
                Description = "Extract the fieldnames of column ""fieldName"" from table ""tableName""",
                Code = "FunctionName(tableName,""fieldName"")",
                Result = "Returns a list of field names, which can e.g. be used for table expansion."
            ]
        }
    ],
    fn = (previousStep as table, columnName as text) => List.Distinct(
        List.Combine(
            List.Transform(Table.ToRecords(previousStep), each Record.FieldNames(Record.Field(_, columnName)))
        )
    )
in 
    Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
