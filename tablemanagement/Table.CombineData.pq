let 
doc = [
    Documentation.Name =  "Combine Data", 
    Documentation.FunctionName = "Table.CombineData",
    Documentation.Description = 
    "This function batches data in a number of sets identified in the groupCount based on the grouped information. The function was initially designed for two use cases: Deduplication of key data, and batching infomation to manage API requests that might be throttled. Note that the function name is dependent on the name of the query in PowerBI in which the function is pasted, so if the Query is called 'Query1', replace FunctionName with Query1 when calling the function.", 
    Documentation.Examples = {
          [
            Description = "Combining all data on a single line based on the group informaton. (i.e. deduplicate the grouped data)",
            Code = "FunctionName(Source,{""Domain"",""Project""})",
            Result = "The table will be grouped by the Domain and Project columns (same as Table.Group) and the records for all other columns will be combined on a single row in a comma separated list, e.g. all board IDs will be in a single record, keys in a single record, etc."
          ],
          [
            Description = "Combining selected data on a single line based on the group informaton. (e.g. grouping all keys that could be used to call info based on all keys)",
            Code = "FunctionName(Source,{""Domain"",""Project""},{""key""})",
            Result = "The table will be grouped by the Domain and Project columns (same as Table.Group) and the records for the key column will be combined on a single row in a comma separated list. All other columns remain as they are."
          ],
          [
            Description = "Combining selected data in batches of a maximum number of items per line based on the group informaton. . (e.g. grouping all keys that could be used to call info based on all keys, but enabled getting the data based on a number of keys at the time to limit throttling issues)",
            Code = "FunctionName(Source,{""Domain"",""Project""},{""key"",""assigees""},50)",
            Result = "The table will be grouped by the Domain and Project columns (same as Table.Group) and the records for the key column and assignees column will be combined in a comma separated list in batches of 50. All other columns remain as they are."
          ]

        }
    
  ],

fn = (previousStep as table, groupBy as list,optional combineColumns as nullable list, optional groupCount as nullable number) =>
    let
        // Group the table by the specified columns
        AddBatchIndex = Table.AddColumn(Table.Group(previousStep, groupBy, {{"GroupedData", each _}}), "GroupedDataWithBatchIndex", each 
                Table.AddColumn(
                    Table.AddIndexColumn(Record.Field(_,"GroupedData"), "GroupedIndex", 0, 1, Int64.Type), "BatchIndex", each if groupCount = null then 1 else Number.IntegerDivide([GroupedIndex], groupCount)
                )
        ),
        
        // Expand the nested tables to access the BatchIndex column
        ExpandedGroupedDataWithBatchIndexTable =   Table.ExpandTableColumn(AddBatchIndex,"GroupedDataWithBatchIndex", 
                            if combineColumns = null 
                            then 
                                List.RemoveItems(
                                    Record.FieldNames(Record.Combine( Table.ExpandListColumn(AddBatchIndex,"GroupedDataWithBatchIndex")[GroupedDataWithBatchIndex])), 
                                    groupBy
                                )
                            else 
                                List.InsertRange( combineColumns, 0, { "BatchIndex","GroupedIndex"})),
        
        ExpandGroupedDataTable = if combineColumns = null then Table.RemoveColumns(ExpandedGroupedDataWithBatchIndexTable,{"GroupedData"}) 
                            else 
                                Table.ExpandTableColumn(ExpandedGroupedDataWithBatchIndexTable,"GroupedData", List.RemoveItems(
                                    Record.FieldNames(Record.Combine( Table.ExpandListColumn(AddBatchIndex,"GroupedData")[GroupedData])), 
                                    List.InsertRange(groupBy,0,combineColumns)
                                )
                        ),

        MakeDistinct =Table.RemoveColumns( Table.Distinct(ExpandGroupedDataTable,List.InsertRange(groupBy,0,{"GroupedIndex"})),{"GroupedIndex"}),
    
        GroupForBatching = Table.Group(
            MakeDistinct, 
            if combineColumns = null 
            then List.InsertRange({"BatchIndex"}, 0, groupBy) 
            else List.RemoveItems(Table.ColumnNames(MakeDistinct), combineColumns), 
            {
                {"CombinedData", each 
                    Record.FromList(
                            List.Transform(if combineColumns <> null 
                                        then combineColumns 
                                        else List.RemoveItems(Table.ColumnNames(MakeDistinct), List.InsertRange({"BatchIndex"}, 0, groupBy)), (col) => 
                                Text.Combine(List.Transform(Table.Column(_, col), Text.From), ",")
                            ), 
                            List.Transform(if combineColumns <> null 
                                        then combineColumns 
                                        else List.RemoveItems(Table.ColumnNames(MakeDistinct), List.InsertRange({"BatchIndex"}, 0, groupBy)), each _ & ".combined")
                        )
                    
                , type record}
            }
        ),
        Expand = Table.ExpandRecordColumn(GroupForBatching, "CombinedData", Record.FieldNames(Record.Combine(Table.Column(GroupForBatching,"CombinedData"))))
        in
        Expand
 in 
Value.ReplaceType(fn, Value.ReplaceMetadata(Value.Type(fn), doc))
