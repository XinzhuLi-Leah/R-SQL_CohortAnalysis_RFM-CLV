-- RFM分析是一种用于客户分群和行为分析的经典方法，基于以下三个指标对客户进行评分：

--  •	R（Recency）: 最近一次购买距离现在的时间间隔。
-- 	•	F（Frequency）: 一定时间内的购买次数。
-- 	•	M（Monetary）: 一定时间内的总购买金额。
-- RFM 分析中的核心目标

	-- 1.	识别关键客户：找到高价值客户（高 RFM 分值的客户）。
	-- 2.	客户分群：对客户进行分群管理，如 VIP 客户、普通客户、新客户等。
	-- 3.	优化资源分配：根据客户重要性分配不同的市场营销资源。


-- 因为数据集是2010年底到2011年年底的数据，那我就设置现在的时间为2012-01-01
WITH RFM AS (
    SELECT 
        CustomerID,
        Country,
        DATEDIFF('2012-01-01', MAX(InvoiceDate)) AS Recency,
        COUNT(DISTINCT InvoiceNo) AS Frequency,
        round(SUM(Quantity * UnitPrice),0) AS Monetary
    FROM OnlineRetail
    where Quantity>0 
    GROUP BY CustomerID,Country
),
RFM_Scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY Recency DESC) AS R_Score,  -- 越小越好
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score, -- 越大越好
        NTILE(5) OVER (ORDER BY Monetary ASC) AS M_Score   -- 越大越好
    FROM RFM
),
total_RFM_Score AS(
  SELECT *,
       R_Score  + F_Score + M_Score AS total_RFM_Score
  FROM RFM_Scored
  order by  total_RFM_Score desc
)
select *,
    CASE 
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Loyal Customers'
        WHEN R_Score >= 4 AND F_Score <= 2 AND M_Score <= 2 THEN 'New Customers'
        WHEN R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4 THEN 'Churn Risk'
        ELSE 'Other'
    END AS Customer_Segment
FROM total_RFM_Score;

-- 创建视图Customer_Segment 方便后面的使用 省略space


-- 除了NTILE 窗口函数能够为顾客分组， 下面两个PERCENT_RANK()，CUME_DIST()也是可以的！

Select  
CustomerID,
total_RFM_Score,
  CASE
        WHEN PERCENT_RANK() OVER (ORDER BY total_RFM_Score DESC) <= 0.2 THEN 'Top Customers'
        WHEN PERCENT_RANK() OVER (ORDER BY total_RFM_Score DESC) <= 0.6 THEN 'Mid-tier Customers'
        ELSE 'Low-value Customers'
    END AS customer_category
from Customer_Segment;


Select  
CustomerID,
total_RFM_Score,
  CASE
        WHEN CUME_DIST() OVER (ORDER BY total_RFM_Score DESC) <= 0.2 THEN 'Top Customers'
        WHEN CUME_DIST() OVER (ORDER BY total_RFM_Score DESC) <= 0.6 THEN 'Mid-tier Customers'
        ELSE 'Low-value Customers'
    END AS customer_category
from Customer_Segment;