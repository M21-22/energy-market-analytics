EIA State Monthly Electricity Generation — Project Data Dictionary



Official source:

https://www.eia.gov/electricity/data/state/

https://www.eia.gov/electricity/data.php



Dataset



Net Generation by State by Type of Producer by Energy Source.



The monthly state dataset is derived from EIA electric-power reporting, including EIA-923 and predecessor surveys.



Business grain



A source record represents approximately:



State × Month × Producer Type × Energy Source



The exact column names in the workbook should be preserved in the raw layer. Curated names should be standardized after inspection.



Core fields



Logical field



Meaning



Expected type



Unit / format



Warehouse use



period / year + month



Reporting month



DATE



Month



Join to DimDate



state



State code or name



STRING



State



Join to DimState



producer\_type



Type of electricity producer / sector



STRING



Category



Optional analytical dimension



energy\_source



Primary energy source used for generation



STRING



Category



Join to DimEnergySource



generation



Net electricity generation



DECIMAL



Typically MWh in the state-level workbook; verify workbook header before transformation



Main supply measure



Typical energy-source categories



The source may contain categories such as:



Coal



Natural Gas



Petroleum



Nuclear



Hydroelectric



Wind



Solar



Biomass



Geothermal



Other



Total



Preserve the source values in raw storage. Map them to normalized categories only in curated / warehouse layers.



Typical producer-type categories



Depending on the workbook, categories may include variants of:



Total Electric Power Industry



Electric Utilities



Independent Power Producers



Commercial Combined Heat and Power



Industrial Combined Heat and Power



Do not assume the exact labels until the downloaded workbook is inspected.



Important transformation rules



Preserve the XLS/XLSX source file unchanged in ADLS raw storage.



Convert Year + Month columns to a single monthly date where needed.



Normalize state code/name into DimState.



Normalize energy-source values into DimEnergySource.



Keep producer type if it is present and useful; otherwise filter deliberately to the required total-industry level.



Do not add Total generation rows to detailed energy-source rows, or generation will be double-counted.



Do not add total-producer rows to individual producer types.



Preserve negative generation values if present. Net generation can occasionally be negative for some technologies/facilities because station use or pumping can exceed gross output.



Treat missing / suppressed values as null unless EIA defines a specific sentinel.



Verify the exact generation unit from the workbook header before creating curated-column names.



Proposed warehouse mapping



FactElectricityGeneration



date\_key



state\_key



energy\_source\_key



producer\_type\_key (optional)



generation\_mwh



source\_file



load\_timestamp



Shared dimensions



DimDate



DimState



DimEnergySource



DimProducerType (optional)



Data-quality checks



Check duplicates at State × Month × Producer Type × Energy Source.



Validate state codes/names against DimState.



Validate energy-source categories against the normalized mapping table.



Prevent double-counting caused by Total rows.



Track minimum/maximum month available.



Compare aggregated state totals against source Total rows as a reconciliation check.



Flag unexpected new energy-source or producer-type values for review.



Relationship to Retail Electricity dataset



The generation dataset and the retail-sales dataset should not be joined row-for-row.



Generation grain:

State × Month × Producer Type × Energy Source



Retail grain:

State × Month × Customer Sector



For cross-domain analysis, aggregate each dataset separately to a common grain such as:



State × Month



Then compare metrics such as total generation, total retail sales, price, and weather indicators.



Notes



This file is a project-specific data dictionary, not an official EIA document. Definitions are based on EIA's published state-level generation descriptions and electric-power metadata.

