# The repository
This repository is used to store Power Query functions that other Power BI developers might also find of interest.

The repository is set up in a way to easily target specific functions or patterns by seprating them into categories, like apis, data management (expanding/removing columns), etc.  

Functions can be used without any user amendments and they should work immediately if used properly. To make them recognisable, their extension is *.pq* (Power Queries)

_**Note:** While it might not be obvious that this is needed in PowerBI desktop, the functions are written in a way so it will also ensure auto-refresh works once published._

# Using functions

## Retrieving all functions
To retrieve the functions in PowerBi, you can simply copy the content from [Record.GetAllQueries.pt](https://github.com/favdv/ready-to-use-powerqueries/blob/main/Record.GetAllQueries.pt) into blank query.

_**Note:** As the list of queries grows, Record.GetAllQueries.pt might need to be amended to cater for additional records in the function list. So you might require to update the function on occasion. The utilities repo has functions and a more exhaustive list to support managing amendments for this purpose._ 



This will create a record, like:

<img width="100%" alt="image" src="https://github.com/user-attachments/assets/b7b53b8a-469c-4f16-b1e7-0ebb3b079155" />

To use a function, you can use the following:
```
<recordQuery>[<functionToCall>](<parameters>)
```

# Copying a single function
For example, if the query above was copied in a Blank Query with name Functions, I want to expand all columns of the table identified in the Source step, I can use:

```
let Source = ...,
Expand = Functions[Table.ExpandAllColumns](Source)
in Expand
```

Alternatively, you can copy any of the queries from the repo in a blank query and call it via 
```
<queryName>(<parameters>)
```

For example, if you copy the query to expand all columns in a query called ExpandAll to expand the source, you can call it via the following method:

```
let Source = ...,
Expand = ExpandAll(Source)
in Expand
```


