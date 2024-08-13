/* 
When this function is called, the data from the table is grouped by the GroupBy list.
Only data in the specified column will be converted into a single comma-seperated line.
It is however possible to batch the comma separated lines into batches. 
So if e.g. the NumberToBeBatched is set to 50, the columnToCombine is split in groups of 50 for each groupBy list.  
.
Essentially, this function could be helpful when an API call is to be made where the api is throttled, but you want to batch the api input.

For instance, when using JIRA, you can make an API call using jql. You can make the cal for each key (key=xxx) or multiple keys (key in (..., ..., ...).

The same number of columns is retained.

Note that all nested columns are converted to text columns.
See also the README.md file in the repository for more information on how to implement this. 
*/

(previousStep as table,groupBy as list, columnToCombine as text,optional NumberToBeBatched as nullable number)=>
let Combine = Table.ExpandTableColumn(
    Table.AddColumn(
        Table.Group(
            Table.ExpandTableColumn(
                Table.AddColumn(
            Table.AddColumn(
                Table.Group(previousStep, groupBy, {{columnToCombine & ".tmpGrp", each _}}), 
                columnToCombine & ".tmpGrp.sub", 
                each Table.AddIndexColumn(Record.Field(_,columnToCombine & ".tmpGrp"), columnToCombine & ".tmpGrp.sub.ix", 0, 1, Int64.Type)
            ),
            columnToCombine & ".tmpGrp.sub.sub", 
            each Table.AddColumn(
                    Record.Field(_,columnToCombine & ".tmpGrp.sub"), 
                    columnToCombine & ".combined.ix", 
                    each 
                        if NumberToBeBatched = null or NumberToBeBatched = 0 
                        then 1 
                        else Number.IntegerDivide(Record.Field(_,columnToCombine &  ".tmpGrp.sub.ix"), NumberToBeBatched)
            )
        )
                , columnToCombine &  ".tmpGrp.sub.sub", 
                { columnToCombine, columnToCombine &  ".combined.ix"}
            ), 
            List.InsertRange(groupBy,0,{ columnToCombine & ".combined.ix"}), {{ columnToCombine & ".tmpGrp.sub.sub", each _}}
        ), 
        columnToCombine & ".combined", 
        each Text.Combine(Table.Column(Record.Field(_,columnToCombine & ".tmpGrp.sub.sub"),columnToCombine), ",")
    ), columnToCombine & ".tmpGrp.sub.sub", {columnToCombine &".tmpGrp"})
in Table.Distinct(
    Table.ExpandTableColumn(
      Combine, 
      columnToCombine &".tmpGrp",
      List.RemoveItems( Table.ColumnNames(Table.Combine(Table.Column(Combine,columnToCombine &".tmpGrp"))),
      List.InsertRange( groupBy,0,{columnToCombine}))),List.InsertRange( groupBy,0,{columnToCombine&".combined"})
    )
