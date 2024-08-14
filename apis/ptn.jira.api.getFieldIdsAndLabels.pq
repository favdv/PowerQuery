/* 
This function is a jira specific pattern, which retrieves the field ids and associated jira labels for specific domains. 

columnNames and fieldlists are optional.

You can create a combination of columns, and some wildcards in linewith the api are supported. 

For instance, you can use:
{"*all"} to get all fields
{"*navigable"} to get all navigable fields
{"*all","-description"} to retrieve all fields apart from description, and so on. 
{"*navigable","someotherfield"} to retrieve all navigable fields plus the extra field
and so on.

*orderable and *searchable are not supported in the user defined fields, but it could be extended accordingly.
They are shown in the columns by dfault too

The navigable column is automativally included (via a logical column) as is the all column (which is all keys), 
so by default you get five columns (all keys, the labels, and navigable searchable and orderable (logical values indicating if the field is also navigable,searchable and orderable (respectively).

Ensure you modify your domain(s) to suit your specific requirements. 
The source table needs to have a column with the jira domain.

Assuming the name of the function will be GetJiraFields, the Domain column is in Table1 Table1[Domain] and 
you want for instance show an "all" column and a "selected" column with the parent and description fields, you could write the function as follows:  

newStep = GetJiraFields(Table1[Domain], {"all","selected"},{{"*all"},{"parent,"description"}})

This will add the 2 columns ("all" and "selected") to the table with a logical indicator of the specified fields (true/false).

See also the README.md file in the repository for more information on how to implement this. 
*/

(domains as list, optional columnNames as nullable list, optional fieldList as nullable list) =>
let
    // Default values if columnNames or fieldList are null
    columnNames = if columnNames = null then {} else columnNames,
    fieldList = if fieldList = null then {} else fieldList,

    #"Get all labels" = let 
        domainList = domains,
        apiCall = Table.Distinct(Table.ExpandRecordColumn(Table.FromList(
            List.Generate(()=>[i=0],each [i]<List.Count(domainList), each [i=[i]+1], each  
                if domainList{[i]} = "<your domain>" 
                then 
                    Json.Document(
                        Web.Contents(
                            "<your domain>",
                            [RelativePath = "/rest/api/3/field"]))
                else 
                    Json.Document(
                        Web.Contents(
                            "https://iagtech.atlassian.net",
                            [RelativePath = "/rest/api/3/field"]))){0},
            Splitter.SplitByNothing(), null, null, ExtraValues.Error), "Column1",{"key", "name","navigable","searchable","orderable"})) 
    in apiCall,

    createTable = List.Accumulate(List.Zip({fieldList, columnNames}), #"Get all labels", (state, currentPair) => let
        currentFieldList = currentPair{0},
        currentColumnName = currentPair{1},

        #"get inclusions and exclusions" = 
            Table.RemoveColumns(
                Table.AddColumn(
                    Table.AddColumn(
                        Table.FromList(
                            List.Distinct(currentFieldList), 
                            Splitter.SplitByNothing(), null, null, ExtraValues.Error)
                        , "include", 
                        each if Text.StartsWith([Column1],"-") then false else true), "fieldnames", each 
                        if Text.StartsWith([Column1],"-") 
                        then Text.RemoveRange([Column1],0) 
                        else [Column1]),
                {"Column1"}),

        #"inclusions only" = Table.SelectRows(#"get inclusions and exclusions", each ([include] = true))[fieldnames],
        #"exclusions only" = Table.SelectRows(#"get inclusions and exclusions", each ([include] = false))[fieldnames],
        #"full table" = state[key],
        #"Navigation Only table" = Table.SelectRows(state, each ([navigable] = true))[key],
        #"Exclude Navigation table" = Table.SelectRows(state, each ([navigable] = false))[key],

        #"create list" = 
            if  (List.Contains(currentFieldList,"*all") = true and List.Count(currentFieldList) = 1) or List.Count(currentFieldList) = 0 then #"full table" else /*all fields*/
            if  List.Contains(currentFieldList,"*navigable") = true and List.Count(currentFieldList) = 1 then #"Navigation Only table" else /*nav only fields*/
            if  (List.Contains(currentFieldList,"-*navigable") = true and List.Count(currentFieldList) = 1) or 
                (List.ContainsAll(currentFieldList,{"*all", "-*navigable"}) = true and List.Count(currentFieldList) = 2) then #"Exclude Navigation table" else /*non-nav fields*/
            if  List.ContainsAny(currentFieldList,{"*all","*navigable","-*navigable"}) = false and List.Count(currentFieldList) > 0 then 
                if List.Count(#"exclusions only") > 0 
                then List.RemoveItems(#"inclusions only",#"exclusions only") 
                else #"inclusions only" else /*field list only*/    
            if  List.Contains(currentFieldList,"*navigable") = true and 
                List.ContainsAny(currentFieldList,{"-*navigable","*all"}) = false
                and List.Count(currentFieldList) > 1 then 
                if List.Count(#"exclusions only") > 0 
                then List.RemoveItems( List.Combine({#"Navigation Only table",#"inclusions only"}), #"exclusions only")
                else List.Combine({#"Navigation Only table",#"inclusions only"}) else /*navigable with inclusions and exclusions*/ 
            if  List.Contains(currentFieldList,"*all") = true and 
                List.ContainsAny(currentFieldList,{"-*navigable","*navigable"}) = false
                and List.Count(currentFieldList) > 1 then 
                if List.Count(#"exclusions only") > 0 
                then List.RemoveItems( #"full table",#"exclusions only") else #"full table" else /*all with exclusions - inclusions will have no impact*/  
            if  List.ContainsAll(currentFieldList,{"*all","-*navigable"}) = true and 
                List.ContainsAny(currentFieldList,{"*navigable"}) = false
                and List.Count(currentFieldList) > 1 then 
                if List.Count(#"exclusions only") > 0 
                then List.RemoveItems( List.Combine(#"Exclude Navigation table",#"inclusions only"), #"exclusions only")
                else  List.Combine(#"Exclude Navigation table",#"inclusions only") /*excl nav withinclusions and  exclusions*/  
            else currentFieldList,

        #"merge table" = Table.Join(
            state, 
            "key",Table.AddColumn(Table.RenameColumns(Table.FromList(#"create list", Splitter.SplitByNothing(), null, null, ExtraValues.Error), {"Column1", "key."& currentColumnName}), currentColumnName, each true), 
            "key."& currentColumnName, JoinKind.LeftOuter) 
    in #"merge table"),

    cleanup = Table.ReplaceValue(Table.RemoveColumns(createTable, List.Select(Table.ColumnNames(createTable), each Text.StartsWith(_, "key."))), null, false, Replacer.ReplaceValue, Table.ColumnNames(Table.RemoveColumns(createTable, List.Select(Table.ColumnNames(createTable), each Text.StartsWith(_, "key.")))))
in
    cleanup
