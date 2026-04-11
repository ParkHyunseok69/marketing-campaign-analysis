/*DATA CLEANING*/
ALTER TABLE marketing_campaign_table
ADD Age tinyint;

UPDATE marketing_campaign_table 
SET Age = 2014 - Year_Birth;

UPDATE marketing_campaign_table
SET Income = NULL
WHERE Income = 0;

ALTER TABLE marketing_campaign_table
ADD Generation varchar(50);

UPDATE marketing_campaign_table
SET Marital_Status = CASE WHEN Marital_Status = 'Absurd' OR Marital_Status = 'YOLO' OR Marital_Status = 'Alone' THEN 'Single' ELSE Marital_Status END

UPDATE marketing_campaign_table
SET Generation = CASE 
				WHEN Year_Birth >= 1928 AND Year_Birth <= 1945 THEN 'Silent Generation'
				WHEN Year_Birth >= 1946 AND Year_Birth <= 1964 THEN 'Baby Boomer'
				WHEN Year_Birth >= 1965 AND Year_Birth <= 1980 THEN 'Generation X'
				WHEN Year_Birth >= 1981 AND Year_Birth <= 1996 THEN 'Millenial'
				WHEN Year_Birth >= 1997 AND Year_Birth <= 2012 THEN 'Generation Z'
				ELSE 'Greatest Generation'
			END;

ALTER TABLE marketing_campaign_table
ADD MostCategorySpent varchar(50);

UPDATE marketing_campaign_table
SET MostCategorySpent = CASE
					WHEN MntWines = GREATEST(MntWines, MntMeatProducts, MntFruits, MntFishProducts, MntSweetProducts, MntGoldProds) THEN 'MntWines'
					WHEN MntMeatProducts = GREATEST(MntWines, MntMeatProducts, MntFruits, MntFishProducts, MntSweetProducts, MntGoldProds) THEN 'MntMeatProducts'
					WHEN MntFruits = GREATEST(MntWines, MntMeatProducts, MntFruits, MntFishProducts, MntSweetProducts, MntGoldProds) THEN ' MntFruits'
					WHEN MntFishProducts = GREATEST(MntWines, MntMeatProducts, MntFruits, MntFishProducts, MntSweetProducts, MntGoldProds) THEN 'MntFishProducts'
					WHEN MntSweetProducts = GREATEST(MntWines, MntMeatProducts, MntFruits, MntFishProducts, MntSweetProducts, MntGoldProds) THEN 'MntSweetProducts'
					WHEN MntGoldProds = GREATEST(MntWines, MntMeatProducts, MntFruits, MntFishProducts, MntSweetProducts, MntGoldProds) THEN 'MntGoldProds'
					ELSE NULL
				END;

ALTER TABLE marketing_campaign_table
ADD TotalSpent smallint;

UPDATE marketing_campaign_table
SET TotalSpent = MntWines + MntMeatProducts + MntFruits + MntFishProducts + MntSweetProducts + MntGoldProds;

ALTER TABLE marketing_campaign_table
ADD IncomeCategory varchar(20);

UPDATE marketing_campaign_table
SET IncomeCategory = CASE
	WHEN Income <= 42000 THEN 'Low Income'
	WHEN Income > 42000 AND Income <= 126000 THEN 'Medium Income'
	WHEN Income > 126000 THEN 'High Income'
	ELSE 'No Income Specified'
END; 

ALTER TABLE marketing_campaign_table
ADD SpendingFrequency tinyint;

UPDATE marketing_campaign_table
SET SpendingFrequency = NumWebPurchases + NumStorePurchases + NumCatalogPurchases;


/*Using income, age, and spending behavior, can you identify distinct customer groups? What are the defining
characteristics of each segment?*/
GO
CREATE VIEW [vw_customer_segment_profile] AS
SELECT IncomeCategory, Generation, COUNT(*) AS CustomerCount, AVG(TotalSpent) AS AvgTotalSpent, AVG(Income) AS AvgIncome
FROM marketing_campaign_table
GROUP BY IncomeCategory, Generation;

GO
CREATE VIEW [vw_category_spend_by_segment] AS
SELECT IncomeCategory, Generation, Marital_Status,
	SUM (CASE WHEN MostCategorySpent = 'MntWines'THEN 1 ELSE 0 END) AS MntWinesCount,
	SUM (CASE WHEN MostCategorySpent = 'MntMeatProducts'THEN 1 ELSE 0 END) AS  MntMeatProductsCount,
	SUM (CASE WHEN MostCategorySpent = 'MntFruits' THEN 1 ELSE 0 END) AS MntFruitsCount,
	SUM (CASE WHEN MostCategorySpent = 'MntFishProducts' THEN 1 ELSE 0 END) AS MntFishCount,
	SUM (CASE WHEN MostCategorySpent = 'MntSweetProducts' THEN 1 ELSE 0 END) AS MntSweetCount,
	SUM (CASE WHEN MostCategorySpent = 'MntGoldProds' THEN 1 ELSE 0 END) AS  MntGoldProdsCount
FROM marketing_campaign_table
GROUP BY IncomeCategory, Generation, Marital_Status;


/*Which customer segments responded most positively to past campaigns? Is there a pattern across income level,
marital status, or education?*/
GO
CREATE VIEW [vw_campaign_response_by_income_marital] AS
SELECT IncomeCategory, Marital_Status,
SUM (CAST(AcceptedCmp1 AS INT) + CAST(AcceptedCmp2 AS INT) + CAST(AcceptedCmp3 AS INT) + CAST(AcceptedCmp4 AS INT) + CAST(AcceptedCmp5 AS INT) + CAST(Response AS INT)) AS TotalAcceptance
FROM marketing_campaign_table
GROUP BY IncomeCategory, Marital_Status;

GO
CREATE VIEW [vw_campaign_response_by_income_education] AS
SELECT IncomeCategory, Education,
SUM (CAST(AcceptedCmp1 AS INT) + CAST(AcceptedCmp2 AS INT) + CAST(AcceptedCmp3 AS INT) + CAST(AcceptedCmp4 AS INT) + CAST(AcceptedCmp5 AS INT) + CAST(Response AS INT)) AS TotalAcceptance
FROM marketing_campaign_table
GROUP BY IncomeCategory, Education;

GO CREATE VIEW [vw_campaign_count] AS
SELECT  SUM (CASE WHEN AcceptedCmp1 = 1 THEN 1 ELSE 0 END) AS C1_Count,
						SUM (CASE WHEN AcceptedCmp2 = 1 THEN 1 ELSE 0 END) AS C2_Count,
						SUM (CASE WHEN AcceptedCmp3 = 1 THEN 1 ELSE 0 END) AS C3_Count,
						SUM (CASE WHEN AcceptedCmp4 = 1 THEN 1 ELSE 0 END) AS C4_Count,
						SUM (CASE WHEN AcceptedCmp5 = 1 THEN 1 ELSE 0 END) AS C5_Count,
						COUNT (CASE WHEN Response = 1 THEN 1 ELSE 0 END) AS Response_Count
FROM marketing_campaign_table





/*Which purchase channels (web, catalog, store) generate the most revenue per customer? Does channel preference
vary by segment?*/
GO
CREATE VIEW [vw_channel_revenue] AS
WITH purchase_channels AS(SELECT SUM(TotalSpent) AS TotalSpent, SUM(NumWebPurchases) AS WebP_Count, SUM(NumStorePurchases) AS StoreP_Count, SUM(NumCatalogPurchases) AS CatalogP_Count,
CASE 
	WHEN  NumWebPurchases = GREATEST (NumWebPurchases, NumStorePurchases, NumCatalogPurchases) THEN 'Web'
	WHEN  NumStorePurchases = GREATEST (NumWebPurchases, NumStorePurchases, NumCatalogPurchases) THEN 'Store'
	WHEN  NumCatalogPurchases = GREATEST (NumWebPurchases, NumStorePurchases, NumCatalogPurchases) THEN 'Catalog'
	ELSE NULL
	END AS PreferredChannel
FROM marketing_campaign_table
GROUP BY NumWebPurchases, NumStorePurchases, NumCatalogPurchases)
SELECT PreferredChannel, SUM(TotalSpent) AS TotalSpent
FROM purchase_channels
GROUP BY PreferredChannel

GO
CREATE VIEW [vw_channel_preference_by_income] AS
WITH purchase_channels AS (SELECT IncomeCategory, SUM(TotalSpent) AS TotalSpent, SUM(NumWebPurchases) AS WebP_Count, SUM(NumStorePurchases) AS StoreP_Count, SUM(NumCatalogPurchases) AS CatalogP_Count,
CASE 
	WHEN  NumWebPurchases = GREATEST (NumWebPurchases, NumStorePurchases, NumCatalogPurchases) THEN 'Web'
	WHEN  NumStorePurchases = GREATEST (NumWebPurchases, NumStorePurchases, NumCatalogPurchases) THEN 'Store'
	WHEN  NumCatalogPurchases = GREATEST (NumWebPurchases, NumStorePurchases, NumCatalogPurchases) THEN 'Catalog'
	ELSE NULL
	END AS PreferredChannel
FROM marketing_campaign_table
GROUP BY IncomeCategory, NumWebPurchases, NumStorePurchases, NumCatalogPurchases)
SELECT IncomeCategory, SUM(CASE WHEN PreferredChannel = 'Store' THEN 1 ELSE 0 END) AS PrefStore, 
	SUM(CASE WHEN PreferredChannel = 'Catalog' THEN 1 ELSE 0 END) AS PrefCatalog, 
	SUM(CASE WHEN PreferredChannel = 'Web' THEN 1 ELSE 0 END) AS PrefWeb
FROM purchase_channels
GROUP BY IncomeCategory


/*How recently and how frequently do high-value customers purchase? Can you classify customers into RFM tiers (e.g.
Champions, At-Risk, Lost)?*/
GO
CREATE VIEW [vw_rfm_recency_frequency_highspend] AS
WITH rfm_catogories AS(SELECT IncomeCategory,
CASE
	WHEN TotalSpent >= 1683 THEN 'High TotalSpent'
	WHEN TotalSpent <= 1683 AND TotalSpent >= 841 THEN 'Mid TotalSpent'
	WHEN TotalSpent < 841 THEN 'Low TotalSpent'
	ELSE NULL
	END AS TotalSpent,
CASE 
	WHEN Recency >= 66 THEN 'High Recency'
	WHEN Recency  <= 66 AND Recency >= 33 THEN 'Mid Recency'
	WHEN Recency < 33 THEN 'Low Recency'
	ELSE NULL
	END AS Recency,
CASE 
	WHEN SpendingFrequency >= 21 THEN 'High Frequency'
	WHEN SpendingFrequency <= 21 AND SpendingFrequency >= 10 THEN 'Mid Frequency'
	WHEN SpendingFrequency < 10 THEN 'Low Frequency'
	ELSE NULL
	END AS SpendingFrequency
FROM marketing_campaign_table)
SELECT TotalSpent, IncomeCategory, SUM(CASE WHEN Recency = 'Low Recency' THEN 1 ELSE 0 END) AS LowRecency_Count, SUM(CASE WHEN Recency = 'Mid Recency' THEN 1 ELSE 0 END) AS MidRecency_Count, SUM(CASE WHEN Recency = 'High Recency' THEN 1 ELSE 0 END) AS HighRecency_Count, 
SUM(CASE WHEN SpendingFrequency = 'Low Frequency' THEN 1 ELSE 0 END) AS LowFrequency_Count, SUM(CASE WHEN SpendingFrequency = 'Mid Frequency' THEN 1 ELSE 0 END) AS MidFrequency_Count, SUM(CASE WHEN SpendingFrequency = 'High Frequency' THEN 1 ELSE 0 END) AS HighFrequency_Count 
FROM rfm_catogories
WHERE (TotalSpent = 'High TotalSpent' AND IncomeCategory = 'High Income') OR (TotalSpent = 'High TotalSpent' AND IncomeCategory = 'Medium Income') OR (TotalSpent = 'High TotalSpent' AND IncomeCategory = 'Low Income')
GROUP BY TotalSpent, IncomeCategory

GO
CREATE VIEW [vw_rfm_tiers_total_spent] AS
WITH rfm_catogories AS(SELECT IncomeCategory,
CASE
	WHEN TotalSpent >= 1683 THEN 'High TotalSpent'
	WHEN TotalSpent <= 1683 AND TotalSpent >= 841 THEN 'Mid TotalSpent'
	WHEN TotalSpent < 841 THEN 'Low TotalSpent'
	ELSE NULL
	END AS TotalSpent,
CASE 
	WHEN Recency >= 66 THEN 'High Recency'
	WHEN Recency  <= 66 AND Recency >= 33 THEN 'Mid Recency'
	WHEN Recency < 33 THEN 'Low Recency'
	ELSE NULL
	END AS Recency,
CASE 
	WHEN SpendingFrequency >= 21 THEN 'High Frequency'
	WHEN SpendingFrequency <= 21 AND SpendingFrequency >= 10 THEN 'Mid Frequency'
	WHEN SpendingFrequency < 10 THEN 'Low Frequency'
	ELSE NULL
	END AS SpendingFrequency
FROM marketing_campaign_table),
rfm_count AS (SELECT TotalSpent, Recency, SpendingFrequency, IncomeCategory,
CASE
	WHEN Recency = 'High Recency' AND SpendingFrequency = 'High Frequency' THEN 'Champions'
	WHEN SpendingFrequency = 'High Frequency' THEN 'Loyal Customers'
	WHEN Recency = 'Mid Recency' OR Recency = 'High Recency' AND SpendingFrequency = 'Mid Frequency' THEN 'Promising'
	WHEN Recency = 'Low Recency'THEN 'At-Risk/Lapsed'
	WHEN TotalSpent = 'High TotalSpent' AND Recency = 'Low Recency' THEN 'Cannot Lose'
	WHEN Recency = 'High Recency' AND SpendingFrequency = 'Low Frequency' THEN 'Hibernating'
	WHEN TotalSpent = 'Low TotalSpent' AND SpendingFrequency = 'Low Frequency' THEN 'Low Value'
	ELSE NULL
	END AS RFM_Tiers
FROM rfm_catogories)
SELECT RFM_Tiers, TotalSpent, SUM((CASE WHEN RFM_Tiers = 'Champions' THEN 1 ELSE 0 END) +
						(CASE WHEN RFM_Tiers = 'Loyal Customers' THEN 1 ELSE 0 END) +
						(CASE WHEN RFM_Tiers = 'Promising' THEN 1 ELSE 0 END) +
						(CASE WHEN RFM_Tiers = 'At-Risk/Lapsed' THEN 1 ELSE 0 END) +
						(CASE WHEN RFM_Tiers = 'Cannot Lose' THEN 1 ELSE 0 END) +
						(CASE WHEN RFM_Tiers = 'Hibernating' THEN 1 ELSE 0 END) +
						(CASE WHEN RFM_Tiers = 'Low Value' THEN 1 ELSE 0 END)
) AS RFMTiers_Count
FROM rfm_count
GROUP BY RFM_Tiers, TotalSpent


/*Which product categories (wines, meats, gold, etc.) drive the most spend? Are there cross-sell opportunities visible in
the data?*/
GO 
CREATE VIEW [vw_category_spend_by_income] AS
SELECT IncomeCategory,
	SUM (CASE WHEN MostCategorySpent = 'MntWines'THEN 1 ELSE 0 END) AS MntWinesCount,
	SUM (CASE WHEN MostCategorySpent = 'MntMeatProducts'THEN 1 ELSE 0 END) AS  MntMeatProductsCount,
	SUM (CASE WHEN MostCategorySpent = 'MntFruits' THEN 1 ELSE 0 END) AS MntFruitsCount,
	SUM (CASE WHEN MostCategorySpent = 'MntFishProducts' THEN 1 ELSE 0 END) AS MntFishCount,
	SUM (CASE WHEN MostCategorySpent = 'MntSweetProducts' THEN 1 ELSE 0 END) AS MntSweetCount,
	SUM (CASE WHEN MostCategorySpent = 'MntGoldProds' THEN 1 ELSE 0 END) AS  MntGoldProdsCount
	
FROM marketing_campaign_table
GROUP BY IncomeCategory;


/*Do customers who have complained in the last 2 years show lower campaign response rates? What does this imply
for customer recovery strategy?*/
GO 
CREATE VIEW [vw_complaint_response_rate] AS
SELECT CAST(ROUND((TotalAcceptance * 100.0)/ ComplainCount, 2) AS DECIMAL(5, 2)) AS ResponseRate , Complain, ComplainCount, TotalAcceptance
FROM(SELECT Complain, COUNT(CAST(Complain AS INT)) AS ComplainCount,
SUM (CAST(AcceptedCmp1 AS INT) + CAST(AcceptedCmp2 AS INT) + CAST(AcceptedCmp3 AS INT) + CAST(AcceptedCmp4 AS INT) + CAST(AcceptedCmp5 AS INT) + CAST(Response AS INT)) AS TotalAcceptance
FROM marketing_campaign_table GROUP BY Complain) AS reponse_rate;
