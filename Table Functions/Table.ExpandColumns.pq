let 
doc = 
  [
    Documentation.Name =  "Auto Expand columns", 
    Documentation.FunctionName = "Table.RecursiveExpandColumns", 
    Documentation.Description = "A function to expand any number of nested columns, including the nested columns as applicable. Value 'null' for the `specifiedCols` parameter means all columns. A 'null' value for the `excludeCols` parameter is assumed to be 'false' and can thus be omitted if preferred. There is an option to change the separator via the separator parameter, which defaults to a fullstop", 
    Documentation.Examples = {
          [
            Description = "Expand all columns",
            Code = "FunctionName(Source)",
            Result = "All columns are expanded."
          ],
          [
            Description = "Expand all columns with exclusions",
            Code = "FunctionName(Source,{""colA"",""colE""},true)",
            Result = "All columns are expanded apart from columns colA and colE."
          ],
          [
            Description = "Expand selected columns",
            Code = "FunctionName(Source,{""colA"",""colE""})",
            Result = "Only columns colA and colE are expanded."
          ],
          [
            Description = "Expand nothing (would typically never be used)",
            Code = "FunctionName(Source,null,true)",
            Result = "Nothing is expanded."
          ],
          [
            Description = "Example: Change the separator while all columns are expanded",
            Code = "FunctionName(Source,null,null,"" "")",
            Result = "Expands all columns, but instead of a fullstop, a space is used as a separator."
          ]
        }
    
  ],
fn = (
    previousStep as table,
    optional specifiedCols as nullable list,
    optional excludeCols as nullable logical,
    optional separator as nullable text
) =>
let
    separator = if separator = null then "." else separator,
    iteration = (
        prev as table,
        specifiedCols as nullable list,
        excludeCols as nullable logical,
        i as number
    ) =>
    let
        columnNames = Table.ColumnNames(prev),
        columnCount = List.Count(columnNames),

        StartsWithAny = (text as text, prefixes as list) as logical =>
            List.AnyTrue(List.Transform(prefixes, each Text.StartsWith(text, _))),

        colsToExpand = 
            if specifiedCols = null and (excludeCols = null or excludeCols = false) then columnNames
            else if specifiedCols = null and excludeCols = true then {}
            else if specifiedCols <> null and (excludeCols = null or excludeCols = false) then 
                List.Select(columnNames, each StartsWithAny(_, specifiedCols))
            else if specifiedCols <> null and excludeCols = true then 
                List.Select(columnNames, each not StartsWithAny(_, specifiedCols))
            else columnNames,

        processColumn = if i < columnCount then
            let
                colName = columnNames{i},
                shouldExpand = List.Contains(colsToExpand, colName),
                colIsExpandable = Table.RowCount(
                    Table.SelectRows(prev, each 
                        Value.Is(Record.Field(_, colName), type list) or
                        Value.Is(Record.Field(_, colName), type table) or
                        Value.Is(Record.Field(_, colName), type record)
                    )
                ) > 0
            in
                if not shouldExpand or not colIsExpandable then
                    @iteration(prev, specifiedCols, excludeCols, i + 1)
                else
                    let
                        expandList = Table.ExpandListColumn(
                            Table.ReplaceValue(
                                prev,
                                each Record.Field(_, colName),
                                each if not Value.Is(Record.Field(_, colName), type list) and 
                                         not Value.Is(Record.Field(_, colName), type table) and 
                                         Record.Field(_, colName) <> null
                                     then {Record.Field(_, colName)} 
                                     else Record.Field(_, colName),
                                Replacer.ReplaceValue,
                                {colName}
                            ),
                            colName
                        ),
                        convert = Table.ReplaceValue(
                            expandList,
                            each Record.Field(_, colName),
                            each if not Value.Is(Record.Field(_, colName), type record) and 
                                     Record.Field(_, colName) <> null
                                 then [ _ = Record.Field(_, colName) ]
                                 else Record.Field(_, colName),
                            Replacer.ReplaceValue,
                            {colName}
                        ),
                        oldRecords = Table.RenameColumns(
                            Table.FromList(
                                Record.FieldNames(
                                    Record.Combine(
                                        List.RemoveNulls(Table.Column(convert, colName))
                                    )
                                ),
                                Splitter.SplitByNothing(),
                                null,
                                null,
                                ExtraValues.Error
                            ),
                            {{"Column1", "old.name"}}
                        ),
                        newRecords = Table.AddColumn(
                            oldRecords,
                            "new.name",
                            each if [old.name] = "_" then colName else colName & separator & [old.name]
                        ),
                        expanded = Table.ExpandRecordColumn(
                            convert,
                            colName,
                            newRecords[old.name],
                            newRecords[new.name]
                        )
                    in
                        @iteration(expanded, specifiedCols, excludeCols, i)
        else
            prev
    in
        processColumn,

    result = iteration(previousStep, specifiedCols, excludeCols, 0)
in
    result

 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
