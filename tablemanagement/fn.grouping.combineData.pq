/* 
When this function is called, the data from the table is grouped by the GroupBy list.
Columns identified by the columnsToCombine list  the grouped table converted into a comma-seperated lines - the number of lines is calculated based on the returnedResults value.
If no columns are specified all columns apart from the columns in groupBy are cobined in a single line.
If no returnedResults value is set, everything is concatenated in a single line.

The combined columns are named as <orginalColumnName>.combined, but it is possible to replace .combined with something else.
During the process, some temporary columns are created and subsequently removed. If this causes an error, the temporary column prefix can be altered too. 
A "combined" index is also added as a column, which can be used to identify a specific grouped list item.

Essentially, this function enables deduplication of a larger dataset (based on the GroupBy list) without losing data or grouping of data, which can for instance be beneficial for api calls with limits.
Note that all nested columns are converted to text columns.
See also the README.md file in the repository for more information on how to implement this. 
*/

(previousStep as table, groupBy as list, optional columnsToCombine as nullable list, optional returnedResults as nullable number, optional replaceSuffix as nullable text, optional tempColumnPrefix as nullable text) =>
let
    columnsToCombine = if columnsToCombine = null then List.RemoveItems(Table.ColumnNames(previousStep),groupBy) else columnsToCombine, 
    replaceSuffix = if replaceSuffix = null then ".combined" else replaceSuffix,
    tempColumnPrefix = if tempColumnPrefix = null then  "__.tmp" else tempColumnPrefix,
    SubGroup = Table.AddColumn(
                        Table.AddColumn(
                            Table.Group(previousStep, groupBy, {{tempColumnPrefix & ".Grp", each _}}), 
                            tempColumnPrefix & ".Grp.sub", 
                            each Table.AddIndexColumn(Record.Field(_,tempColumnPrefix & ".Grp"),  tempColumnPrefix & ".Grp.sub.ix", 0, 1, Int64.Type)
                        ),
                        tempColumnPrefix & ".Grp.sub.sub", 
                        each Table.AddColumn(
                            Record.Field(_, tempColumnPrefix & ".Grp.sub"), 
                           "Index" & replaceSuffix, 
                            each if returnedResults = null or returnedResults = 0 
                                 then 1 
                                 else Number.IntegerDivide(Record.Field(_,tempColumnPrefix & ".Grp.sub.ix"), returnedResults)
                        )
                    ),
     
    SubSubGroup = Table.Group(
                Table.ExpandTableColumn(
                    SubGroup,
                    tempColumnPrefix & ".Grp.sub.sub", 
                   List.RemoveItems( Table.ColumnNames(Table.Combine(Table.Column(SubGroup,tempColumnPrefix & ".Grp.sub.sub"))),groupBy)
                ), 
                List.InsertRange(groupBy, 0, {"Index" & replaceSuffix}), 
                {{ tempColumnPrefix & ".Grp.sub.sub", each _}}
            ),
    
     Combine =   Table.Distinct(Table.ExpandTableColumn(List.Accumulate(
                            columnsToCombine,
                            SubSubGroup,
                            (state, current) =>  
                                if List.Contains(Table.ColumnNames(state), current & replaceSuffix) 
                                then state 
                                else Table.AddColumn(
                                    state,current & replaceSuffix,each Text.Combine(
                                        List.Transform(
                                            Table.Column(Record.Field(_, tempColumnPrefix & ".Grp.sub.sub"), current), 
                                            each Text.From(_)
                                        ),",")
                                    )
                        )
                        ,tempColumnPrefix & ".Grp.sub.sub",List.RemoveItems( 
                            Table.ColumnNames(Table.Combine(Table.Column(SubGroup,tempColumnPrefix & ".Grp.sub.sub"))),
                            List.InsertRange(groupBy,0,List.InsertRange(columnsToCombine,0,{"Index" & replaceSuffix,tempColumnPrefix & ".Grp.sub.ix"}))
                        )))
in
    Combine
