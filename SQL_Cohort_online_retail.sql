SET SQL_SAFE_UPDATES = 0;

-- 日期更改
--  •	第一部分通过 STR_TO_DATE() 函数确保文本数据转化为合适的日期格式。
-- 	•	第二部分通过 ALTER TABLE 修改列的类型，使得数据库能够正确地存储和处理日期
UPDATE OnlineRetail
SET InvoiceDate = STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i')
WHERE STR_TO_DATE(InvoiceDate, '%m/%d/%Y %H:%i') IS NOT NULL;

ALTER TABLE OnlineRetail
MODIFY COLUMN InvoiceDate DATETIME;

-- 根据每个客户的最早发票时间去获取该客户第一次在公司的“上车”时间 并调整成月份，最后根据这个“上车”时间去统计每个“上车”时间有多少独立客户数量

with tmp2 as 
(select cohort, count(distinct CustomerID) as total_counts
from 
(
select *,date_format(min(InvoiceDate) over(partition by CustomerID order by InvoiceDate),'%Y-%m' )as cohort
from OnlineRetail
where CustomerID is not null and  Quantity > 0
) as tmp1
group by cohort
),
tmp3 as 
(                 -- 下面的代码即是计算月份差 month_diff 也就是距离客户第一次“上车时间”之后顾客购买行为过去了几个月？
select *,
       date_format(min(InvoiceDate) over(partition by CustomerID order by InvoiceDate),'%Y-%m' )as cohort,
       timestampdiff(month,  date(min(InvoiceDate) over(partition by CustomerID order by InvoiceDate)),date(InvoiceDate)) as month_diff
from OnlineRetail
where CustomerID is not null and  Quantity > 0
)
select  tmp3.cohort,     -- 然后这里就是在cohort +month_diff的共同作用下，计算出count,比如2月份统一“上车”的客户，在一个月后有多少人，在3个月之后有多少人还存在...以此类推
        tmp3.month_diff,
        tmp2.total_counts,
        count(distinct CustomerID) as active_counts,
        round(count(distinct CustomerID) /tmp2.total_counts,2) as retention_rate
from tmp3
left join tmp2
on tmp3.cohort = tmp2.cohort
group by tmp3.cohort,tmp3.month_diff,tmp2.total_counts



