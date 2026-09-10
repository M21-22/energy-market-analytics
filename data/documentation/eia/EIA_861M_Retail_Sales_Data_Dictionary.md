EIA-861M Retail Electricity Sales — Project Data Dictionary



Official source:

https://www.eia.gov/electricity/data/state/

https://www.eia.gov/opendata/documentation.php



Dataset



Monthly Sales to Ultimate Customers by State and Sector.



Business grain



One record represents:



State / Census Region × Month × Customer Sector



For the warehouse, we will keep U.S. states and the sectors required for analysis.



Core fields



Field



Meaning



Expected type



Unit / format



Warehouse use



period



Reporting month



DATE / YYYY-MM



Month



Join to DimDate



stateid



State or census-region code



STRING



EIA state code



Join to DimState



stateDescription



State / region name



STRING



Text



Source validation / dimension loading



sectorid



Customer-sector code



STRING



EIA sector code



Join to DimSector



sectorName



Customer-sector name



STRING



Text



Source validation / dimension loading



sales



Electricity sold to ultimate customers



DECIMAL



EIA API metadata: million kilowatthours (equivalent numerically to thousand MWh)



Main demand measure



revenue



Revenue from sales to ultimate customers



DECIMAL



Million USD



Revenue measure



price



Average retail electricity price



DECIMAL



Cents per kWh



Price measure



customers



Number of ultimate customers



BIGINT



Customers



Customer-count measure



Main customer sectors



Expected sector categories include:



Residential



Commercial



Industrial



Transportation



Total



The exact source labels/codes should be preserved in the raw layer and normalized in the dimension layer.



Important transformation rules



Preserve the source file unchanged in ADLS raw storage.



Convert period to a proper month date, preferably the first day of the month.



Use state code as the natural business key for DimState.



Use sector code as the natural business key for DimSector.



Do not aggregate sector rows before loading the detailed fact table.



Do not sum price; calculate weighted or source-provided averages as appropriate.



Do not mix Total rows with component sectors when calculating totals, or values will be double-counted.



Keep source units explicitly documented in the curated layer.



Treat missing / suppressed values as null unless the source clearly defines another sentinel value.



Proposed warehouse mapping



FactRetailElectricity



date\_key



state\_key



sector\_key



sales



revenue\_million\_usd



avg\_price\_cents\_per\_kwh



customer\_count



source\_file



load\_timestamp



Shared dimensions



DimDate



DimState



DimSector



Data-quality checks



period, state and sector should identify the intended business grain.



sales, revenue, price, and customers should never be negative unless source documentation explicitly allows it.



Check duplicate State × Month × Sector rows after normalization.



Check that Total-sector rows are not included together with detailed sectors in downstream summed KPIs.



Validate that state codes map to a known state/region.



Track the maximum source month loaded for incremental ingestion.



Notes



This file is a project-specific data dictionary, not an official EIA document. Definitions are based on EIA's published dataset metadata and state-level electricity documentation.

