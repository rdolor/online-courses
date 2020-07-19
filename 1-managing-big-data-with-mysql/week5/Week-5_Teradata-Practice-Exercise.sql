/*Exercise 1. How many distinct dates are there in the saledate column of the transaction
table for each month/year combination in the database?*/
SELECT 
  EXTRACT(MONTH FROM SALEDATE) AS _MONTH
  , EXTRACT(YEAR FROM SALEDATE) AS _YEAR
  , COUNT(DISTINCT SALEDATE) AS NUM_DATE
FROM TRNSACT
GROUP BY  _MONTH, _YEAR
ORDER BY  _YEAR DESC, _MONTH DESC 


/*Exercise 2. Use a CASE statement within an aggregate function to determine which sku
had the greatest total sales during the combined summer months of June, July, and August.*/
SELECT TOP 10 
  SKU
  ,SUM( CASE WHEN EXTRACT(MONTH from saledate)=6
  THEN AMT
  END) AS JUNE
  ,SUM( CASE WHEN EXTRACT(MONTH from saledate)=7
  THEN AMT
  END) AS JULY
  ,SUM( CASE WHEN EXTRACT(MONTH from saledate)=8
  THEN AMT
  END) AS AUGUST
  ,JUNE+JULY+AUGUST AS TOTAL
FROM TRNSACT
WHERE STYPE = 'P'
GROUP BY SKU
ORDER BY TOTAL DESC


/*Exercise 3. How many distinct dates are there in the saledate column of the transaction
table for each month/year/store combination in the database? Sort your results by the
number of days per combination in ascending order.*/
SELECT  
  EXTRACT(MONTH FROM SALEDATE) AS _MONTH
  ,EXTRACT(YEAR FROM SALEDATE) AS _YEAR
  ,STORE
  ,COUNT(DISTINCT SALEDATE) AS NUM_DATE
FROM TRNSACT
GROUP BY  _MONTH
         ,_YEAR
         ,STORE
ORDER BY NUM_DATE ASC 


/*Exercise 4. What is the average daily revenue for each store/month/year combination in
the database? Calculate this by dividing the total revenue for a group by the number of
sales days available in the transaction table for that group.*/
SELECT 
  SKU
  ,SUM(CASE WHEN EXTRACT(MONTH FROM SALEDATE) = 11 THEN AMT END) AS _NOV
  ,SUM(CASE WHEN EXTRACT(MONTH FROM SALEDATE) = 12 THEN AMT END) AS _DEC
  ,(CASE WHEN (EXTRACT(MONTH FROM SALEDATE) = 8 AND EXTRACT(YEAR FROM SALEDATE) = 2005) THEN 'NO' ELSE 'YES' END) AS IS_INCLUDED
  ,DEC-_NOV AS INCREASE_REV_NOV_DEC
FROM TRNSACT
WHERE STYPE = 'P' AND IS_INCLUDED='YES'
GROUP  BY SKU,IS_INCLUDED
ORDER BY INCREASE_REV_NOV_DEC DESC


/*Exercise 5. What is the average daily revenue brought in by Dillard’s stores in areas of
high, medium, or low levels of high school education?*/
SELECT  
  (CASE 
    WHEN S.MSA_HIGH >= 50 AND S.MSA_HIGH < 60 THEN 'LOW'
    WHEN S.MSA_HIGH >= 60 AND S.MSA_HIGH < 70 THEN 'MEDIUM'
    WHEN S.MSA_HIGH >= 70 THEN 'HIGH'
    END) AS EDUCATION_LEVELS
  ,SUM(SUB.TOTAL_REVENUE)/SUM(SUB.NUM_DATES) AS AVG_DAILY_REVENUE
FROM STORE_MSA S_
JOIN 
  (
    SELECT  STORE 
          ,EXTRACT (YEAR FROM SALEDATE) AS YEAR_NUM
          ,EXTRACT (MONTH FROM SALEDATE) AS MONTH_NUM
          , SUM(AMT) AS TOTAL_REVENUE
          , COUNT (DISTINCT (SALEDATE)) AS NUM_DATES
          ,(CASE WHEN (YEAR_NUM=2005 AND MONTH_NUM=8) THEN 'NO' ELSE 'YES' END) AS IS_INCLUDED
    FROM TRNSACT
    WHERE STYPE='P' AND IS_INCLUDED='YES'
    GROUP BY YEAR_NUM, MONTH_NUM, STORE
    HAVING NUM_DATES >= 20
  ) AS SUB
  ON S.STORE = SUB.STORE
GROUP BY EDUCATION_LEVELS;


/*Exercise 6. Compare the average daily revenues of the stores with the highest median
msa_income and the lowest median msa_income. In what city and state were these stores,
and which store had a higher average daily revenue?*/
SELECT  S.CITY
       ,S.STATE
       ,S.MSA_INCOME
       ,SUM(SUB.TOTAL_REVENUE)/SUM(SUB.NUM_DATES) AS AVG_DAILY_REVENUE
FROM STORE_MSA S
JOIN 
  (
    SELECT  STORE
          ,EXTRACT (YEAR FROM SALEDATE) AS YEAR_NUM
          ,EXTRACT (MONTH FROM SALEDATE) AS MONTH_NUM
          , SUM(AMT) AS TOTAL_REVENUE
          , COUNT(DISTINCT SALEDATE) AS NUM_DATES
          , (CASE WHEN (YEAR_NUM=2005 AND MONTH_NUM=8) THEN 'NO' ELSE 'YES' END) AS IS_INCLUDED
    FROM TRNSACT
    WHERE STYPE='P' 
    AND IS_INCLUDED='YES'
    GROUP BY YEAR_NUM, MONTH_NUM, STORE
    HAVING NUM_DATES >= 20 
  ) AS SUB
  ON S.STORE = SUB.STORE
WHERE S.MSA_INCOME IN 
  (
  (SELECT  MAX(MSA_INCOME) FROM STORE_MSA),(SELECT  MIN(MSA_INCOME)FROM STORE_MSA)
  )
GROUP BY S.CITY, S.STATE,S.MSA_INCOME;


/*
Exercise 7: What is the brand of the sku with the greatest standard deviation in sprice?
Only examine skus that have been part of over 100 transactions.
*/
SELECT  DISTINCT (t.SKU)                                                   AS item 
       ,s.brand                                                            AS brand 
       ,STDDEV_SAMP(t.sprice)                                              AS dev_price 
       ,COUNT(DISTINCT(t.SEQ || t.STORE || t.REGISTER || t.TRANNUM || t.SALEDATE)) AS distinct_transactions
FROM TRNSACT t
  JOIN SKUINFO s
    ON t.sku=s.sku
WHERE t.stype='p' 
GROUP BY  item 
         ,brand
HAVING distinct_transactions>100
ORDER BY dev_price DESC


/*
Exercise 8: Examine all the transactions for the sku with the greatest standard deviation in
sprice, but only consider skus that are part of more than 100 transactions.
*/
SELECT  DISTINCT(S.SKU)               AS ITEMS 
       ,S.BRAND 
       ,AVG(T.SPRICE)                 AS AVG_PRICE 
       ,STDDEV_SAMP(T.SPRICE)         AS VARIATION_PRICE 
       ,AVG(T.ORGPRICE)-AVG(T.SPRICE) AS SALE_PRICE_DIFF 
       ,COUNT(DISTINCT(T.TRANNUM))    AS DISTINCT_TRANSACTIONS
FROM SKUINFO S
  JOIN TRNSACT T
    ON S.SKU=T.SKU
WHERE STYPE='P' 
GROUP BY  ITEMS
         ,S.BRAND
HAVING DISTINCT_TRANSACTIONS > 100
ORDER BY VARIATION_PRICE DESC;


/*Exercise 9: What was the average daily revenue Dillard’s brought in during each month of
the year?*/
SELECT  
      (CASE 
        WHEN SUB.MONTH_NUM=1 THEN 'JAN' 
        WHEN SUB.MONTH_NUM=2 THEN 'FEB'
        WHEN SUB.MONTH_NUM=3 THEN 'MAR'
        WHEN SUB.MONTH_NUM=4 THEN 'APR'
        WHEN SUB.MONTH_NUM=5 THEN 'MAY'
        WHEN SUB.MONTH_NUM=6 THEN 'JUN'
        WHEN SUB.MONTH_NUM=7 THEN 'JUL'
        WHEN SUB.MONTH_NUM=8 THEN 'AUG'
        WHEN SUB.MONTH_NUM=9 THEN 'SEP'
        WHEN SUB.MONTH_NUM=10 THEN 'OCT'
        WHEN SUB.MONTH_NUM=11 THEN 'NOV'
        WHEN SUB.MONTH_NUM=12 THEN 'DEC'
        END) AS MONTH_NAME 
       ,SUM(NUM_DATES)                    AS NUM_DAYS_IN_MONTH 
       ,SUM(TOTAL_REVENUE)/SUM(NUM_DATES) AS AVG_MONTHLY_REVENUE
FROM 
  (
  SELECT  
      EXTRACT (MONTH FROM SALEDATE) AS MONTH_NUM 
      ,EXTRACT (YEAR FROM SALEDATE) AS YEAR_NUM
      ,COUNT (DISTINCT SALEDATE) AS NUM_DATES
      ,SUM(AMT) AS TOTAL_REVENUE
      ,(CASE WHEN (YEAR_NUM=2005 AND MONTH_NUM=8) THEN 'NO' ELSE 'YES' END) AS IS_INCLUDED 
    FROM TRNSACT 
    WHERE STYPE='P' AND IS_INCLUDED='YES'
    GROUP BY MONTH_NUM, YEAR_NUM
    HAVING NUM_DATES>=20 
  ) AS SUB
GROUP BY MONTH_NAME
ORDER BY AVG_MONTHLY_REVENUE DESC;

/*
Exercise 11: What is the city and state of the store that had the greatest decrease in
average daily revenue from August to September?
*/

SELECT  SUB.STORE
       ,STR.CITY
       ,STR.STATE
       ,SUM(CASE WHEN SUB.MONTH_NUM=8 THEN SUB.AMT END)                 AS AUG_REVENUE
       ,SUM(CASE WHEN SUB.MONTH_NUM=9 THEN SUB.AMT END)                 AS SEP_REVENUE
       ,COUNT(DISTINCT CASE WHEN SUB.MONTH_NUM=8 THEN SUB.SALEDATE END) AS AUG_DAYS
       ,COUNT(DISTINCT CASE WHEN SUB.MONTH_NUM=9 THEN SUB.SALEDATE END) AS SEP_DAYS
       ,AUG_REVENUE/AUG_DAYS                                            AS AUG_DAILY_REV
       ,SEP_REVENUE/SEP_DAYS                                            AS SEP_DAILY_REV
       ,(SEP_DAILY_REV-AUG_DAILY_REV)                                   AS REV_DIFFERENCE
FROM 
(
	SELECT  STORE
	       ,AMT
	       ,SALEDATE
	       ,EXTRACT (MONTH
	FROM SALEDATE) AS MONTH_NUM, EXTRACT (YEAR
	FROM SALEDATE) AS YEAR_NUM, (CASE WHEN (YEAR_NUM=2005 AND MONTH_NUM=8) THEN 'NO' ELSE 'YES' END) AS IS_INCLUDED
	FROM TRNSACT
	WHERE STYPE='P' 
	AND IS_INCLUDED='YES'  
) AS SUB
INNER JOIN STRINFO STR -- EXTRACT STORE'S CITY STATE
ON STR.STORE = SUB.STORE
GROUP BY  SUB.STORE
         ,STR.CITY
         ,STR.STATE
HAVING AUG_DAYS>=20 AND SEP_DAYS>=20 -- ONLY KEEP STORES > 20 DATES PER MONTH
ORDER BY REV_DIFFERENCE ASC


/*Exercise 12: Determine the month of maximum total revenue for each store. Count the
number of stores whose month of maximum total revenue was in each of the twelve
months. Then determine the month of maximum average daily revenue. Count the
number of stores whose month of maximum average daily revenue was in each of the
twelve months. How do they compare?*/
SELECT  CLEAN.MONTH_NAME                                                            AS MONTH_N
       ,COUNT(CASE WHEN CLEAN.ROW_SUM_REV =1 THEN CLEAN.STORE END)                  AS TOTAL_MONTHLY_REV_COUNT
       ,COUNT(CASE WHEN CLEAN.ROW_AVG_REV =1 THEN CLEAN.STORE END) AS AVERAGE_DAILY_REV_COUNT 
  (
    SELECT  
      (CASE 
        WHEN SUB.MONTH_NUM=1 THEN 'JAN'
        WHEN SUB.MONTH_NUM=2 THEN 'FEB'
        WHEN SUB.MONTH_NUM=3 THEN 'MAR'
        WHEN SUB.MONTH_NUM=4 THEN 'APR'
        WHEN SUB.MONTH_NUM=5 THEN 'MAY'
        WHEN SUB.MONTH_NUM=6 THEN 'JUN'
        WHEN SUB.MONTH_NUM=7 THEN 'JUL'
        WHEN SUB.MONTH_NUM=8 THEN 'AUG'
        WHEN SUB.MONTH_NUM=9 THEN 'SEP'
        WHEN SUB.MONTH_NUM=10 THEN 'OCT'
        WHEN SUB.MONTH_NUM=11 THEN 'NOV'
        WHEN SUB.MONTH_NUM=12 THEN 'DEC'
        END) AS MONTH_NAME
        ,SUB.STORE
        ,SUM(SUB.TOTAL_REVENUE) AS SUM_MONTHLY_REVENUE
        ,SUM(SUB.TOTAL_REVENUE)/SUM(SUB.NUM_DATES) AS AVG_DAILY_REVENUE
        ,ROW_NUMBER() OVER (PARTITION BY SUB.STORE ORDER BY AVG_DAILY_REVENUE DESC ) AS ROW_SUM_REV
        ,ROW_NUMBER() OVER (PARTITION BY SUB.STORE ORDER BY SUM_MONTHLY_REVENUE DESC ) AS ROW_AVG_REV
      FROM 
          (
            SELECT  STORE
              ,EXTRACT (MONTH FROM SALEDATE) AS MONTH_NUM
              ,EXTRACT (YEAR FROM SALEDATE) AS YEAR_NUM
              ,COUNT (DISTINCT SALEDATE) AS NUM_DATES
              ,SUM(AMT) AS TOTAL_REVENUE
              ,(CASE WHEN (YEAR_NUM=2005 AND MONTH_NUM=8) THEN 'NO' ELSE 'YES' END) AS IS_INCLUDED
              FROM TRNSACT
              WHERE STYPE='P' AND IS_INCLUDED='YES'
              GROUP BY MONTH_NUM,YEAR_NUM,STORE
              HAVING NUM_DATES>=20
          ) AS SUB
          GROUP BY MONTH_NAME,SUB.STORE
  ) AS CLEAN
GROUP BY MONTH_N
ORDER BY TOTAL_MONTHLY_REV_COUNT DESC