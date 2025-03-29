# Source
This data dump was downloaded from https://github.com/gordonkjlee/northwind-csv-sample-data

Note that the accuracy or quality is not guaranteed in any way and the data itself is typically not amended from the downloaded version.

The changes made are: 

* Pictures and picture links are removed throughout and the Homepage column from suppliers were removed as they didn't add any value.
* In some cases, the csv wasn't properly formatted (e.g. the CSV did not split properly), so this was fixed.
* deleting files that were not needed (like bson files and shell scripts), so only the csv files and the readme is retained (see below). The northwind CSV file is also deleted since it essentially a combined file of all other csv files
* csv files moved to a subfolder to split CSVs from other conversions that might be added in the future
* Conversion to xlsx added

Note: The xlsx file contains one tab per csv - each tab contains a table. So it is possible to import the data by sheet or Excel table in PowerBI. Note that due to Excel table naming convention restriction, the tale name might differ slightly from the sheet name.

Note: Overall, the relationships can easily be identified. The only odd one is the ShipperId in the shippers table, which is linked to the ShipVia entity in the orders table. The entity was not renamed to keep the integrity of the original dataset as much as possible. 

Note: relationships might not be auto-detected by PowerBI, which is likely due to headers not being promoted if imported. Promote the first row should mostly resolve this.


See also the comments from the above repository below.

## Colour coding in the xlsx
* Blue: Client & Employee Data, like client info, employee info and employee info
* Green: Product info and categorisation
* Orange: Order Info
* Purple: Logistics, like Shipping & territory organisation
* Grey: link tables
---
# Original Readme

## Northwind@MongoDB ##

### What it is

* Just a simple data dump from SQL's Northwind database to a CSV
* CSV (northwind.csv) turned into multiple CSVs
* CSVs imported into Mongo (mongo-import.sh)


### What it needs

* There aren't any employee/product images
* It's a straight data dump - no relations or special magic


Thanks to [@shayden](https://github.com/shayden) for the csv dump. Buyer beware, caveat emptor, carthago delenda est et al
---