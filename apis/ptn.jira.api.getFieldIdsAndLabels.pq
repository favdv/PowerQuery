/**/

(domains as list,columnNames as list,fieldList as list)=>
let
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
            Splitter.SplitByNothing(), null, null, ExtraValues.Error), "Column1",{"key", "name","navigable"})) 
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
